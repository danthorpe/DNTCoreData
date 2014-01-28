//
//  DNTIncrementalStore.m
//  YOM
//
//  Created by Daniel Thorpe on 31/12/2013.
//  Copyright (c) 2013 Blinding Skies. All rights reserved.
//

#import "DNTIncrementalStore.h"
#import "DNTCoreDataStack.h"
#import "NSManagedObjectContext+DNTAdditions.h"

typedef NS_ENUM(NSUInteger, DNTIncrementalStoreManagedObjectContextTarget) {
    DNTIncrementalStoreManagedObjectContextPrimary,
    DNTIncrementalStoreManagedObjectContextBacking
};

static NSString * const DNTReferenceObjectPrefix = @"__dnt_";

@interface DNTIncrementalStore ( /* Private */ )

@property (nonatomic, strong, readwrite) DNTCoreDataStack *backingStack;
@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) NSCache *backingObjectIDByObjectID;
@property (nonatomic, strong) NSMutableDictionary *registeredObjectIDsByEntityNameAndResourceIdentifier;

@end

@implementation DNTIncrementalStore

+ (NSString *)storeType {
    return NSStringFromClass([self class]);
}

#pragma mark - Dynamic Properties

- (dispatch_queue_t)queue {
    if ( !_queue ) {
        _queue = dispatch_queue_create("me.danthorpe.incremental-store", DISPATCH_QUEUE_CONCURRENT);
    }
    return _queue;
}

#pragma mark - Public API

- (NSAttributeDescription *)identifyingAttributeForEntity:(NSEntityDescription *)entity {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Must implement %@ in subclass.", NSStringFromSelector(_cmd)] userInfo:nil];
}

- (id)executeFetchRequest:(NSFetchRequest *)request
              withContext:(NSManagedObjectContext *)context
                    error:(NSError *__autoreleasing *)error {

    NSAssert(self.remoteStore, @"Must have a remote store for DNTIncrementalStore to work.");

    // Execute the fetch request on the remote store.
    [self.remoteStore executeFetchRequest:request withCompletion:^(NSDictionary *representationKeyedByResourceIdentifier, NSError *error) {

        if ( representationKeyedByResourceIdentifier && !error ) {

            // Schedule processing on the context
            [context performBlockAndWait:^{

                // Create a child context
                NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                moc.parentContext = context;
                moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;

                // On this child context, schedule the insertion and/or update of objects from representations
                [moc performBlockAndWait:^{

                    [self insertOrUpdateManagedObjectsFromRemoteRepresentations:representationKeyedByResourceIdentifier ofEntitiy:request.entity inContext:moc completion:^(NSArray *managedObjects, NSArray *backingObjects) {

                        // Get the objects
                        NSSet *childObjects = [moc registeredObjects];

                        // Save the context
                        [moc dnt_save];

                        // Save the backing context
                        [self.backingStack save];

                        // Refresh the objects in the original context
                        [context performBlockAndWait:^{
                            for ( NSManagedObject *object in childObjects ) {
                                NSManagedObject *parentObject = [context objectWithID:object.objectID];
                                [context refreshObject:parentObject mergeChanges:YES];
                            }
                        }];
                    }];
                }];
            }];

        } else if ( error ) {
            DDLogError(@"Error %@ executing fetch request: %@", error, request);
        }
    }];

    id result = nil;

    // Execute the fetch request in the backing stack
    NSManagedObjectContext *backingContext = [self.backingStack managedObjectContext];
    NSFetchRequest *backingFetchRequest = [request copy];
    backingFetchRequest.entity = [NSEntityDescription entityForName:request.entityName inManagedObjectContext:backingContext];

    switch (request.resultType) {

        case NSManagedObjectResultType: {

            backingFetchRequest.resultType = NSDictionaryResultType;
            backingFetchRequest.propertiesToFetch = @[ DNTIncrementalStoreResourceIdentifierAttributeName ];

            NSArray *results = [backingContext executeFetchRequest:backingFetchRequest error:error];
            NSMutableArray *managedObjects = [NSMutableArray arrayWithCapacity:results.count];

            for ( NSString *resourceIdentifier in [results valueForKeyPath:DNTIncrementalStoreResourceIdentifierAttributeName] ) {
                NSManagedObjectID *objectID = [self objectIDForEntity:request.entity withResourceIdentifier:resourceIdentifier];
                NSManagedObject *managedObject = [context objectWithID:objectID];
                [managedObjects addObject:managedObject];
            }

            result = managedObjects;

        } break;

        case NSManagedObjectIDResultType: {

        } break;

        case NSDictionaryResultType:
        case NSCountResultType:
            result = [backingContext executeFetchRequest:backingFetchRequest error:error];
        default:
            break;
    }

    return result;
}

- (id)executeSaveRequest:(NSSaveChangesRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {


    return nil;
}

#pragma mark - NSIncrementalStore

- (BOOL)loadMetadata:(NSError *__autoreleasing *)error {

    if ( !self.backingStack ) {

        // Set the store metadata
        NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
        [metadata setObject:[[NSProcessInfo processInfo] globallyUniqueString] forKey:NSStoreUUIDKey];
        [metadata setObject:[[self class] storeType] forKey:NSStoreTypeKey];
        [self setMetadata:metadata];

        // Create a Core Data stack for locally storing remote objects
        self.backingStack = [self createBackingCoreDataStack];

        // Create a store to keep track of object IDs.
        self.registeredObjectIDsByEntityNameAndResourceIdentifier = [NSMutableDictionary dictionary];

        self.backingObjectIDByObjectID = [NSCache new];

        return YES;
    }

    return NO;
}

- (id)executeRequest:(NSPersistentStoreRequest *)request
         withContext:(NSManagedObjectContext *)context
               error:(NSError *__autoreleasing *)error {

    if ( request.requestType == NSFetchRequestType ) {

        return [self executeFetchRequest:(NSFetchRequest *)request withContext:context error:error];

    } else if ( request.requestType == NSSaveRequestType ) {

        return [self executeSaveRequest:(NSSaveChangesRequest *)request withContext:context error:error];

    } else {
        if ( error ) {
            *error = [[NSError alloc] initWithDomain:DNTIncrementalStoreErrorDomain code:0 userInfo:@{ [NSString stringWithFormat:@"Unknown store request type: %ld", (unsigned long)request.requestType] : NSLocalizedDescriptionKey }];
        }
    }

    return nil;
}

- (id)newValueForRelationship:(NSRelationshipDescription *)relationship forObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {

    id referenceObject = [self referenceObjectForObjectID:objectID];
    NSManagedObjectID *backingObjectID = [self backingObjectIDForEntity:[objectID entity] withResourceIdentifier:DNTResourceIdentifierFromReferenceObject(referenceObject)];
    NSManagedObject *backingObject = (backingObjectID == nil) ? nil : [[self.backingStack managedObjectContext] existingObjectWithID:backingObjectID error:nil];

    if (backingObject) {
        id backingRelationshipObject = [backingObject valueForKeyPath:relationship.name];
        if ([relationship isToMany]) {
            NSMutableArray *mutableObjects = [NSMutableArray arrayWithCapacity:[(NSArray *)backingRelationshipObject count]];
            for ( NSString *resourceIdentifier in [backingRelationshipObject valueForKeyPath:DNTIncrementalStoreResourceIdentifierAttributeName]) {
                NSManagedObjectID *objectID = [self objectIDForEntity:relationship.destinationEntity withResourceIdentifier:resourceIdentifier];
                [mutableObjects addObject:objectID];
            }
            return mutableObjects;
        } else {
            NSString *resourceIdentifier = [backingRelationshipObject valueForKeyPath:DNTIncrementalStoreResourceIdentifierAttributeName];
            NSManagedObjectID *objectID = [self objectIDForEntity:relationship.destinationEntity withResourceIdentifier:resourceIdentifier];
            return objectID ?: [NSNull null];
        }
    } else {
        return [relationship isToMany] ? [NSArray array] : [NSNull null];
    }
}

- (NSArray *)obtainPermanentIDsForObjects:(NSArray *)array error:(NSError *__autoreleasing *)error {
    DDLogError(@"%@", NSStringFromSelector(_cmd));
    return nil;
}

- (NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID
                                         withContext:(NSManagedObjectContext *)context
                                               error:(NSError *__autoreleasing *)error {

    NSString *entityName = [[objectID entity] name];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.fetchLimit = 1;
    fetchRequest.includesSubentities = NO;

    NSArray *attributes = [[[NSEntityDescription entityForName:entityName inManagedObjectContext:context] attributesByName] allValues];
    NSArray *intransientAttributes = [attributes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isTransient == NO"]];
    fetchRequest.propertiesToFetch = [intransientAttributes valueForKeyPath:@"name"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@", DNTIncrementalStoreResourceIdentifierAttributeName, DNTResourceIdentifierFromReferenceObject([self referenceObjectForObjectID:objectID])];

    __block NSArray *results = nil;
    NSManagedObjectContext *backingContext = [self.backingStack managedObjectContext];
    [backingContext performBlockAndWait:^{
        results = [backingContext executeFetchRequest:fetchRequest error:error];
    }];

    NSDictionary *attributeValues = [results lastObject] ?: [NSMutableDictionary dictionary];
    NSIncrementalStoreNode *node = [[NSIncrementalStoreNode alloc] initWithObjectID:objectID withValues:attributeValues version:1];

    return node;
}

- (void)managedObjectContextDidRegisterObjectsWithIDs:(NSArray *)objectIDs {
    [super managedObjectContextDidRegisterObjectsWithIDs:objectIDs];

    for ( NSManagedObjectID *objectID in objectIDs ) {
        id referenceObject = [self referenceObjectForObjectID:objectID];
        if ( !referenceObject ) continue;
        NSString *entityName = [[objectID entity] name];
        NSMutableDictionary *objectIDsByResourceIdentifier = self.registeredObjectIDsByEntityNameAndResourceIdentifier[entityName] ?: [NSMutableDictionary dictionary];
        [objectIDsByResourceIdentifier setObject:objectID forKey:DNTResourceIdentifierFromReferenceObject(referenceObject)];
        [self.registeredObjectIDsByEntityNameAndResourceIdentifier setObject:objectIDsByResourceIdentifier forKey:entityName];
    }
}

- (void)managedObjectContextDidUnregisterObjectsWithIDs:(NSArray *)objectIDs {
    [super managedObjectContextDidUnregisterObjectsWithIDs:objectIDs];
    for ( NSManagedObjectID *objectID in objectIDs ) {
        id referenceObject = [self referenceObjectForObjectID:objectID];
        if ( !referenceObject ) continue;
        NSString *entityName = [[objectID entity] name];
        [self.registeredObjectIDsByEntityNameAndResourceIdentifier[entityName] removeObjectForKey:DNTResourceIdentifierFromReferenceObject(referenceObject)];
    }
}

#pragma mark - Helper Methods

@end

@implementation DNTIncrementalStore ( Private )

- (DNTCoreDataStack *)createBackingCoreDataStack {

    NSManagedObjectModel *model = [self copyModelForBackingStoreFromModel:self.persistentStoreCoordinator.managedObjectModel];

    DNTCoreDataStack *stack = [[DNTCoreDataStack alloc] initWithModel:model name:@"DNTIncrementalStore.BackingStore" configuration:^(NSPersistentStoreCoordinator *persistentStoreCoordinator, NSURL *suggestedStoreURL) {

        // Add an SQLite Store
        NSDictionary *options = @{ NSInferMappingModelAutomaticallyOption : @(YES),
                                   NSMigratePersistentStoresAutomaticallyOption: @(YES) };

        NSError *error = nil;
        NSPersistentStore *sqliteStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:suggestedStoreURL options:options error:&error];

        if ( !sqliteStore && error ) {
            DDLogError(@"Error adding SQLite store: %@", error);
        }
    }];

    return stack;
}

- (NSManagedObjectModel *)copyModelForBackingStoreFromModel:(NSManagedObjectModel *)original {

    // Copy the model
    NSManagedObjectModel *model = [original copy];

    // Add metadata for incremental store
    NSArray *superentities = [model.entities filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSEntityDescription *entity, NSDictionary *bindings) {
        return ![entity superentity];
    }]];

    for ( NSEntityDescription *entity in superentities ) {

        NSAttributeDescription *resourceIdentifierProperty = [NSAttributeDescription new];
        resourceIdentifierProperty.name = DNTIncrementalStoreResourceIdentifierAttributeName;
        resourceIdentifierProperty.attributeType = NSStringAttributeType;
        [resourceIdentifierProperty setIndexed:YES];

        entity.properties = [entity.properties arrayByAddingObjectsFromArray:@[ resourceIdentifierProperty ]];
    }

    return model;
}

- (BOOL)insertOrUpdateManagedObjectsFromRemoteRepresentations:(NSDictionary *)representations ofEntitiy:(NSEntityDescription *)entity inContext:(NSManagedObjectContext *)context completion:(void(^)(NSArray *managedObjects, NSArray *backingObjects))completion {

    NSParameterAssert(context);
    NSParameterAssert(completion);

    // Find these objects in both the context, and the Backing Core Data stack,
    // and either create them if they dont't exist or update them if they do.
    NSArray *keysOfRequiredAttributes = [[self.remoteStore attributesRequiredToRepresentEntity:entity] valueForKeyPath:@"name"];
    NSArray *keysOfRequiredRelationships = [[self.remoteStore relationshipsRequiredToRepresentEntity:entity] valueForKeyPath:@"name"];

    // Create storage for the managed objects which we're going to complete with
    __block NSMutableArray *backingObjects = [NSMutableArray arrayWithCapacity:representations.count];
    __block NSMutableArray *managedObjects = [NSMutableArray arrayWithCapacity:representations.count];

    // Fetch existing objects from the backing context
    NSManagedObjectContext *backingContext = [self.backingStack managedObjectContext];

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        completion(managedObjects, backingObjects);
    });

    @autoreleasepool {
        for ( NSString *identifier in representations ) {

            NSDictionary *representation = [representations objectForKey:identifier];
            NSDictionary *attributes = [representation dictionaryWithValuesForKeys:keysOfRequiredAttributes];

            // Figure out the attributes first
            __block NSManagedObject *managedObject = nil;
            [context performBlockAndWait:^{
                NSManagedObjectID *objectID = [self objectIDForEntity:entity withResourceIdentifier:identifier];
                managedObject = [context existingObjectWithID:objectID error:nil];
            }];
            [managedObject setValuesForKeysWithDictionary:attributes];

            NSManagedObjectID *backingObjectID = [self backingObjectIDForEntity:entity withResourceIdentifier:identifier];
            __block NSManagedObject *backingObject = nil;
            [backingContext performBlockAndWait:^{
                if ( backingObjectID ) {
                    backingObject = [backingContext existingObjectWithID:backingObjectID error:nil];
                } else {
                    backingObject = [NSEntityDescription insertNewObjectForEntityForName:entity.name inManagedObjectContext:backingContext];
                    [backingObject.managedObjectContext obtainPermanentIDsForObjects:@[ backingObject ] error:nil];
                }
            }];
            [backingObject setValue:identifier forKey:DNTIncrementalStoreResourceIdentifierAttributeName];
            [backingObject setValuesForKeysWithDictionary:attributes];

            if ( !backingObjectID ) {
                [context insertObject:managedObject];
            }

            // Get the relationships for this object
            NSDictionary *relationships = [representation dictionaryWithValuesForKeys:keysOfRequiredRelationships];
            for ( NSString *relationshipName in relationships ) {

                NSRelationshipDescription *relationshipDescription = [entity relationshipsByName][relationshipName];
                id relationshipRepresentation = relationships[relationshipName];

                if (!relationshipDescription ||
                    (relationshipDescription.isOptional &&
                     (!relationshipRepresentation || [relationshipRepresentation isEqual:[NSNull null]]))) {
                        continue;
                    }

                if (!relationshipRepresentation ||
                    [relationshipRepresentation isEqual:[NSNull null]] ||
                    ([relationshipRepresentation respondsToSelector:@selector(count)] &&
                     ([relationshipRepresentation count] == 0))) {
                        [managedObject setValue:nil forKey:relationshipName];
                        [backingObject setValue:nil forKey:relationshipName];
                        continue;
                    }

                // Fetch the remote objects
                DNT_WEAK_SELF
                dispatch_group_enter(group);
                [self.remoteStore representationsOfRelationshipRepresentation:relationshipRepresentation ofEntity:relationshipDescription.destinationEntity withCompletion:^(NSDictionary *representationsKeyedByResourceIdentifier, NSError *error) {

                    if ( representationsKeyedByResourceIdentifier && !error ) {

                        [weakSelf insertOrUpdateManagedObjectsFromRemoteRepresentations:representationsKeyedByResourceIdentifier ofEntitiy:relationshipDescription.destinationEntity inContext:context completion:^(NSArray *moreManagedObjects, NSArray *moreBackingObjects) {

                            if ( [relationshipDescription isToMany] ) {
                                if ( [relationshipDescription isOrdered] ) {
                                    [managedObject setValue:[NSOrderedSet orderedSetWithArray:moreManagedObjects] forKey:relationshipName];
                                    [backingObject setValue:[NSOrderedSet orderedSetWithArray:moreBackingObjects] forKey:relationshipName];
                                } else {
                                    [managedObject setValue:[NSSet setWithArray:moreManagedObjects] forKey:relationshipName];
                                    [backingObject setValue:[NSSet setWithArray:moreBackingObjects] forKey:relationshipName];
                                }
                            } else {
                                [managedObject setValue:[moreManagedObjects lastObject] forKey:relationshipName];
                                [backingObject setValue:[moreBackingObjects lastObject] forKey:relationshipName];
                            }

                            [managedObjects addObjectsFromArray:moreManagedObjects];
                            [backingObjects addObjectsFromArray:moreBackingObjects];

                            dispatch_group_leave(group);
                        }];
                    }
                }];
            }
            
            [managedObjects addObject:managedObject];
            [backingObjects addObject:backingObject];
        }
    }

    dispatch_group_leave(group);
    return YES;
}

- (NSManagedObjectID *)objectIDForEntity:(NSEntityDescription *)entity
                  withResourceIdentifier:(NSString *)resourceIdentifier {
    if (!resourceIdentifier) return nil;

    NSManagedObjectID *objectID = self.registeredObjectIDsByEntityNameAndResourceIdentifier[entity.name][resourceIdentifier];

    if ( !objectID ) {
        objectID = [self newObjectIDForEntity:entity referenceObject:DNTReferenceObjectFromResourceIdentifier(resourceIdentifier)];
    }

    NSAssert([objectID.entity.name isEqualToString:entity.name], @"The entity name of the objectID should be: %@", entity.name);
    return objectID;
}

- (NSManagedObjectID *)backingObjectIDForEntity:(NSEntityDescription *)entity
                         withResourceIdentifier:(NSString *)resourceIdentifier {
    if (!resourceIdentifier) return nil;

    NSManagedObjectID *objectID = [self objectIDForEntity:entity withResourceIdentifier:resourceIdentifier];
    __block NSManagedObjectID *backingObjectID = [self.backingObjectIDByObjectID objectForKey:objectID];
    if (backingObjectID) return backingObjectID;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[entity name]];
    fetchRequest.resultType = NSManagedObjectIDResultType;
    fetchRequest.fetchLimit = 1;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@", DNTIncrementalStoreResourceIdentifierAttributeName, resourceIdentifier];

    __block NSError *error = nil;
    NSManagedObjectContext *backingContext = [self.backingStack managedObjectContext];
    [backingContext performBlockAndWait:^{
        backingObjectID = [[backingContext executeFetchRequest:fetchRequest error:&error] lastObject];
    }];

    if ( error ) {
        NSLog(@"Error fetching backing object id: %@", error);
        return nil;
    }

    if (backingObjectID) {
        [self.backingObjectIDByObjectID setObject:backingObjectID forKey:objectID];
    }

    return backingObjectID;
}


@end

/// @name Functions

inline NSString * DNTReferenceObjectFromResourceIdentifier(NSString *resourceIdentifier) {
    return resourceIdentifier ? [DNTReferenceObjectPrefix stringByAppendingString:resourceIdentifier] : nil;
}

inline NSString * DNTResourceIdentifierFromReferenceObject(id referenceObject) {
    if ( !referenceObject ) return nil;
    NSString *string = [referenceObject description];
    return [string hasPrefix:DNTReferenceObjectPrefix] ? [string substringFromIndex:[DNTReferenceObjectPrefix length]] : string;
}

/// @name Constants

NSString * const DNTIncrementalStoreErrorDomain = @"me.danthorpe.incremental-store.error";
NSString * const DNTIncrementalStoreResourceIdentifierAttributeName = @"__dnt_resourceIdentifier";

NSInteger const DNTIncrementalStoreErrorUnknownStoreRequestType = 91000;

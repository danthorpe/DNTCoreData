//
//  DNTIncrementalStore.h
//  YOM
//
//  Created by Daniel Thorpe on 31/12/2013.
//  Copyright (c) 2013 Blinding Skies. All rights reserved.
//

#import <CoreData/CoreData.h>

@class DNTCoreDataStack;
@protocol DNTIncrementalStoreRemoteStore;
@protocol DNTIncrementalStoreRemoteRelationship;

/**
 * @abstract
 * An incremental store subclass which supports a local
 * SQLite backing store, with remote store adaptors.
 */
@interface DNTIncrementalStore : NSIncrementalStore

@property (nonatomic, strong, readonly) DNTCoreDataStack *backingStack;
@property (nonatomic, strong) id <DNTIncrementalStoreRemoteStore> remoteStore;

/**
 @abstract The string used as the NSStoreTypeKey value by the application's persistent store coordinator.
 @discussion This should be over-ridden by subclasses.
 @return A string used to describe the type of the store.
 */
+ (NSString *)storeType;

- (NSAttributeDescription *)identifyingAttributeForEntity:(NSEntityDescription *)entity;

- (id)executeFetchRequest:(NSFetchRequest *)request
              withContext:(NSManagedObjectContext *)context
                    error:(NSError *__autoreleasing *)error;

- (id)executeSaveRequest:(NSSaveChangesRequest *)request
             withContext:(NSManagedObjectContext *)context
                   error:(NSError *__autoreleasing *)error;

@end

@interface DNTIncrementalStore ( Private )

- (DNTCoreDataStack *)createBackingCoreDataStack;

- (NSManagedObjectModel *)copyModelForBackingStoreFromModel:(NSManagedObjectModel *)original;

- (BOOL)insertOrUpdateManagedObjectsFromRemoteRepresentations:(NSDictionary *)representationsKeyedByResourceIdentifier ofEntitiy:(NSEntityDescription *)entity inContext:(NSManagedObjectContext *)context completion:(void(^)(NSArray *managedObjects, NSArray *backingObjects))completion;

- (NSManagedObjectID *)objectIDForEntity:(NSEntityDescription *)entity withResourceIdentifier:(NSString *)resourceIdentifier;

- (NSManagedObjectID *)backingObjectIDForEntity:(NSEntityDescription *)entity withResourceIdentifier:(NSString *)resourceIdentifier;
@end

typedef void(^DNTIncrementalStoreAdaptorCompletionBlock)(NSDictionary *representationsKeyedByResourceIdentifier, NSError *error);


@protocol DNTIncrementalStoreRemoteStore <NSObject>

- (NSArray *)attributesRequiredToRepresentEntity:(NSEntityDescription *)entity;

- (NSArray *)relationshipsRequiredToRepresentEntity:(NSEntityDescription *)entity;

/**
 @abstract Asynchonously execute the fetch request on the remote store.
 @discussion This method doesn't assume or enforce a direct one-to-one
 mapping of local-to-remote entities. Therefore this array should be
 dictionary representations containing the local attributes for this
 entity.
 */
- (void)executeFetchRequest:(NSFetchRequest *)request withCompletion:(DNTIncrementalStoreAdaptorCompletionBlock)completion;

- (void)representationsOfRelationshipRepresentation:(id)representation ofEntity:(NSEntityDescription *)entity withCompletion:(DNTIncrementalStoreAdaptorCompletionBlock)completion;

@end

/// @name Functions

extern NSString * DNTReferenceObjectFromResourceIdentifier(NSString *resourceIdentifier);
extern NSString * DNTResourceIdentifierFromReferenceObject(id referenceObject);

/// @name Constants
extern NSString * const DNTIncrementalStoreErrorDomain;
extern NSString * const DNTIncrementalStoreResourceIdentifierAttributeName;

/// @name Error Codes
extern NSInteger const DNTIncrementalStoreErrorUnknownStoreRequestType;

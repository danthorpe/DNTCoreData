//
//  DNTCoreDataStack.m
//  DNTCOreData
//
//  Created by Daniel Thorpe on 29/12/2013.
//  Copyright (c) 2013 Blinding Skies. All rights reserved.
//

#import "DNTCoreDataStack.h"

@interface DNTCoreDataStack ( /* Private */ )

@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation DNTCoreDataStack

- (instancetype)initWithModelName:(NSString *)modelName configuration:(DNTCoreDataStackConfiguration)config {
    return [self initWithModel:nil name:modelName configuration:config];
}

- (instancetype)initWithModel:(NSManagedObjectModel *)model name:(NSString *)modelName configuration:(DNTCoreDataStackConfiguration)config {
    self = [super init];
    if (self) {
        _managedObjectModel = model;
        _modelName = modelName;
        _configuration = config;
    }
    return self;
}

- (NSManagedObjectModel *)managedObjectModel {
    if ( _managedObjectModel != nil) return _managedObjectModel;

    NSURL *url = [self urlForManagedObjectModel];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];

    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if ( _persistentStoreCoordinator != nil ) return _persistentStoreCoordinator;

    NSManagedObjectModel *model = [self managedObjectModel];

    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

    self.configuration( _persistentStoreCoordinator, [self suggestedStoreURL] );

    NSAssert(self.persistentStoreCoordinator.persistentStores.count > 0, @"The configuration block must configure at least one persistant store.");

    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    if ( _managedObjectContext != nil ) return _managedObjectContext;

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if ( coordinator != nil ) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }

    return _managedObjectContext;
}

- (void)save {
    NSManagedObjectContext *moc = [self managedObjectContext];
    if ( moc != nil && [moc hasChanges] ) {
        NSError *error = nil;
        if ( ![moc save:&error] ) {
            NSLog(@"Error saving MOC: %@", error.userInfo);
        }
    }
}

- (NSURL *)urlForManagedObjectModel {
    if (!self.modelName) {
        [NSException raise:NSInternalInconsistencyException format:@"Attempting to get the URL for model with no model name set."];
    }
    return [[NSBundle bundleForClass:[self class]] URLForResource:self.modelName withExtension:@"momd"];
}

- (NSURL *)suggestedStoreURL {
    NSString *filename = [NSString stringWithFormat:@"%@.store", self.modelName];
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:filename];
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end

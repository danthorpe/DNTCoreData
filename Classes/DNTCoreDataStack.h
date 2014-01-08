//
//  DNTCoreDataStack.h
//  DNTCOreData
//
//  Created by Daniel Thorpe on 29/12/2013.
//  Copyright (c) 2013 Blinding Skies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef void(^DNTCoreDataStackConfiguration)(NSPersistentStoreCoordinator *persistentStoreCoordinator, NSURL *suggestedStoreURL);

@protocol DNTCoreDataStack <NSObject>

- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectContext *)managedObjectContext;
- (void)save;

@end

@interface DNTCoreDataStack : NSObject <DNTCoreDataStack>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSString *modelName;
@property (nonatomic, copy) DNTCoreDataStackConfiguration configuration;

- (instancetype)initWithModelName:(NSString *)modelName configuration:(DNTCoreDataStackConfiguration)config;

/**
 * @discussion
 * The configuration block is called when the NSPsersistentStoreCoordinator is created.
 * This block must add a NSPersistentStore to the coordinator.
 */
- (instancetype)initWithModel:(NSManagedObjectModel *)model name:(NSString *)modelName configuration:(DNTCoreDataStackConfiguration)config;

- (NSURL *)urlForManagedObjectModel;

@end

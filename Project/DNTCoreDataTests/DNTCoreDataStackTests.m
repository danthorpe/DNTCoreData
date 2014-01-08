//
//  DNTCoreDataStackTests.m
//  DNTCoreData
//
//  Created by Daniel Thorpe on 29/12/2013.
//  Copyright (c) 2013 Blinding Skies. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "DNTCoreDataStack.h"

@interface DNTCoreDataStackTests : XCTestCase
@property (nonatomic, strong) DNTCoreDataStack *coreDataStack;
@property (nonatomic, strong) DNTCoreDataStackConfiguration config;
@property (nonatomic, strong) NSPersistentStoreCoordinator *configBlockCalledWithPSC;
@property (nonatomic, strong) NSURL *configCalledWithStoreURL;
@end

@implementation DNTCoreDataStackTests

- (void)setUp {
    [super setUp];
    __weak DNTCoreDataStackTests *weakSelf = self;

    self.config = ^(NSPersistentStoreCoordinator *persistentStoreCoordinator, NSURL *suggestedStoreURL) {
        weakSelf.configBlockCalledWithPSC = persistentStoreCoordinator;
        weakSelf.configCalledWithStoreURL = suggestedStoreURL;
        [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:suggestedStoreURL options:nil error:nil];
    };
    self.coreDataStack = [[DNTCoreDataStack alloc] initWithModelName:@"Model" configuration:self.config];
}

- (void)tearDown {
    self.config = nil;
    self.coreDataStack = nil;
    self.configBlockCalledWithPSC = nil;
    self.configCalledWithStoreURL = nil;
    [super tearDown];
}

- (void)testThat_GivenName_ThenInitializedStackUsesModelName {
    XCTAssertEqualObjects(self.coreDataStack.modelName, @"Model");
}

- (void)testThat_GivenStack_ThenModelIsNotNil {
    NSManagedObjectModel *model = [self.coreDataStack managedObjectModel];
    XCTAssertNotNil(model);
}

- (void)testThat_GivenStack_ThenPersistentStoreCoordinatorUsesModel {
    NSPersistentStoreCoordinator *psc = [self.coreDataStack persistentStoreCoordinator];
    NSManagedObjectModel *model = [self.coreDataStack managedObjectModel];
    XCTAssertNotNil(psc);
    XCTAssertEqualObjects(psc.managedObjectModel, model);
}

- (void)testThat_GivenStack_ThenConfigurationBlockIsExecuted_WhenAccessingPersistentStoreCoordinate {
    NSPersistentStoreCoordinator *psc = [self.coreDataStack persistentStoreCoordinator];
    XCTAssertNotNil(psc);
    XCTAssertEqualObjects(psc, self.configBlockCalledWithPSC);
    XCTAssertEqualObjects(psc.managedObjectModel, [self.coreDataStack managedObjectModel]);
}

- (void)testThat_GivenStack_ThenManagedObjectContextUsesPersistentStoreCoordinate {
    NSManagedObjectContext *moc = [self.coreDataStack managedObjectContext];
    NSPersistentStoreCoordinator *psc = [self.coreDataStack persistentStoreCoordinator];
    XCTAssertNotNil(moc);
    XCTAssertEqualObjects(moc.persistentStoreCoordinator, psc);
}

- (void)testThat_GivenStack_ThenManagedObjectContextIsCreated_WhenCalled {
    NSManagedObjectContext *moc = [self.coreDataStack managedObjectContext];
    XCTAssertNotNil(moc);
    XCTAssertEqualObjects(moc.persistentStoreCoordinator, [self.coreDataStack persistentStoreCoordinator]);
}

- (void)testThat_WhenSave_ThenManagedObjectContextReceivesSave {
    // Setup
    id mockContext = [OCMockObject niceMockForClass:[NSManagedObjectContext class]];
    [[[mockContext expect] andReturnValue:@YES] hasChanges];
    [[[mockContext expect] andReturnValue:@YES] save:(NSError * __autoreleasing *)[OCMArg anyPointer]];

    self.coreDataStack.managedObjectContext = mockContext;
    [self.coreDataStack save];

    XCTAssertNoThrow([mockContext verify]);
}

@end

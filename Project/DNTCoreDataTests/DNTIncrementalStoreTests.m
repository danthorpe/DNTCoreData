//
//  DNTIncrementalStoreTests.m
//  YOM
//
//  Created by Daniel Thorpe on 01/01/2014.
//  Copyright (c) 2014 Blinding Skies. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "DNTIncrementalStore.h"

@interface DNTIncrementalStoreTests : XCTestCase
@property (nonatomic, strong) NSManagedObjectModel *model;
@property (nonatomic, strong) NSPersistentStoreCoordinator *psc;
@property (nonatomic, strong) DNTIncrementalStore *incrementalStore;
@end

@implementation DNTIncrementalStoreTests

- (void)setUp {
    [super setUp];
    self.model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[self urlForModel]];
    self.psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
    self.incrementalStore = [[DNTIncrementalStore alloc] initWithPersistentStoreCoordinator:self.psc configurationName:nil URL:nil options:nil];
}

- (void)tearDown {
    self.model = nil;
    self.psc = nil;
    self.incrementalStore = nil;
    [super tearDown];
}

- (void)testThat_GivenStore_WhenLoadingMetadata_ThenBackingStackIsCreated {
    [self.incrementalStore loadMetadata:nil];
    XCTAssertNotNil(self.incrementalStore.backingStack);
}

#pragma mark - Helpers

- (NSURL *)urlForModel {
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"Test" withExtension:@"momd"];
    return url;
}

@end

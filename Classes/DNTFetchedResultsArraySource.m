//
//  BSFetchedResultsArraySource.m
//  YOM
//
//  Created by Daniel Thorpe on 29/12/2013.
//  Copyright (c) 2013 Blinding Skies. All rights reserved.
//

#import "DNTFetchedResultsArraySource.h"

@interface DNTFetchedResultsArraySource ( /* Private */ )
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) UICollectionView *collectionView;
@end

@implementation DNTFetchedResultsArraySource

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext:(NSManagedObjectContext *)context cellConfigurationBlock:(DNTFetchedResultsCellConfigurationBlock)cellConfigurationBlock {

    self = [super init];
    if (self) {
        _cellConfigurationBlock = cellConfigurationBlock;
        _fetchRequest = fetchRequest;
        _managedObjectContext = context;
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:_fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsController.delegate = self;
    }
    return self;
}

#pragma mark - Dynamic Properties

- (void)setView:(id)view {
    if ( ![_view isEqual:view] ) {
        _view = view;
        _tableView = [view isKindOfClass:[UITableView class]] ? view : nil;
        _collectionView = [view isKindOfClass:[UICollectionView class]] ? view : nil;
    }
}

#pragma mark - Public API

- (void)executeFetch {
    NSError *error = nil;
    BOOL success = [self.fetchedResultsController performFetch:&error];
    if ( !success && error ) {
        NSLog(@"Error performing fetch for FRC: %@", self.fetchedResultsController);
    }
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    id object = [self objectAtIndexPath:indexPath];
    return self.cellConfigurationBlock( collectionView, object, indexPath );
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id object = [self objectAtIndexPath:indexPath];
    return self.cellConfigurationBlock( tableView, object, indexPath );
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if ( !self.changeIsUserDriven ) {
        [self.tableView beginUpdates];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

    if ( !self.changeIsUserDriven ) {
        NSIndexSet *indexSet =[NSIndexSet indexSetWithIndex:sectionIndex];

        switch (type) {

            case NSFetchedResultsChangeInsert: {
                [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.collectionView insertSections:indexSet];
            } break;

            case NSFetchedResultsChangeDelete: {
                [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.collectionView deleteSections:indexSet];
            } break;
                
            default:
                break;
        }
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

    if ( !self.changeIsUserDriven ) {
        switch (type) {
            case NSFetchedResultsChangeInsert: {
                [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.collectionView insertItemsAtIndexPaths:@[ newIndexPath ]];
            } break;

            case NSFetchedResultsChangeDelete: {
                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.collectionView deleteItemsAtIndexPaths:@[ indexPath ]];
            } break;

            case NSFetchedResultsChangeUpdate: {
                NSAssert(self.view, @"Must set the view object on the fetched results controller.");
                self.cellConfigurationBlock(self.view, anObject, indexPath);
            } break;

            case NSFetchedResultsChangeMove: {
                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.collectionView deleteItemsAtIndexPaths:@[ indexPath ]];
                [self.collectionView insertItemsAtIndexPaths:@[ indexPath ]];
            } break;
                
            default:
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if ( !self.changeIsUserDriven ) {
        [self.tableView endUpdates];
    }
}

@end

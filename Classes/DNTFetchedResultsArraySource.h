//
//  DNTFetchedResultsArraySource.h
//  YOM
//
//  Created by Daniel Thorpe on 29/12/2013.
//  Copyright (c) 2013 Blinding Skies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

typedef id(^DNTFetchedResultsCellConfigurationBlock)(id view, id object, NSIndexPath *indexPath);

@interface DNTFetchedResultsArraySource : NSObject <UITableViewDataSource, UICollectionViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchRequest *fetchRequest;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) id view;
@property (nonatomic, copy) DNTFetchedResultsCellConfigurationBlock cellConfigurationBlock;
@property (nonatomic) BOOL changeIsUserDriven;

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext:(NSManagedObjectContext *)context cellConfigurationBlock:(DNTFetchedResultsCellConfigurationBlock)cellConfigurationBlock;

- (void)executeFetch;

- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

@end

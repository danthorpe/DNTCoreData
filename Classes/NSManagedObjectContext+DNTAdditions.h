//
//  NSManagedObjectContext+DNTAdditions.h
//  DNTCoreDataStack
//
//  Created by Daniel Thorpe on 01/01/2014.
//  Copyright (c) 2014 Blinding Skies. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (DNTAdditions)

#pragma mark -

- (void)dnt_save;

- (NSArray *)dnt_fetchObjectsForRequest:(NSFetchRequest *)fetchRequest;
- (NSFetchRequest *)dnt_fetchRequestForEntity:(NSEntityDescription *)entity;
- (NSFetchRequest *)dnt_fetchRequestForEntityName:(NSString *)entityName;

#pragma mark - Counts

- (NSUInteger)dnt_countForEntityName:(NSString *)entityName
                      withPredicate:(NSPredicate *)predicate;

- (NSUInteger)dnt_countForEntityName:(NSString *)entityName
                withPredicateFormat:(NSString *)format
                          arguments:(va_list)arguments;

- (NSUInteger)dnt_countForEntityName:(NSString *)entityName
                withPredicateFormat:(NSString *)format, ... NS_REQUIRES_NIL_TERMINATION;

#pragma mark - Objects

- (NSArray *)dnt_fetchObjectArrayForEntityName:(NSString *)entityName
                         usingSortDescriptors:(NSArray *)sortDescriptors
                                withPredicate:(NSPredicate *)predicate;

- (NSArray *)dnt_fetchObjectArrayForEntityName:(NSString *)entityName
                         usingSortDescriptors:(NSArray *)sortDescriptors
                          withPredicateFormat:(NSString *)format
                                    arguments:(va_list)arguments;

- (NSArray *)dnt_fetchObjectArrayForEntityName:(NSString *)entityName
                         usingSortDescriptors:(NSArray *)sortDescriptors
                          withPredicateFormat:(NSString *)format, ... NS_REQUIRES_NIL_TERMINATION;

- (NSArray *)dnt_fetchObjectArrayForEntityName:(NSString *)entityName
                          withPredicateFormat:(NSString *)format, ... NS_REQUIRES_NIL_TERMINATION;

- (NSArray *)dnt_fetchObjectArrayForEntityName:(NSString *)entityName
                         usingSortDescriptors:(NSArray *)sortDescriptors;

- (id)dnt_firstObjectForEntityName:(NSString *)entityName
             usingSortDescriptors:(NSArray *)sortDescriptors
                    withPredicate:(NSPredicate *)predicate;

- (id)dnt_firstObjectForEntityName:(NSString *)entityName
             usingSortDescriptors:(NSArray *)sortDescriptors
              withPredicateFormat:(NSString *)format
                        arguments:(va_list)arguments;

- (id)dnt_firstObjectForEntityName:(NSString *)entityName
             usingSortDescriptors:(NSArray *)sortDescriptors
              withPredicateFormat:(NSString *)format, ... NS_REQUIRES_NIL_TERMINATION;

- (id)dnt_firstObjectForEntityName:(NSString *)entityName
              withPredicateFormat:(NSString *)format, ... NS_REQUIRES_NIL_TERMINATION;


#pragma mark - Value

- (id)dnt_fetchValueForEntityName:(NSString *)entityName
                  usingAttribute:(NSString *)attributeName
                     andFunction:(NSString *)function
                   withPredicate:(NSPredicate *)predicate;

- (id)dnt_fetchValueForEntityName:(NSString *)entityName
                  usingAttribute:(NSString *)attributeName
                     andFunction:(NSString *)function
             withPredicateFormat:(NSString *)format
                       arguments:(va_list)arguments;

- (id)dnt_fetchValueForEntityName:(NSString *)entityName
                  usingAttribute:(NSString *)attributeName
                     andFunction:(NSString *)function
             withPredicateFormat:(NSString *)format, ... NS_REQUIRES_NIL_TERMINATION;

- (id)dnt_fetchValueForEntityName:(NSString *)entityName
                  usingAttribute:(NSString *)attributeName
                     andFunction:(NSString *)function;


#pragma mark - Changes

- (NSSet *)dnt_registeredObjectsOfEntityName:(NSString *)entityName
                              withPredicate:(NSPredicate *)predicate;



@end

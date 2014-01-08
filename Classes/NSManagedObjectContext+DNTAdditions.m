//
//  NSManagedObjectContext+DNTAdditions.m
//  YOM
//
//  Created by Daniel Thorpe on 01/01/2014.
//  Copyright (c) 2014 Blinding Skies. All rights reserved.
//

#import "NSManagedObjectContext+DNTAdditions.h"

@implementation NSManagedObjectContext (DNTAdditions)

#pragma mark -

- (void)dnt_save {
    NSError *error = nil;
    if ( ![self save:&error] ) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[error localizedFailureReason] userInfo:[NSDictionary dictionaryWithObject:error forKey:NSUnderlyingErrorKey]];
    }
}

- (NSArray *)dnt_fetchObjectsForRequest:(NSFetchRequest *)fetchRequest {
	NSError *error = nil;
	NSArray *results = [self executeFetchRequest:fetchRequest error:&error];

    NSAssert(error == nil, [error description]);

    return results;
}

- (NSFetchRequest *)dnt_fetchRequestForEntity:(NSEntityDescription *)entity {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	request.entity = entity;

    return request;
}

- (NSFetchRequest *)dnt_fetchRequestForEntityName:(NSString *)entityName {
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];

	return [self dnt_fetchRequestForEntity:entity];
}

#pragma mark - Counts

- (NSUInteger)dnt_countForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate {
	NSFetchRequest *request = [self dnt_fetchRequestForEntityName:entityName];

	if (predicate) {
		request.predicate = predicate;
	}

	NSError *error = nil;
	NSUInteger result = [self countForFetchRequest:request error:&error];

	NSAssert(error == nil, [error description]);

	return result;
}

- (NSUInteger)dnt_countForEntityName:(NSString *)entityName withPredicateFormat:(NSString *)format arguments:(va_list)arguments {
	NSPredicate *predicate = nil;
	if (format) {
		predicate = [NSPredicate predicateWithFormat:format arguments:arguments];
	}

	return [self dnt_countForEntityName:entityName withPredicate:predicate];
}

- (NSUInteger)dnt_countForEntityName:(NSString *)entityName withPredicateFormat:(NSString *)format, ... NS_REQUIRES_NIL_TERMINATION {
	va_list arguments;
	va_start(arguments, format);
	NSUInteger result = [self dnt_countForEntityName:entityName withPredicateFormat:format arguments:arguments];
	va_end(arguments);

	return result;
}


#pragma mark - Objects

- (NSArray *)dnt_fetchObjectArrayForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors withPredicate:(NSPredicate *)predicate {
	NSFetchRequest *request = [self dnt_fetchRequestForEntityName:entityName];

	if (sortDescriptors) {
		request.sortDescriptors = sortDescriptors;
	}

	if (predicate) {
		request.predicate = predicate;
	}

	NSError *error = nil;
	NSArray *results = [self executeFetchRequest:request error:&error];

	NSAssert(error == nil, [error description]);

	return results;
}

- (NSArray *)dnt_fetchObjectArrayForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors withPredicateFormat:(NSString *)format arguments:(va_list)arguments {
	NSPredicate *predicate = nil;
	if (format) {
		predicate = [NSPredicate predicateWithFormat:format arguments:arguments];
	}

	return [self dnt_fetchObjectArrayForEntityName:entityName usingSortDescriptors:sortDescriptors withPredicate:predicate];
}

- (NSArray *)dnt_fetchObjectArrayForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors withPredicateFormat:(NSString *)format, ... NS_REQUIRES_NIL_TERMINATION {
	va_list arguments;
	va_start(arguments, format);
	NSArray *results = [self dnt_fetchObjectArrayForEntityName:entityName usingSortDescriptors:sortDescriptors withPredicateFormat:format arguments:arguments];
	va_end(arguments);

	return results;
}

- (NSArray *)dnt_fetchObjectArrayForEntityName:(NSString *)entityName withPredicateFormat:(NSString *)format, ... NS_REQUIRES_NIL_TERMINATION {
	va_list arguments;
	va_start(arguments, format);
	NSArray *results = [self dnt_fetchObjectArrayForEntityName:entityName usingSortDescriptors:nil withPredicateFormat:format arguments:arguments];
	va_end(arguments);

	return results;
}

- (NSArray *)dnt_fetchObjectArrayForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors {
	return [self dnt_fetchObjectArrayForEntityName:entityName usingSortDescriptors:sortDescriptors withPredicate:nil];
}

- (id)dnt_firstObjectForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors withPredicate:(NSPredicate *)predicate {
    NSArray *results = [self dnt_fetchObjectArrayForEntityName:entityName usingSortDescriptors:sortDescriptors withPredicate:predicate];
    if ([results count] > 0) {
        return [results objectAtIndex:0];
    } else {
        return nil;
    }
}

- (id)dnt_firstObjectForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors withPredicateFormat:(NSString *)format arguments:(va_list)arguments {
    NSArray *results = [self dnt_fetchObjectArrayForEntityName:entityName usingSortDescriptors:sortDescriptors withPredicateFormat:format arguments:arguments];
    if ([results count] > 0) {
        return [results objectAtIndex:0];
    } else {
        return nil;
    }
}

- (id)dnt_firstObjectForEntityName:(NSString *)entityName usingSortDescriptors:(NSArray *)sortDescriptors withPredicateFormat:(NSString *)format, ... NS_REQUIRES_NIL_TERMINATION {
	va_list arguments;
	va_start(arguments, format);
	NSArray *results = [self dnt_fetchObjectArrayForEntityName:entityName usingSortDescriptors:sortDescriptors withPredicateFormat:format arguments:arguments];
	va_end(arguments);

    if ([results count] > 0) {
        return [results objectAtIndex:0];
    } else {
        return nil;
    }
}

- (id)dnt_firstObjectForEntityName:(NSString *)entityName withPredicateFormat:(NSString *)format, ... NS_REQUIRES_NIL_TERMINATION {
	va_list arguments;
	va_start(arguments, format);
	NSArray *results = [self dnt_fetchObjectArrayForEntityName:entityName usingSortDescriptors:nil withPredicateFormat:format arguments:arguments];
	va_end(arguments);

    if ([results count] > 0) {
        return [results objectAtIndex:0];
    } else {
        return nil;
    }
}


#pragma mark - Value

- (id)dnt_fetchValueForEntityName:(NSString *)entityName usingAttribute:(NSString *)attributeName andFunction:(NSString *)function withPredicate:(NSPredicate *)predicate {
	id value = nil;

	// Get the entity so we can check its attribute information
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];

	NSAttributeDescription *attribute = [[entity attributesByName] objectForKey:attributeName];
	if (attribute) {
		NSFetchRequest *request = [self dnt_fetchRequestForEntity:entity];

		NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:attributeName];
		NSExpression *functionExpression = [NSExpression expressionForFunction:function arguments:[NSArray arrayWithObject:keyPathExpression]];

		NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
		[expressionDescription setName:attributeName];
		[expressionDescription setExpression:functionExpression];
		[expressionDescription setExpressionResultType:[attribute attributeType]];

		[request setResultType:NSDictionaryResultType];
		[request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];

		if (predicate) {
			[request setPredicate:predicate];
		}

		NSError *error = nil;
		NSArray *results = [self executeFetchRequest:request error:&error];
		NSAssert(error == nil, [error description]);

		if (results) {
			value = [[results lastObject] valueForKey:attributeName];
		}
	}

	return value;
}

- (id)dnt_fetchValueForEntityName:(NSString *)entityName usingAttribute:(NSString *)attributeName andFunction:(NSString *)function withPredicateFormat:(NSString *)format arguments:(va_list)arguments {
	NSPredicate *predicate = nil;
	if (format) {
		predicate = [NSPredicate predicateWithFormat:format arguments:arguments];
	}

	return [self dnt_fetchValueForEntityName:entityName usingAttribute:attributeName andFunction:function withPredicate:predicate];
}

- (id)dnt_fetchValueForEntityName:(NSString *)entityName usingAttribute:(NSString *)attributeName andFunction:(NSString *)function withPredicateFormat:(NSString *)format, ... NS_REQUIRES_NIL_TERMINATION {
	id result = nil;

	va_list arguments;
	va_start(arguments, format);
	result = [self dnt_fetchValueForEntityName:entityName usingAttribute:attributeName andFunction:function withPredicateFormat:format arguments:arguments];
	va_end(arguments);

	return result;
}

- (id)dnt_fetchValueForEntityName:(NSString *)entityName usingAttribute:(NSString *)attributeName andFunction:(NSString *)function {
	return [self dnt_fetchValueForEntityName:entityName usingAttribute:attributeName andFunction:function withPredicate:nil];
}


#pragma mark - Changes

- (NSSet *)dnt_registeredObjectsOfEntityName:(NSString *)entityName
                           withPredicate:(NSPredicate *)predicate {
    // Create a predicate for the entity name
    NSPredicate *entityNamePredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [entityName isEqualToString:NSStringFromClass([evaluatedObject class])];
    }];

    // Define the filter predicate
    NSPredicate *filter = nil;

    if (predicate) {
        // Create a filter predicate
        filter = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:entityNamePredicate, predicate, nil]];
    } else {
        filter = entityNamePredicate;
    }

    // Filter the registered objects
    NSSet *filtered = [[self registeredObjects] filteredSetUsingPredicate:filter];

    return filtered;
}

@end

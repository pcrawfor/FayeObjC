//
//  NSString+InflectionSupport.h
//  
//
//  Created by Ryan Daigle on 7/31/08.
//  Copyright 2008 yFactorial, LLC. All rights reserved.
//

@interface NSString (InflectionSupport)

/**
 * Return the camelCase form af this dashed/underscored string:
 *
 *   [@"camel-case_string" camelize] //> @"camelCaseString"
 */
- (NSString *)faye_camelize;

/**
 * Return a copy of the string with the first letter capitalized.
 */
- (NSString *)faye_toClassName;

@end

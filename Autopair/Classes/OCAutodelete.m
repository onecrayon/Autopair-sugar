//
//  OCAutodelete.m
//  Autopair
//
//  Created by Ian Beck on 5/21/14.
//  Copyright (c) 2014 One Crayon. MIT license.
//

#import "OCAutodelete.h"
#import <EspressoTextActions.h>

@implementation OCAutodelete

- (id)initWithDictionary:(NSDictionary *)dictionary bundlePath:(NSString *)bundlePath
{
	self = [super init];
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (NSString *)titleWithContext:(id)context
{
	return nil;
}

- (BOOL)canPerformActionWithContext:(id)context
{
	NSRange range = [[[context selectedRanges] objectAtIndex:0] rangeValue];
	if ([[context selectedRanges] count] > 1 || [self autopairMode] == 0 || range.length > 0 || range.location == 0 || range.location == [[context string] length]) {
		return NO;
	}
	NSString *prevCharacter = [[context string] substringWithRange:NSMakeRange(range.location - 1, 1)];
	NSString *nextCharacter = [[context string] substringWithRange:NSMakeRange(range.location, 1)];
	NSString *balancedCharacter = [self balancingCharacterFor:prevCharacter withRange:range inContext:context];
	return balancedCharacter != nil && [nextCharacter isEqualToString:balancedCharacter];
}

- (BOOL)performActionWithContext:(id)context error:(NSError **)outError
{
	CETextRecipe *recipe = [CETextRecipe textRecipe];
	NSRange range = [[[context selectedRanges] objectAtIndex:0] rangeValue];
	[context setSelectedRanges:@[[NSValue valueWithRange:NSMakeRange(range.location + 1, 0)]]];
	[recipe deleteRange:NSMakeRange(range.location - 1, 2)];
	return [context applyTextRecipe:recipe];
}

@end

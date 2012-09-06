//
//  OCAutoclose.m
//  Autopair
//
//  Created by Ian Beck on 9/6/12.
//  Copyright 2012 One Crayon. MIT license.
//

#import "OCAutoclose.h"
#import <EspressoTextActions.h>
#import <NSString+MRFoundation.h>
#import <MRRangeSet.h>


@implementation OCAutoclose

- (void)dealloc
{
    [super dealloc];
}

- (BOOL)canPerformActionWithContext:(id)context
{
	NSRange range = [[[context selectedRanges] objectAtIndex:0] rangeValue];
	return [self autopairMode] > 0 && range.length == 0 && range.location < [[context string] length] && [[[context string] substringWithRange:NSMakeRange(range.location, 1)] isEqualToString:character] && [context settingForKey:@"autopair-opt-in" inRange:range] != nil && [[context settingForKey:@"autopair-opt-in" inRange:range] containsString:balancedCharacter];
}

- (NSString *)titleWithContext:(id)context
{
	return nil;
}

- (BOOL)performActionWithContext:(id)context error:(NSError **)outError
{
	// TODO: check if we need to skip over the closing character, or if we are closing an unbalanced delimiter
	BOOL skipCharacter = NO;
	NSRange range = [[[context selectedRanges] objectAtIndex:0] rangeValue];
	if ([character isEqualToString:@"'"] || [character isEqualToString:@"\""]) {
		// Dealing with a string, so we just need to check if we are adjacent to a string closing delimiter
		SXSelector *stringZone = [SXSelector selectorWithString:@"string punctuation.definition.end"];
		if ([stringZone matches:[[context syntaxTree] zoneAtCharacterIndex:range.location]]) {
			skipCharacter = YES;
		}
	} else {
		// FIXME: Switch to a parsing-based method of detecting balanced braces? This is likely faster, but far more prone to errors
		// Dealing with a brace, so we need to see if the braces in the document are balanced
		// Rather than parse through everything, we are just doing a simple count
		// First, figure out the ranges that are not strings or comments
		SXSelectorGroup *ignoredZones = [SXSelectorGroup selectorGroupWithString:@"string, comment, regex"];
		NSArray *ignoredSelectables = [[[context syntaxTree] rootZone] descendantSelectablesMatchingSelectors:ignoredZones];
		MRRangeSet *rangeSet = [MRRangeSet rangeSet];
		[rangeSet unionRange:NSMakeRange(0, [[context string] length])];
		for (id zone in ignoredSelectables) {
			[rangeSet minusRange:[zone range]];
		}
		// Now that we have our ranges (sans comments and strings), find the number of braces
		NSUInteger openBraces = 0;
		NSUInteger closeBraces = 0;
		NSString *text;
		for (NSValue *value in [rangeSet ranges]) {
			text = [[context string] substringWithRange:[value rangeValue]];
			openBraces += [[text componentsSeparatedByString:balancedCharacter] count] - 1;
			closeBraces += [[text componentsSeparatedByString:character] count] - 1;
		}
		if (openBraces == closeBraces) {
			// Equal number of braces, so skip over the character
			skipCharacter = YES;
		}
	}
	
	if (skipCharacter) {
		[context setSelectedRanges:[NSArray arrayWithObject:[NSValue valueWithRange:NSMakeRange(range.location + 1, 0)]]];
		return YES;
	} else {
		// We don't have a balanced character, so just insert the character
		CETextRecipe *recipe = [CETextRecipe textRecipe];
		[recipe insertString:character atIndex:range.location];
		return [context applyTextRecipe:recipe];
	}
}

@end

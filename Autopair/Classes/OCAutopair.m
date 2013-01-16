//
//  OCAutopair.m
//  Autopair
//
//  Created by Ian Beck on 10/13/11.
//  Copyright 2011 One Crayon. MIT license.
//

#import "OCAutopair.h"
#import <EspressoTextActions.h>
#import <NSString+MRFoundation.h>


@implementation OCAutopair

+ (void)load
{
	[super load];
	
	// This is really a bit of a hacky way to approach this, but it works...
	// Runs one-time initialization code upon bundle load
	// Setup the default preferences, in case they've never been modified
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:1] forKey:@"OCAutopairMode"]];
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:0] forKey:@"OCAutopairSelectionMode"]];
}

- (id)initWithDictionary:(NSDictionary *)dictionary bundlePath:(NSString *)bundlePath
{
	self = [super init];
    if (self) {
        character = [[dictionary objectForKey:@"character"] retain];
    }
    
    return self;
}

- (void)dealloc
{
	MRRelease(character);
    [super dealloc];
}

- (BOOL)canPerformActionWithContext:(id)context
{
	NSRange range = [[[context selectedRanges] objectAtIndex:0] rangeValue];
	NSString *balancedCharacter = [self balancingCharacterFor:character withRange:range inContext:context];
	if ([character isEqualToString:balancedCharacter] && range.length == 0 && range.location < [[context string] length] && [[[context string] substringWithRange:NSMakeRange(range.location, 1)] isEqualToString:character]) {
		// Make sure that autopair doesn't trigger when autoclose is needed
		return NO;
	} else {
		return [self autopairMode] > 0 && balancedCharacter != nil;
	}
}

- (NSString *)titleWithContext:(id)context
{
	NSRange range = [[[context selectedRanges] objectAtIndex:0] rangeValue];
	// FIXME: figure out how to localize this!
	if (range.length > 0 && [self autopairSelectionMode]) {
		NSString *balancedCharacter = [self balancingCharacterFor:character withRange:range inContext:context];
		return (balancedCharacter != nil ? [NSString stringWithFormat:@"Wrap With %@ %@", character, balancedCharacter] : @"Disabled");
	} else {
		return [NSString stringWithFormat:@"Autopair %@", character];
	}
}

- (BOOL)performActionWithContext:(id)context error:(NSError **)outError
{
	BOOL autopair = NO;
	NSRange range = [[[context selectedRanges] objectAtIndex:0] rangeValue];
	if ([self autopairMode] == 1 && range.length == 0) {
		/*
		 Only autopair if:
		 
		 - We are the last thing on the line (excluding whitespace)
		 - The following character is common syntactic punctuation (excluding whitespace)
		 */
		// Grab the string for the end of the line
		NSUInteger nextStartIndex = [[context lineStorage] lineStartIndexGreaterThanIndex:range.location];
		if (nextStartIndex == NSNotFound) {
			nextStartIndex = [[context string] length];
		}
		NSString *lineEndString = [[context string] substringWithRange:NSMakeRange(range.location, nextStartIndex - range.location)];
		if ([lineEndString length] == 0) {
			// End of the document, so definitely autopair
			autopair = YES;
		} else {
			// These are the characters that are most commonly syntactically-relevant in the majority of languages that Espresso supports
			NSCharacterSet *legalChars = [NSCharacterSet characterSetWithCharactersInString:@";]})!=|><&:+-.?,^~*/%"];
			NSCharacterSet *whitespaceChars = [NSCharacterSet whitespaceCharacterSet];
			// Parse through the line end to make sure it's legal
			NSUInteger index = 0;
			unichar testChar;
			while (index < [lineEndString length]) {
				// Grab our character and increment the index
				testChar = [lineEndString characterAtIndex:index];
				index++;
				// Check to see if we are a legal character or we are at the end of the string
				if ([legalChars characterIsMember:testChar] || index == [lineEndString length]) {
					autopair = YES;
					break;
				} else if (![whitespaceChars characterIsMember:testChar]) {
					// If the character isn't whitespace or a legal character, then break out and don't autopair
					break;
				}
			}
		}
	} else {
		// "Always autopair", or else we are wrapping a selection (in which case we always act because they must have explicitly chosen it from the menu)
		autopair = YES;
	}
	
	CETextSnippet *snippet;
	if (autopair) {
		// Easiest just to backslash all characters for safety
		if ([self autopairSelectionMode]) {
			snippet = [CETextSnippet snippetWithString:[NSString stringWithFormat:@"\\%@${1:$EDITOR_SELECTION}\\%@", character, [self balancingCharacterFor:character withRange:range inContext:context]]];
		} else {
			snippet = [CETextSnippet snippetWithString:[NSString stringWithFormat:@"\\%@$1\\%@", character, [self balancingCharacterFor:character withRange:range inContext:context]]];
		}
	} else {
		// Always insert the character they typed
		snippet = [CETextSnippet snippetWithString:[NSString stringWithFormat:@"\\%@$0", character]];
	}
	
	return [context insertTextSnippet:snippet options:CETextOptionVerbatim];
}

- (NSInteger)autopairMode
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:@"OCAutopairMode"];
}
			
- (NSInteger)autopairSelectionMode
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:@"OCAutopairSelectionMode"];
}

- (NSString *)balancingCharacterFor:(NSString *)targetCharacter withRange:(NSRange)range inContext:(id)context
{
	NSString *optInString = [context settingForKey:@"autopair-opt-in" inRange:range];
	// If we don't have an opt-in, return nil
	if (optInString == nil)
		return nil;
	NSRange charRange = [optInString rangeOfString:targetCharacter];
	// If the character isn't in the opt-in, return nil
	if (charRange.location == NSNotFound)
		return nil;
	// If the character doesn't have a balanced character (end of the opt-in string), return the character
	if (charRange.location + charRange.length == [optInString length])
		return targetCharacter;
	// We have a balanced character, so return that
	return [optInString substringWithRange:NSMakeRange(charRange.location + charRange.length, 1)];
}

@end

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
		 - The previous character(s) are not an even number of backslashes (we don't want to pair when they are escaping the paired character because we cannnot predict what they are doing)
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
			// If we can autopair, ensure we are not working with a backslash escaped character
			if (autopair && range.location > 0 && [[[context string] substringWithRange:NSMakeRange(range.location - 1, 1)] isEqualToString:@"\\"]) {
				NSUInteger prevStartIndex = range.location - 1;
				NSUInteger totalBackslashes = 0;
				while ([[[context string] substringWithRange:NSMakeRange(prevStartIndex, 1)] isEqualToString:@"\\"]) {
					totalBackslashes++;
					if (prevStartIndex == 0) {
						break;
					} else {
						prevStartIndex--;
					}
				}
				// If we have an odd number of backslashes, do not autopair
				if (totalBackslashes % 2) {
					autopair = NO;
				}
			}
		}
	} else {
		// "Always autopair", or else we are wrapping a selection (in which case we always act because they must have explicitly chosen it from the menu)
		autopair = YES;
	}
	
	CETextSnippet *snippet;
	if (autopair) {
		NSString *balancedCharacter = [self balancingCharacterFor:character withRange:range inContext:context];
		// Easiest just to backslash all characters for safety
		if ([self autopairSelectionMode]) {
			snippet = [CETextSnippet snippetWithString:[NSString stringWithFormat:@"\\%@${1:$EDITOR_SELECTION}\\%@", character, balancedCharacter]];
		} else {
			// If we are working with Python, check for a preceding double quotes (means we are completing a triple quoted string)
			SXSelector *pythonRoot = [SXSelector selectorWithString:@"language-root.python"];
			if ([character isEqualToString:balancedCharacter] && range.location >= 2 && [pythonRoot matches:[[context syntaxTree] rootZone]] && [[[context string] substringWithRange:NSMakeRange(range.location - 2, 2)] isEqualToString:[@"" stringByPaddingToLength:2 withString:character startingAtIndex:0]]) {
				snippet = [CETextSnippet snippetWithString:[NSString stringWithFormat:@"\\%@$1\\%@", character, [@"" stringByPaddingToLength:3 withString:character startingAtIndex:0]]];
			} else {
				snippet = [CETextSnippet snippetWithString:[NSString stringWithFormat:@"\\%@$1\\%@", character, balancedCharacter]];
			}
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

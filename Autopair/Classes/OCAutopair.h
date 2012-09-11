//
//  OCAutopair.h
//  Autopair
//
//  Created by Ian Beck on 10/13/11.
//  Copyright 2011 One Crayon. MIT license.
//

#import <Foundation/Foundation.h>


@interface OCAutopair : NSObject {
@protected
    NSString *character;
}

- (NSInteger)autopairMode;
- (NSString *)balancingCharacterFor:(NSString *)character withRange:(NSRange)range inContext:(id)context;

@end

//
//  OCAutopair.h
//  Autopair
//
//  Created by Ian Beck on 10/13/11.
//  Copyright 2011 MacRabbit. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OCAutopair : NSObject {
@protected
    NSString *character;
	NSString *balancedCharacter;
}

- (NSInteger)autopairMode;

@end

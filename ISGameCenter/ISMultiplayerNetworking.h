//
//  ISMultiplayerNetworking.h
//  butterfly
//
//  Created by Luis Flores on 3/26/14.
//  Copyright (c) 2014 Iguana Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISGameCenter.h"
#import "ISMultiplayerNetworking.h"

@protocol ISMultiplayerDelegate <NSObject>
@optional
- (void)multiplayerMatchStarted;
- (void)multiplayerMatchEnded;
- (void)playerIndex:(NSUInteger)index;
- (void)movePlayer:(CGFloat)dx dy:(CGFloat)dy;
@end

@interface ISMultiplayerNetworking : NSObject<ISGameCenterNetworkingDelegate>

@property (nonatomic, assign) id<ISMultiplayerDelegate> delegate;

- (void)sendMove:(float)dx dy:(float)dy;
- (void)sendGameOverMessage;
- (void)sendData:(NSData*)data;

@end

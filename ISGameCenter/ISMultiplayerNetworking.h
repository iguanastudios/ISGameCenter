//
//  ISMultiplayerNetworking.h
//  butterfly
//
//  Created by Luis Flores on 3/26/14.
//  Copyright (c) 2014 Iguana Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISGameCenter.h"

@protocol ISMultiplayerDelegate <NSObject>

@required
- (void)multiplayerMatchStarted:(BOOL)hoster;
- (void)multiplayerMatchEnded:(NSError *)error;

@end

@interface ISMultiplayerNetworking : NSObject<ISGameCenterNetworkingDelegate>

@property (weak, nonatomic) id<ISMultiplayerDelegate> delegate;

- (void)sendGameOverMessage;
- (void)sendReliableData:(NSData *)data;
- (void)sendUnreliableData:(NSData *)data;

@end

//
//  ISGameCenter.h
//  butterfly
//
//  Created by Luis Flores on 3/23/14.
//  Copyright (c) 2014 Iguana Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@import GameKit;

@protocol ISGameCenterDelegate <NSObject>
@required
- (void)presentAuthenticationViewController;
@end

@protocol ISGameCenterNetworkingDelegate <NSObject>
@optional
- (void)matchStarted;
- (void)matchEnded;
- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerId;
@end

@interface ISGameCenter : NSObject

@property (nonatomic,assign) id<ISGameCenterDelegate> delegate;
@property (nonatomic,assign) id<ISGameCenterNetworkingDelegate> networkingDelegate;
@property (nonatomic,strong) GKMatch *multiplayerMatch;
@property (nonatomic, readonly) UIViewController *authenticationViewController;

+ (instancetype)sharedISGameCenter;
- (void)authenticateLocalPlayer;
- (void)showGameCenterViewController:(UIViewController *)viewController;
- (void)reportAchievements:(NSArray *)achievements;
- (void)reportScore:(NSInteger)score leaderboardIdentifier:(NSString *)leaderboardIdentifier;
- (void)resetAchievements;
- (void)findMatchWithMinPlayers:(int)minPlayers
                     maxPlayers:(int)maxPlayers
       presentingViewController:(UIViewController *)viewController;

@end

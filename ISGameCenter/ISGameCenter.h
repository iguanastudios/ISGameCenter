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
@required
- (void)matchStarted;
- (void)matchEnded:(NSError *)error;
- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerId;
@end

@interface ISGameCenter : NSObject

@property (weak, nonatomic) id<ISGameCenterDelegate> delegate;
@property (weak, nonatomic) id<ISGameCenterNetworkingDelegate> networkingDelegate;
@property (strong, nonatomic) GKMatch *multiplayerMatch;
@property (readonly, nonatomic) UIViewController *authenticationViewController;

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

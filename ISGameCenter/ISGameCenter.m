//
//  ISGameCenter.m
//  butterfly
//
//  Created by Luis Flores on 3/23/14.
//  Copyright (c) 2014 Iguana Studios. All rights reserved.
//

#import "ISGameCenter.h"

@interface ISGameCenter()<GKGameCenterControllerDelegate, GKMatchmakerViewControllerDelegate, GKMatchDelegate>
@property (strong, nonatomic) UIViewController *presentingViewController;
@property (nonatomic) BOOL multiplayerMatchStarted;
@end

@implementation ISGameCenter

#pragma mark - Getters and setters

- (void)setAuthenticationViewController:(UIViewController *)authenticationViewController {
    if (authenticationViewController != nil) {
        _authenticationViewController = authenticationViewController;
        [self.delegate presentAuthenticationViewController];
    }
}

#pragma mark - Singleton

+ (instancetype)sharedISGameCenter {
    static ISGameCenter *sharedISGameCenter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedISGameCenter = [[ISGameCenter alloc] init];
    });
    return sharedISGameCenter;
}


#pragma mark - Public methods

- (void)authenticateLocalPlayer {
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }

        if(viewController != nil) {
            self.authenticationViewController = viewController;
        }
    };
}

- (void)showGameCenterViewController:(UIViewController *)viewController {
    GKGameCenterViewController *gameCenterViewController = [[GKGameCenterViewController alloc] init];
    gameCenterViewController.gameCenterDelegate = self;
    gameCenterViewController.viewState = GKGameCenterViewControllerStateDefault;
    [viewController presentViewController:gameCenterViewController animated:YES completion:nil];
}

- (void)reportAchievements:(NSMutableArray *)achievementsUser {
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievementsDone, NSError *error) {
        if(error) {
            NSLog(@"%@", error);
        }

        for (GKAchievement *achievementDone in achievementsDone) {
            for (GKAchievement *achievementUser in achievementsUser) {
                if([achievementDone.identifier isEqualToString:achievementUser.identifier]
                   && achievementDone.completed) {
                    [achievementsUser removeObject:achievementUser];
                    break;
                }
            }
        }

        [GKAchievement reportAchievements:achievementsUser withCompletionHandler:^(NSError *error ){
            if (error) {
                NSLog(@"Error %@", error);
            }
        }];
    }];
}

- (void)reportScore:(NSInteger)score leaderboardIdentifier:(NSString *)leaderboardIdentifier {
    GKScore *scoreReporter = [[GKScore alloc] initWithLeaderboardIdentifier:leaderboardIdentifier];
    scoreReporter.value = score;
    scoreReporter.context = 0;
    NSArray *scores = @[ scoreReporter ];

    [GKScore reportScores:scores withCompletionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Error, %@", error);
        }
    }];
}

- (void)resetAchievements {
    [GKAchievement resetAchievementsWithCompletionHandler: ^(NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }];
}

- (void)findMatchWithMinPlayers:(int)minPlayers
                     maxPlayers:(int)maxPlayers
       presentingViewController:(UIViewController*)viewController {
    self.multiplayerMatchStarted = NO;
    self.multiplayerMatch = nil;
    self.presentingViewController = viewController;

    GKMatchRequest *matchRequest = [[GKMatchRequest alloc] init];
    matchRequest.minPlayers = minPlayers;
    matchRequest.maxPlayers = maxPlayers;
    GKMatchmakerViewController *matchMakerViewController = [[GKMatchmakerViewController alloc]
                                                            initWithMatchRequest:matchRequest];
    matchMakerViewController.matchmakerDelegate = self;
    [self.presentingViewController presentViewController:matchMakerViewController
                                                animated:NO
                                              completion:nil];
}

#pragma mark - GKGameCenterControllerDelegate

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
    [gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - GKMatchmakerViewControllerDelegate

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [self.networkingDelegate matchEnded:nil];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController
                didFailWithError:(NSError *)error {
    NSLog(@"Error creating a match: %@", error.localizedDescription);
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [self.networkingDelegate matchEnded:error];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController
                    didFindMatch:(GKMatch *)match {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    self.multiplayerMatch = match;
    self.multiplayerMatch.delegate = self;

    if (!self.multiplayerMatchStarted && self.multiplayerMatch.expectedPlayerCount == 0) {
        [self.networkingDelegate matchStarted];
    }
}

#pragma mark - GKMatchDelegate

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {
    if (self.multiplayerMatch == match) {
        [self.networkingDelegate match:match didReceiveData:data fromPlayer:playerID];
    }
}

- (void)match:(GKMatch *)match didFailWithError:(NSError *)error {
    if (error) {
        self.multiplayerMatchStarted = NO;
        [self.networkingDelegate matchEnded:error];
    }
}

- (void)match:(GKMatch *)match player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state {
    if (self.multiplayerMatch != match) {
        return;
    }

    switch (state) {
        case GKPlayerStateConnected:
            NSLog(@"Player connected");
            if (!self.multiplayerMatchStarted && self.multiplayerMatch.expectedPlayerCount == 0) {
                [self.networkingDelegate matchStarted];
            }
            break;
        case GKPlayerStateDisconnected:
        default:
            NSLog(@"Player disconnected");
            self.multiplayerMatchStarted = NO;
            [self.networkingDelegate matchEnded:nil];
            break;
    }
}

@end

//
//  ISMultiplayerNetworking.m
//  butterfly
//
//  Created by Luis Flores on 3/26/14.
//  Copyright (c) 2014 Iguana Studios. All rights reserved.
//

#import "ISMultiplayerNetworking.h"

typedef NS_ENUM(int, ISMessageType) {
    ISMessageTypeGamePrepare,
    ISMessageTypeGameBegin,
    ISMessageTypeMove,
    ISMessageTypeGameOver
};

typedef struct {
    ISMessageType messageType;
} ISMessage;

typedef struct {
    ISMessage message;
} ISMessageGamePrepare;

typedef struct {
    ISMessage message;
} ISMessageGameBegin;

typedef struct {
    ISMessage message;
    float dx, dy;
} ISMessageMove;

typedef struct {
    ISMessage message;
} ISMessageGameOver;

@interface ISMultiplayerNetworking ()
@property (strong, nonatomic) NSMutableArray *players;
@end

@implementation ISMultiplayerNetworking;

#pragma mark - Initialization

- (id)init {
    if (self = [super init]) {
        self.players = [NSMutableArray array];
    }
    return self;
}

#pragma mark ISGameCenterNetworkingDelegate

- (void)matchStarted {
    NSLog(@"Multiplayer match has started successfully");
    [self sendPrepareGame];
}

- (void)matchEnded {
    NSLog(@"Multiplayer match has ended");
    [[ISGameCenter sharedISGameCenter].multiplayerMatch disconnect];
    if ([self.delegate respondsToSelector:@selector(multiplayerMatchEnded)]) {
        [self.delegate multiplayerMatchEnded];
    }
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerId {
    ISMessage *message = (ISMessage*)[data bytes];

    switch (message->messageType) {
        case ISMessageTypeGamePrepare:
            [self prepareGame:playerId];
            break;

        case ISMessageTypeGameBegin:
            if ([self.delegate respondsToSelector:@selector(multiplayerMatchStarted)]) {
                [self.delegate multiplayerMatchStarted];
            }
            break;

        case ISMessageTypeMove:
            [self move:data];
            break;

        case ISMessageTypeGameOver:
            [self matchEnded];
            break;

        default:
            break;
    }
}

#pragma mark - Send data

- (void)sendData:(NSData*)data {
    NSError *error;
    ISGameCenter *gameKitHelper = [ISGameCenter sharedISGameCenter];
    BOOL success = [gameKitHelper.multiplayerMatch sendDataToAllPlayers:data
                                                           withDataMode:GKMatchSendDataReliable
                                                                  error:&error];
    if (!success) {
        NSLog(@"Error sending data: %@", error);
        [self matchEnded];
    }
}

- (void)sendPrepareGame {
    ISMessageGameBegin message;
    message.message.messageType = ISMessageTypeGamePrepare;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(ISMessageGamePrepare)];
    [self sendData:data];
}

- (void)sendBeginGame {
    ISMessageGameBegin message;
    message.message.messageType = ISMessageTypeGameBegin;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(ISMessageGameBegin)];
    [self sendData:data];
}

- (void)sendMove:(float)dx dy:(float)dy {
    ISMessageMove messageMove;
    messageMove.dx = dx;
    messageMove.dy = dy;
    messageMove.message.messageType = ISMessageTypeMove;
    NSData *data = [NSData dataWithBytes:&messageMove length:sizeof(ISMessageMove)];
    [self sendData:data];
}

- (void)sendGameOverMessage {
    ISMessageGameOver gameOverMessage;
    gameOverMessage.message.messageType = ISMessageTypeGameOver;
    NSData *data = [NSData dataWithBytes:&gameOverMessage length:sizeof(ISMessageGameOver)];
    [self sendData:data];
}

#pragma mark - Private methods

- (void)prepareGame:(NSString *)playerId {
    [self.players addObject:playerId];

    GKMatch *multiplayerMatch = [ISGameCenter sharedISGameCenter].multiplayerMatch;
    if ([self.players count] == [multiplayerMatch.playerIDs count]) {
        NSString *localPlayerId = [GKLocalPlayer localPlayer].playerID;
        [self.players addObject:localPlayerId];

        [self.players sortUsingComparator:^NSComparisonResult(NSString *id1, NSString *id2) {
            return [id1 caseInsensitiveCompare:id2];
        }];

        NSUInteger index = [self.players indexOfObject:localPlayerId];
        if ([self.delegate respondsToSelector:@selector(playerIndex:)]) {
            [self.delegate playerIndex:index];
        }
    }
}

- (void)move:(NSData *)data {
    ISMessageMove *messageMove = (ISMessageMove*)[data bytes];
    if ([self.delegate respondsToSelector:@selector(movePlayer:dy:)]) {
        [self.delegate movePlayer:messageMove->dx dy:messageMove->dy];
    }
}

@end

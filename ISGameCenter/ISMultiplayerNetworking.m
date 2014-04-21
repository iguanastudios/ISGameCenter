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
    ISMessageTypeGameOver
};

typedef struct {
    ISMessageType messageType;
} ISMessage;

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

#pragma mark - Public methods

- (void)sendGameOverMessage {
    [self sendMessageType:ISMessageTypeGameOver];
}

- (void)sendReliableData:(NSData*)data {
    [self sendData:data withDataMode:GKMatchSendDataReliable];
}

- (void)sendUnreliableData:(NSData*)data {
    [self sendData:data withDataMode:GKMatchSendDataUnreliable];
}

- (void)sendData:(NSData *)data withDataMode:(GKMatchSendDataMode)mode {
    NSError *error;
    ISGameCenter *gameKitHelper = [ISGameCenter sharedISGameCenter];
    BOOL success = [gameKitHelper.multiplayerMatch sendDataToAllPlayers:data
                                                           withDataMode:mode
                                                                  error:&error];
    if (!success) {
        NSLog(@"Error sending data: %@", error);
        [self matchEnded:error];
    }
}

#pragma mark - Private methods

- (void)sendPrepareGame {
    [self sendMessageType:ISMessageTypeGamePrepare];
}

- (void)sendBeginGame {
    [self sendMessageType:ISMessageTypeGameBegin];
}

- (void)sendMessageType:(ISMessageType)messageType {
    ISMessage message;
    message.messageType = messageType;
    NSData *data = [NSData dataWithBytes:&message length:sizeof(ISMessage)];
    [self sendReliableData:data];
}

- (void)prepareGame:(NSString *)playerId {
    [self.players addObject:playerId];
    GKMatch *multiplayerMatch = [ISGameCenter sharedISGameCenter].multiplayerMatch;

    if ([self.players count] == [multiplayerMatch.playerIDs count]) {
        NSString *localPlayerId = [GKLocalPlayer localPlayer].playerID;
        [self.players addObject:localPlayerId];

        [self.players sortUsingComparator:^ NSComparisonResult(NSString *id1, NSString *id2) {
            return [id1 caseInsensitiveCompare:id2];
        }];

        // Local player is hoster
        if ([self.players indexOfObject:localPlayerId] == 0) {
            [self sendBeginGame];
            [self.delegate multiplayerMatchStarted:YES];
        }
    }
}

#pragma mark ISGameCenterNetworkingDelegate

- (void)matchStarted {
    [self sendPrepareGame];
}

- (void)matchEnded:(NSError *)error {
    [[ISGameCenter sharedISGameCenter].multiplayerMatch disconnect];
    [self.delegate multiplayerMatchEnded:error];
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerId {
    ISMessage *message = (ISMessage*)[data bytes];

    switch (message->messageType) {
        case ISMessageTypeGamePrepare:
            [self prepareGame:playerId];
            break;

        case ISMessageTypeGameBegin:
            [self.delegate multiplayerMatchStarted:NO];
            break;

        case ISMessageTypeGameOver:
        default:
            [self matchEnded:nil];
            break;
    }
}

@end

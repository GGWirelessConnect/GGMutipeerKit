//
//  GGMutipeer.m
//  GGMutipeer
//
//  Created by marsung on 2016/9/18.
//  Copyright © 2016 marsung. All rights reserved.
//

#import "GGMutipeer.h"
#import "GGMarcos.h"
#import "GGError.h"

@interface GGMultipeer ()<MCSessionDelegate,MCNearbyServiceBrowserDelegate,MCNearbyServiceAdvertiserDelegate,NSStreamDelegate>
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCPeerID *advertiserPeerID;
@property (nonatomic, strong) MCPeerID *browserPeerID;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSURL *destinationURL;
@property (nonatomic, assign) GGMutipeerDeviceMode startMode;
@property (nonatomic, strong) NSTimer *timeoutTimer;
@end

static NSString *const SERVICE_TYPE = @"rsp-receiver";
@implementation GGMultipeer
{
    void(^ConnectHandle)(MCPeerID *peer,MCSessionState state,NSString *log);
    void(^MessageHandle)(NSString *message,MCPeerID *fromPeer);
    
    void(^StreamProgressHandle)(NSData *data);
    void(^StreamCompleteHandle)(BOOL success,NSError *error);
    
    void(^ResourceProgressHandle)(NSString *resourceName,MCPeerID *peer,NSProgress *progress);
    void(^ResourceCompleteHandle)(BOOL success,NSString *resourceName,MCPeerID *peer,NSURL *localURL,NSError *error);
    
    BOOL hasRecievedForOnceMessage;
    BOOL timeoutForOnceMessage;
    BOOL recievedMessage;
    BOOL messageTimeout;
}


/****************************** Function syntactic sugar ******************************/

/**
<#session start#>

@discuss parameters->
mode:  <#BrowerMode or AdvertiserMode#>;
displayName:  <#set devcie name. such as "server-A" or "client-B"#>;
@return callback for block : <#[peer,state(MCSessionState) , log(string)]#>.
*/
- (GGMultipeer *(^)(GGMutipeerDeviceMode mode,NSString *displayName,void(^)(MCPeerID *peer, MCSessionState state,NSString *log)))start {
    return ^ GGMultipeer*(GGMutipeerDeviceMode mode,NSString *displayName,void(^connectBlock)(MCPeerID *peer, MCSessionState state,NSString *log)) {
        self.startMode = mode;
        if (mode == BrowerMode) {
            [self startBrowsingNearbyPeersToSessionWithDisplayName:displayName];
        }else {
            [self startAdvertisingWithDisplayName:displayName];
        }
        
        [self setConnectStateNotification:^(MCPeerID * _Nonnull peer, MCSessionState state, NSString * _Nonnull log) {
            connectBlock(peer,state,log);
        }];
        return self;
    };
}
/**
session stop
*/
- (GGMultipeer *(^)(void))stop {
    return ^(void) {
        if (self.startMode == BrowerMode) {
            [self stopBrowsing];
        }else {
            [self stopAdvertising];
        }
        return self;
    };
}
/**
session restart
*/
- (GGMultipeer *(^)(void))restart {
    return ^(void) {
        if (self.startMode == BrowerMode) {
            [self reBrowing];
        }else {
            [self reAdvertising];
        }
        return self;
    };
}


/**
<#message#>

@discuss parameters->
sendMessage:  <#message for string#>;
timeout:  <#timeout for secs#>.
@return callback for block :<#[resopndMessage, error]#>.
*/
- (GGMultipeer *(^)(NSString *sendMessage,NSTimeInterval timeout,void(^)(NSString *respondMessage,NSError *err)))message {
    return ^GGMultipeer *(NSString *sendMessage,NSTimeInterval timeout,void(^respondBlock)(NSString *respondMessage,NSError *err)) {
       @GGWeakObjc(self);
        dispatch_block_t timeoutBlock = ^{
            @GGStrongObjc(self);
            self->messageTimeout = YES;
            
            if (!self->recievedMessage) {
                GGError *error = [[GGError alloc] initWithMultipeerErrorCode:GGMultipeerErrorCode_timeoutForAutoExcute userInfo:@{
                    GGErroUserInfoDescriptionKey:@"GGMultipeerErrorCode_timeoutForAutoExcute",
                    GGErroUserInfoReasonKey:@"time out!",
                    GGErroUserInfoSuggestionKey:@""
                }];
                respondBlock(nil,error);
            }
        };
        NSArray *arg = @[@(timeout),timeoutBlock];
        [self performSelector:@selector(__timeoutWithArg:) onThread:[NSThread currentThread] withObject:arg waitUntilDone:NO];
        
        [self sendMessage:sendMessage];
        
        [self setReceivedMessageNotification:^(id  _Nonnull message, MCPeerID * _Nonnull fromPeer) {
            @GGStrongObjc(self);
            if (!self->messageTimeout) {
                self->recievedMessage = YES;
                respondBlock(message,nil);
            }
        }];
        return self;
    };
}

/**
<#Auto message for once#>
One-click single-time sending of string information, no need to wait for connection. Automatically connect, send and receive.

@discuss parameters->
 mode:  <#BrowerMode or AdvertiserMode#>;
 displayName:  <#set devcie name. such as "server-A" or "client-B"#>;
 sendMessage:  <#message for string#>;
 timeout:  <#timeout for secs#>.
@return callback for block :<#[resopndMessage, error]#>.
*/
- (GGMultipeer *(^)(GGMutipeerDeviceMode mode,NSString *displayName,NSString *sendMessage,NSTimeInterval timeout,void(^)(NSString *respondMessage,NSError *err)))onceMessageForAutomator {
    return ^GGMultipeer *(GGMutipeerDeviceMode mode,NSString *displayName,NSString *sendMessage,NSTimeInterval timeout,void(^respondBlock)(NSString *respondMessage,NSError *err)){
        @GGWeakObjc(self);
        dispatch_block_t timeoutBlock = ^{
            @GGStrongObjc(self);
            self->timeoutForOnceMessage = YES;
            
            if (!self->hasRecievedForOnceMessage) {
                GGError *error = [[GGError alloc] initWithMultipeerErrorCode:GGMultipeerErrorCode_timeoutForAutoExcute userInfo:@{
                    GGErroUserInfoDescriptionKey:@"GGMultipeerErrorCode_timeoutForAutoExcute",
                    GGErroUserInfoReasonKey:@"time out!",
                    GGErroUserInfoSuggestionKey:@""
                }];
                respondBlock(nil,error);
            }
        };
        NSArray *arg = @[@(timeout),timeoutBlock];
        
        [self performSelector:@selector(__timeoutWithArg:) onThread:[NSThread currentThread] withObject:arg waitUntilDone:NO];
        
        if (mode == BrowerMode) {
            [self startBrowsingNearbyPeersToSessionWithDisplayName:displayName];
        }else {
            [self startAdvertisingWithDisplayName:displayName];
        }
        
        [self setConnectStateNotification:^(MCPeerID * _Nonnull peer, MCSessionState state, NSString * _Nonnull log) {
            @GGStrongObjc(self);
            if (!self->timeoutForOnceMessage) {
                if (sendMessage) {
                    [self sendMessage:sendMessage];
                }
            }
        }];
        
        [self setReceivedMessageNotification:^(id  _Nonnull message, MCPeerID * _Nonnull fromPeer) {
            @GGStrongObjc(self);
            if (!self->timeoutForOnceMessage) {
                self->hasRecievedForOnceMessage = YES;
                respondBlock(message,nil);
            }
        }];
        return self;
    };
}

/**
<#stream#>

@discuss parameters->
name:  <#message for string#>;
fromPeer: <#fromPeer#>;
timeout:  <#timeout for secs#>;
@return callback for block :<#progress block#>: -> progress data; <#complete block#>: -> success or not, and error info.
*/
- (GGMultipeer *(^)(NSString *name,MCPeerID *fromPeer,NSTimeInterval timeout,void(^)(NSData *data),void(^)(BOOL success, NSError *error)))stream {
    return ^GGMultipeer *(NSString *name,MCPeerID *fromPeer,NSTimeInterval timeout,void(^progress)(NSData *data),void(^complete)(BOOL success, NSError *error)) {
        [self startStreamWithName:name toPeer:fromPeer];
                
        [self setReadStreamNoficationWithProgress:^(NSData * _Nonnull data) {
            progress(data);
        } complete:^(BOOL success, NSError * _Nonnull error) {
            complete(success,error);
        }];
        return self;
    };
}
/**
wirte data to stream
*/
- (GGMultipeer *(^)(NSData *data))writeData {
    return ^GGMultipeer *(NSData *data) {
        [self writeStreamWithData:data];
        return self;
    };
}

/**
<#resource#>

@discuss parameters->
localURL:  <#localURL#> ;
destinationURL: <#destinationURL#>;
toPeer:  <#toPeer#>;
@return callback for block :<#progress block#> : -> [resourceName,peer,progress]; <#complete block#>: -> [success, resourceName,localURL,error].
*/
- (GGMultipeer *(^)(NSURL *localURL,NSURL *destinationURL,MCPeerID *toPeer,void(^)(NSString *resourceName,MCPeerID *peer,NSProgress *progress),void(^)(BOOL success,NSString *resourceName,MCPeerID *peer,NSURL *localURL,NSError *error)))resource {
    return ^GGMultipeer *(NSURL *localURL,NSURL *destinationURL,MCPeerID *toPeer,void(^progressHandle)(NSString *resourceName,MCPeerID *peer,NSProgress *progress),void(^completeHandle)(BOOL success,NSString *resourceName,MCPeerID *peer,NSURL *localURL,NSError *error)) {
        
        [self sendResourceFromlocalURL:localURL destinationURL:destinationURL toPeer:toPeer complete:^(NSError * _Nonnull error) {
            if (error) {
                completeHandle(NO,[localURL lastPathComponent],toPeer,localURL,error);
            }
        }];
        
        [self setResourceNotificationWithProgress:^(NSString * _Nonnull resourceName, MCPeerID * _Nonnull peer, NSProgress * _Nonnull progress) {
            progressHandle(resourceName,peer,progress);
        } complete:^(BOOL success, NSString * _Nonnull resourceName, MCPeerID * _Nonnull peer, NSURL * _Nonnull localURL, NSError * _Nonnull error) {
            completeHandle(success,resourceName,peer,localURL,error);
        }];
        
        return self;
    };
}


/****************************** Traditional  use for block ******************************/

/**
Browsing start

@param displayName <#displayName description#>
*/
- (void)startBrowsingNearbyPeersToSessionWithDisplayName:(NSString *)displayName {
    [self stopBrowsing];
    self.browserPeerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    self.session = [[MCSession alloc] initWithPeer:self.browserPeerID];
    self.session.delegate = self;
    
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.browserPeerID serviceType:SERVICE_TYPE];
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];
}
/**
Browsing again
 */
- (void)reBrowing {
    if (_browser) {
        [self.browser startBrowsingForPeers];
    }
}
/**
Browsing stop
*/
- (void)stopBrowsing {
    [self.browser stopBrowsingForPeers];
    [self.session disconnect];
}

/**
Advertising start
@param displayName <#displayName description#>
*/
- (void)startAdvertisingWithDisplayName:(NSString *)displayName {
    [self stopAdvertising];
    self.advertiserPeerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    self.session = [[MCSession alloc] initWithPeer:self.advertiserPeerID];
    self.session.delegate = self;
    
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.advertiserPeerID discoveryInfo:nil serviceType:SERVICE_TYPE];
    self.advertiser.delegate = self;
    [self.advertiser startAdvertisingPeer];
}
/**
Advertising again
*/
- (void)reAdvertising {
    if (self.advertiser) {
        [self.advertiser startAdvertisingPeer];
    }
}
/**
Advertising stop
*/
- (void)stopAdvertising {
    [self.advertiser stopAdvertisingPeer];
    [self.session disconnect];
}


#pragma mark- message
- (void)sendMessage:(NSString *)message
{
    if (message == nil) {
        return;
    }
    if (self.session.connectedPeers.count > 0) {
        NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        BOOL queued = [self.session sendData:messageData
                                            toPeers:self.session.connectedPeers
                                           withMode:MCSessionSendDataReliable
                                              error:&error];
        
        if (!queued) {
            GGLog(@"Error enqueuing the message! %@", error);
        }
    }
}

#pragma mark- stream
- (void)startStreamWithName:(NSString *)name toPeer:(MCPeerID *)peer
{
    NSError *error;
    self.outputStream = [self.session startStreamWithName:name toPeer:peer error:&error];
}

- (void)writeStreamWithData:(NSData *)data {
    if ([self.outputStream hasSpaceAvailable]) {
        [self.outputStream write:data.bytes maxLength:data.length];
    }
}

#pragma mark- resource

- (void)sendResourceFromlocalURL:(NSURL *)fileURL destinationURL:(NSURL *)destinationURL toPeer:(MCPeerID *)peer complete:(void(^)(NSError *error))complete {
    self.destinationURL = destinationURL;
    [self.session sendResourceAtURL:fileURL withName:[fileURL lastPathComponent] toPeer:peer withCompletionHandler:^(NSError * _Nullable error) {
        complete(error);
    }];
}


#pragma mark- Notification
- (void)setConnectStateNotification:(void(^)(MCPeerID *peer, MCSessionState state,NSString *log))complete {
    if (complete) {
        ConnectHandle = complete;
    }
}

- (void)setReceivedMessageNotification:(void(^)(id message,MCPeerID *fromPeer))complete {
    if (complete) {
        MessageHandle = complete;
    }
}


- (void)setReadStreamNoficationWithProgress:(void(^)(NSData *data))progress complete:(void(^)(BOOL success, NSError *error))complete {
    if (progress) {
        StreamProgressHandle = progress;
    }
    if (complete) {
        StreamCompleteHandle = complete;
    }
}

- (void)setResourceNotificationWithProgress:(void(^)(NSString *resourceName,MCPeerID *peer,NSProgress *progress))progress complete:(void(^)(BOOL success,NSString *resourceName,MCPeerID *peer,NSURL *localURL,NSError *error))complete {
    if (progress) {
        ResourceProgressHandle = progress;
    }
    if (complete) {
        ResourceCompleteHandle = complete;
    }
}

- (void)__timeoutWithArg:(NSArray *)arg {
    NSTimeInterval secs = ((NSNumber*)arg[0]).doubleValue;
    dispatch_block_t block = arg.lastObject;
    
    if (GGAPIAavaliable(10, 10.12)) {
        self.timeoutTimer = [NSTimer timerWithTimeInterval:0 repeats:NO block:^(NSTimer * _Nonnull timer) {
            block();
            [timer invalidate];
            timer = nil;
            CFRunLoopStop(CFRunLoopGetCurrent());
        }];
    }else {
        self.timeoutTimer = [NSTimer timerWithTimeInterval:0 target:self selector:@selector(__timeout:) userInfo:block repeats:NO];
    }
    
    [_timeoutTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:secs]];
    [[NSRunLoop currentRunLoop] addTimer:_timeoutTimer forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop] run];
}

- (void)__timeout:(dispatch_block_t)block {
    block();
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
    CFRunLoopStop(CFRunLoopGetCurrent());
}


#pragma mark - MCSessionDelegate

// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    GGLog(@"Peer did change state: %li", state);
    NSString *device = [NSString stringWithFormat:@"Server-%@ ",peerID.displayName];
    NSString *stateMessage = @"Disconnect";
    BOOL hasConnected = NO;
    switch (state) {
        case MCSessionStateConnected: {
            stateMessage = @"Connected";
            hasConnected = YES;
        }
            break;
        case MCSessionStateConnecting: {
            stateMessage = @"Connecting";
            hasConnected = NO;
        }
            break;
        case MCSessionStateNotConnected: {
            stateMessage = @"Fail connection";
            hasConnected = NO;
        }break;
    }
    
    ConnectHandle(peerID,state,[NSString stringWithFormat:@"%@ %@",device,stateMessage]);
    NSString *message = [NSString stringWithFormat:@"Client：%@ %@...", device, stateMessage];
    GGLog(@"%@",message);
}

// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    if (MessageHandle) {
        NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        MessageHandle(msg,peerID);
        GGLog(@"Received Message... :%@",msg);
    }
}

// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    stream.delegate = self;
    [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [stream open];
}

// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    GGLog(@"downloading file: %f%%", progress.fractionCompleted);
    if (ResourceProgressHandle) {
        ResourceProgressHandle(resourceName,peerID,progress);
    }
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    GGLog(@"finished receiving file...");
    if (![[NSFileManager defaultManager] moveItemAtURL:localURL toURL:self.destinationURL error:&error]) {
        GGLog(@"Error when receiving file :%@",error);
    }
    if (ResourceCompleteHandle) {
        ResourceCompleteHandle(error == nil? YES:NO,resourceName,peerID,localURL,error);
    }
}

#pragma mark- MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info
{
    NSString *msg = [NSString stringWithFormat:@"found a peer： %@",peerID.displayName];
    GGLog(@"%@",msg);
    [browser stopBrowsingForPeers];
    [self.browser invitePeer:peerID toSession:self.session withContext:nil timeout:30];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    [browser startBrowsingForPeers];
    GGLog(@"%@ lost Peer",peerID.displayName);
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    [browser stopBrowsingForPeers];
    GGLog(@"browser error:%@",error);
}


#pragma mark- MCNearbyServiceAdvertiserDelegate
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    NSString *message = [NSString stringWithFormat:@"Received invitation from %@. Joining...", peerID.displayName];
    GGLog(@"%@",message);
    invitationHandler(YES, self.session);
    [self.advertiser stopAdvertisingPeer];
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    GGLog(@"unable to advertise! %@", error);
}

#pragma mark-
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:{
            uint8_t buff[1024];
            NSInputStream *inputStream = (NSInputStream *)aStream;
            NSUInteger length = [inputStream read:buff maxLength:sizeof(buff)];
            NSData *data = [NSData dataWithBytes:(void *)buff length:length];
            StreamProgressHandle(data);
        }break;
        case NSStreamEventEndEncountered: {
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            StreamCompleteHandle(YES,nil);
        }
        case NSStreamEventErrorOccurred:
        {
            GGError *error = [[GGError alloc] initWithMultipeerErrorCode:GGMultipeerErrorCode_StreamEventErrorOccurred userInfo:@{
                GGErroUserInfoDescriptionKey:@"NSStreamEventErrorOccurred",
                GGErroUserInfoReasonKey:@"NSStreamEvent error",
                GGErroUserInfoSuggestionKey:@"please check the method `stream:handleEvent:`",
            }];
            StreamCompleteHandle(NO,error);
        }
        default:
            break;
    }
}
@end

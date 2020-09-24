//
/**
 *
 *     _ __ __ __        _ __ __ __
 *    / __ __ __ |     /  __ __ __ |
 *   / /              / /
 *  | |     __ __    | |      _ _ _
 *  | |    |_ __ |   | |     |_ _  |
 *   \ \ __ __ | |    \ \ __ __ _| |
 *    \ __ __ __ |     \ __ __ __ _|
 *
 *
 *  This code is distributed under the terms and conditions of the MIT license.
 *
 *  Created by GG on 2016/9/18.
 *  Copyright © 2016-2020 GG. All rights reserved.
 *
 *  Organization: GGWirlessConnect (https://github.com/GGWirelessConnect)
 *  Github Pages: https://github.com/GGWirelessConnect/GGMutipeerKit
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
*/

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,GGMutipeerDeviceMode) {
    BrowerMode = 0,
    AdvertiserMode
};

@interface GGMultipeer : NSObject

/****************************** Function syntactic sugar ******************************/

/**
 <#session start#>
 
 @discuss parameters->
 mode:  <#BrowerMode or AdvertiserMode#>;
 displayName:  <#set devcie name. such as "server-A" or "client-B"#>;
 @return callback for block : <#[peer,state(MCSessionState) , log(string)]#>.
 */
- (GGMultipeer *(^)(GGMutipeerDeviceMode mode,NSString *displayName,void(^)(MCPeerID *peer, MCSessionState state,NSString *log)))start;
/**
 session stop
 */
- (GGMultipeer *(^)(void))stop;
/**
 session restart
 */
- (GGMultipeer *(^)(void))restart;

/**
 <#message#>
 
 @discuss parameters->
 sendMessage:  <#message for string#>;
 timeout:  <#timeout for secs#>.
 @return callback for block :<#[resopndMessage, error]#>.
 */
- (GGMultipeer *(^)(NSString *sendMessage,NSTimeInterval timeout,void(^)(NSString *respondMessage,NSError *err)))message;
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
- (GGMultipeer *(^)(GGMutipeerDeviceMode mode,NSString *displayName,NSString *sendMessage,NSTimeInterval timeout,void(^)(NSString *respondMessage,NSError *err)))onceMessageForAutomator;

/**
 <#stream#>
 
 @discuss parameters->
 name:  <#message for string#>;
 fromPeer: <#fromPeer#>;
 timeout:  <#timeout for secs#>;
 @return callback for block :<#progress block#>: -> progress data; <#complete block#>: -> success or not, and error info.
 */
- (GGMultipeer *(^)(NSString *name,MCPeerID *fromPeer,NSTimeInterval timeout,void(^)(NSData *data),void(^)(BOOL success, NSError *error)))stream;

/**
 wirte data to stream
 */
- (GGMultipeer *(^)(NSData *data))writeData;

/**
<#resource#>

@discuss parameters->
localURL:  <#localURL#> ;
destinationURL: <#destinationURL#>;
toPeer:  <#toPeer#>;
@return callback for block :<#progress block#> : -> [resourceName,peer,progress]; <#complete block#>: -> [success, resourceName,localURL,error].
*/
- (GGMultipeer *(^)(NSURL *localURL,NSURL *destinationURL,MCPeerID *toPeer,void(^)(NSString *resourceName,MCPeerID *peer,NSProgress *progress),void(^)(BOOL success,NSString *resourceName,MCPeerID *peer,NSURL *localURL,NSError *error)))resource;


/****************************** Traditional  use for block ******************************/
#pragma mark- Brower
/**
 Browsing start
 
 @param displayName <#displayName description#>
 */
- (void)startBrowsingNearbyPeersToSessionWithDisplayName:(NSString *)displayName;
/**
Browsing again
 */
- (void)reBrowing;
/**
 Browsing stop
 */
- (void)stopBrowsing;

#pragma mark- Advertiser
/**
 Advertising start
 @param displayName <#displayName description#>
 */
- (void)startAdvertisingWithDisplayName:(NSString *)displayName;
/**
Advertising again
*/
- (void)reAdvertising;
/**
 Advertising stop
 */
- (void)stopAdvertising;

/// Connect state nofication
/// @param complete <#complete description#>
- (void)setConnectStateNotification:(void(^)(MCPeerID *peer, MCSessionState state,NSString *log))complete;

#pragma mark- Message
/**
 send message
 @param message <#message description#>
 */
- (void)sendMessage:(NSString *)message;
/**
 notification for recieved message
 @param complete <#complete description#>
 */
- (void)setReceivedMessageNotification:(void(^)(id message,MCPeerID *fromPeer))complete;

#pragma mark- Stream
/**
 stream start
 
 @param name A name for the stream. This name is provided to the nearby peer.
 @param peer The ID of the nearby peer.
 */
- (void)startStreamWithName:(NSString *)name toPeer:(MCPeerID *)peer;
/**
 write data to stream
 @param data data
 */
- (void)writeStreamWithData:(NSData *)data;

/**
 notification for stream
 @param progress progress block
 @param complete complete block
 */
- (void)setReadStreamNoficationWithProgress:(void(^)(NSData *data))progress complete:(void(^)(BOOL success, NSError *error))complete;

#pragma mark- Resource
/**
 resource start
 
 @param fileURL <#fileURL description#>
 @param destinationURL <#destinationURL description#>
 @param peer <#peer description#>
 @param complete <#complete description#>
 */
- (void)sendResourceFromlocalURL:(NSURL *)fileURL destinationURL:(NSURL *)destinationURL toPeer:(MCPeerID *)peer complete:(void(^)(NSError *error))complete;

/**
 notification for resource with progress and complete
 @param progress <#progress description#>
 @param complete <#complete description#>
 */
- (void)setResourceNotificationWithProgress:(void(^)(NSString *resourceName,MCPeerID *peer,NSProgress *progress))progress complete:(void(^)(BOOL success,NSString *resourceName,MCPeerID *peer,NSURL *localURL,NSError *error))complete;
@end

NS_ASSUME_NONNULL_END

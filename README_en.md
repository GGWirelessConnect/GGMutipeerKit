![logo](https://raw.githubusercontent.com/itmarsung/resource_images/master/framework/icon_mutipeer.png)
# GGMutipeerKit  【[Chinese](https://github.com/itmarsung/GGMutipeerKit) | [English](https://github.com/itmarsung/GGMutipeerKit/blob/master/README_en.md)】

#### GGMutipeerKit is a small framework based on the <MultipeerConnectivity> package. Support functional syntactic sugar to make your code more concise.

## 1.Install
 
 1）CocoaPods support
 	
 	pod 'GGMutipeerKit', '~> 0.0.1'
 
 2）Carthage support
 
 coming soon
 
 3) Manual installation
 You can also download the [framework](https://github.com/itmarsung/GGMutipeerKit/tree/master/GGMutipeerKit)  and import it directly into the project.


## 2.How to use？

### 1.Traditional

1）Init

    GGMultipeer *session = [[GGMultipeer alloc] init];
 
2）Brower mode
    
    [session startBrowsingNearbyPeersToSessionWithDisplayName:@"server"];

    @GGWeakObjc(session);
    [session setConnectStateNotification:^(MCPeerID * _Nonnull peer, MCSessionState state, NSString * _Nonnull log) {
        @GGStrongObjc(session);
        if (state == MCSessionStateConnected) {
            [session sendMessage:@"hello"];
        }
    }];
    
    [session setReceivedMessageNotification:^(id  _Nonnull message, MCPeerID * _Nonnull fromPeer) {
        NSLog(@"server recieved message: %@",message);
    }];
   
   
3）Advertiser mode
    
    [session startBrowsingNearbyPeersToSessionWithDisplayName:@"client"];

    [session setConnectStateNotification:^(MCPeerID * _Nonnull peer, MCSessionState state, NSString * _Nonnull log) {
        @GGStrongObjc(session);
        if (state == MCSessionStateConnected) {
            [session sendMessage:@"hello"];
        }
    }];
    
    [session setReceivedMessageNotification:^(id  _Nonnull message, MCPeerID * _Nonnull fromPeer) {
        NSLog(@"client recieved message: %@",message);
    }];
 

### 2.Functional syntactic sugar

1）Init

    GGMultipeer *session = [[GGMultipeer alloc] init];

2）Brower mode

    session.start(BrowerMode,@"server",^(MCPeerID *peer, MCSessionState state,NSString *log) {
        if (state == MCSessionStateConnected) {
            session.message(@"hello",30,^(NSString *respondMessage,NSError *err) {
                NSLog(@"server recieved message: %@ err:%@",respondMessage,err);
            });
        }
    });

3）Advertiser mode

    session.start(AdvertiserMode,@"client",^(MCPeerID *peer, MCSessionState state,NSString *log) {
        if (state == MCSessionStateConnected) {
            session.message(@"world",30,^(NSString *respondMessage,NSError *err) {
                NSLog(@"client recieved message: %@ err:%@",respondMessage,err);
            });
        }
    });


#### Fast message way:

Provide one-click message transmission function without waiting for a handshake. (Note: Only one time transmission is supported)

1）Init

    GGMultipeer *session = [[GGMultipeer alloc] init];
  
2）Brower mode
 
    session.onceMessageForAutomator(BrowerMode,@"server",@"hello",30,^(NSString *respondMsg,NSError *err){
                   NSLog(@"server recieved message: %@ err:%@",respondMsg,err);
    });

3）Advertiser mode

    session.onceMessageForAutomator(AdvertiserMode,@"client",@"world",30,^(NSString *respondMsg,NSError *err){
               NSLog(@"client recieved message: %@ err:%@",respondMsg,err);
    });



tips:[Here](https://github.com/itmarsung/GGMutipeerKit/tree/master/GGSnippets) are Snippets, you can download and import it into your project.

## License

GGMutipeerKit is released under the MIT license. See [LICENSE](https://github.com/itmarsung/GGMutipeerKit/blob/master/LICENSE) for details.

## Issues and Star

If you find bugs, please [issus](https://github.com/itmarsung/GGMutipeerKit/issues), thank you!

Expectation of your Star ⭐⭐⭐【Star】【Star】【Star】



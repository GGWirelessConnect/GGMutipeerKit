![logo](https://raw.githubusercontent.com/itmarsung/resource_images/master/framework/icon_mutipeer.png)
# GGMutipeerKit  【[Chinese](https://github.com/itmarsung/GGMutipeerKit) | [English](https://github.com/itmarsung/GGMutipeerKit/blob/master/README_en.md) 】

#### GGMutipeerKit是基于<MultipeerConnectivity>封装的小框架。支持函数式语法糖，让你的代码更简练。

## 1.安装
 
 1）CocoaPods支持
 	
 	pod 'GGMutipeerKit', '~> 0.0.1'
 
 2）Carthage支持
 coming soon
 
 
 当然你也可以下载[framework](https://github.com/itmarsung/GGMutipeerKit/tree/master/GGMutipeerKit)文件直接导入的项目中。


## 2.怎样使用？

### 1.传统方式

1）初始化

    GGMultipeer *session = [[GGMultipeer alloc] init];
 
2）Brower模式
    
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
   
   
3）advertiser 模式
    
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
 

### 2.函数式语法糖

1）初始化

    GGMultipeer *session = [[GGMultipeer alloc] init];

2）Brower模式

    session.start(BrowerMode,@"server",^(MCPeerID *peer, MCSessionState state,NSString *log) {
        if (state == MCSessionStateConnected) {
            session.message(@"hello",30,^(NSString *respondMessage,NSError *err) {
                NSLog(@"server recieved message: %@ err:%@",respondMessage,err);
            });
        }
    });

3）advertiser 模式

    session.start(AdvertiserMode,@"client",^(MCPeerID *peer, MCSessionState state,NSString *log) {
        if (state == MCSessionStateConnected) {
            session.message(@"world",30,^(NSString *respondMessage,NSError *err) {
                NSLog(@"client recieved message: %@ err:%@",respondMessage,err);
            });
        }
    });


快速message模式:提供一键式messaage传输功能，无需等待握手。（注：仅支持一次数据传输）

1）初始化

    GGMultipeer *session = [[GGMultipeer alloc] init];
  
2）Brower模式
 
    session.onceMessageForAutomator(BrowerMode,@"server",@"hello",30,^(NSString *respondMsg,NSError *err){
                   NSLog(@"server recieved message: %@ err:%@",respondMsg,err);
    });

3）advertiser 模式

    session.onceMessageForAutomator(AdvertiserMode,@"client",@"world",30,^(NSString *respondMsg,NSError *err){
               NSLog(@"client recieved message: %@ err:%@",respondMsg,err);
    });



tips:由于ObjC的函数式语法糖实际上采用block调用方式实现，实质上并不是方法调用。书写时Xcode不会有提示。这里我采用了Snippets方式，[这里](https://github.com/itmarsung/GGMutipeerKit/tree/master/GGSnippets)是下载链接,导入到你的Xcode就可以享用了。


## License

GGMutipeerKit 支持[MIT](https://github.com/itmarsung/GGMutipeerKit/blob/master/LICENSE)开源协议.

## issues and star

在使用过程中，若有问题，欢迎[issus](https://github.com/itmarsung/GGMutipeerKit/issues)

当然也期待你给我个小 ⭐⭐⭐【Star】【Star】【Star】



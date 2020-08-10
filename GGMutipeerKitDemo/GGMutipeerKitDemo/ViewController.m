//
//  ViewController.m
//  GGMutipeerKitDemo
//
//  Created by marsung on 2020/8/10.
//  Copyright © 2020 marsung. All rights reserved.
//

#import "ViewController.h"
#import "GGMutipeerKit.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
#if 1
        
        // example 1
        
        GGMultipeer *session = [[GGMultipeer alloc] init];
        // brower
        session.start(BrowerMode,@"server",^(MCPeerID *peer, MCSessionState state,NSString *log) {
            if (state == MCSessionStateConnected) {
                session.message(@"hello",30,^(NSString *respondMessage,NSError *err) {
                    NSLog(@"server recieved message: %@ err:%@",respondMessage,err);
                });
            }
        });

        // advertiser
        session.start(AdvertiserMode,@"client",^(MCPeerID *peer, MCSessionState state,NSString *log) {
            if (state == MCSessionStateConnected) {
                session.message(@"world",30,^(NSString *respondMessage,NSError *err) {
                    NSLog(@"client recieved message: %@ err:%@",respondMessage,err);
                });
            }
        });
        
#elif 0
        
        // example 2
        
        GGMultipeer *session = [[GGMultipeer alloc] init];
        // brower
        session.onceMessageForAutomator(BrowerMode,@"server",@"hello",30,^(NSString *respondMsg,NSError *err){
                       NSLog(@"server recieved message: %@ err:%@",respondMsg,err);
        });

        // advertiser
        session.onceMessageForAutomator(AdvertiserMode,@"client",@"world",30,^(NSString *respondMsg,NSError *err){
                   NSLog(@"client recieved message: %@ err:%@",respondMsg,err);
        });
        
#elif 0
        
        // example 3
        GGMultipeer *session = [[GGMultipeer alloc] init];
        // brower
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
       
        // advertiser
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
        
#else
        
        
        
        
        
        // stream
        GGMultipeer *session = [[GGMultipeer alloc] init];

        NSMutableData *recievedData = [[NSMutableData alloc] init];
        // brower
        session.start(BrowerMode,@"server",^(MCPeerID *peer, MCSessionState state,NSString *log) {
            if (state == MCSessionStateConnected) {
                session.stream(@"server-stream",peer,120,^(NSData *data){
                    [recievedData appendData:data];
                },^(BOOL success, NSError *error){
                    NSLog(@"state:%@ err:%@",success ? @"success":@"fail",error);
                });
            }
        });
        
        
        NSData *data = [@"hello----world" dataUsingEncoding:NSUTF8StringEncoding];
        session.writeData(data);

        // advertiser
        session.start(BrowerMode,@"client",^(MCPeerID *peer, MCSessionState state,NSString *log) {
            if (state == MCSessionStateConnected) {
                session.stream(@"client-stream",peer,120,^(NSData *data){
                    [recievedData appendData:data];
                },^(BOOL success, NSError *error){
                    NSLog(@"state:%@ err:%@",success ? @"success":@"fail",error);
                });
            }
        });
    
#endif
}


@end

//
//  GGError.h
//  GGMultipeer
//
//  Created by marsung on 18/6/13.
//  Copyright © 2018 com.marsung. All rights reserved.ed.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, GGMultipeerErrorCode) {
    GGMultipeerErrorCode_Unkown = 0,
    GGMultipeerErrorCode_timeoutForAutoExcute,
    GGMultipeerErrorCode_StreamEventErrorOccurred,
};

typedef NSString *GGErroUserInfoKey;
extern GGErroUserInfoKey const GGErroUserInfoDescriptionKey;
extern GGErroUserInfoKey const GGErroUserInfoReasonKey;
extern GGErroUserInfoKey const GGErroUserInfoSuggestionKey;

@interface GGError : NSError
- (instancetype)initWithMultipeerErrorCode:(GGMultipeerErrorCode)code userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)dict;
@end

NS_ASSUME_NONNULL_END

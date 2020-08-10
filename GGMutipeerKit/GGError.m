//
//  GGBLEError.m
//  GGMultipeer
//
//  Created by marsung on 18/6/13.
//  Copyright © 2018 com.marsung. All rights reserved.
//

#import "GGError.h"


NSString *const GGErrorDomain = @"com.marsung.GGMultipeer.erroDomain";

GGErroUserInfoKey const GGErroUserInfoDescriptionKey = @"GGErroUserInfoDescriptionKey";
GGErroUserInfoKey const GGErroUserInfoReasonKey = @"GGErroUserInfoReasonKey";
GGErroUserInfoKey const GGErroUserInfoSuggestionKey = @"GGErroUserInfoSuggestionKey";

@interface GGError ()

@end

@implementation GGError

- (instancetype)initWithMultipeerErrorCode:(GGMultipeerErrorCode)code userInfo:(NSDictionary<GGErroUserInfoKey,id> *)dict{
    if (self == [super initWithDomain:GGErrorDomain code:code userInfo:dict]) {
        
    }
    return self;
}
@end

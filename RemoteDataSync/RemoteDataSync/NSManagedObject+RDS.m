//
//  NSManagedObject+RDS.m
//  PhotoKeeper
//
//  Created by Anton Remizov on 12/1/15.
//  Copyright © 2015 PhotoKeeper. All rights reserved.
//

#import "NSManagedObject+RDS.h"
#import "RDSManager.h"
#import "RDSObjectFactory.h"

@implementation NSManagedObject (RDS)

- (void) fetchWithSuccess:(nullable void (^)(id __nonnull responseObject))success
                  failure:(nullable void (^)(NSError* __nullable error))failure {
    [self fetch:nil
    withSuccess:^(id  _Nonnull responseObject, NSInteger newObjects) { if(success) success(responseObject);}
        failure:failure];
}

- (void) fetchWithParameters:(nullable NSDictionary*)parameters
                     success:(nullable void (^)(id __nonnull responseObject))success
                     failure:(nullable void (^)(NSError* __nullable error))failure {
    [self fetch:nil withParameters:parameters
        success:^(id  _Nonnull responseObject, NSInteger newObjects) { if(success) success(responseObject);}
        failure:failure];
}

- (void) fetch:(nullable NSString*)keyName
   withSuccess:(nullable void (^)(id __nonnull responseObject, NSInteger newObjects))success
       failure:(nullable void (^)(NSError* __nullable error))failure
{
    [self fetch:keyName withParameters:nil success:success failure:failure];
}

- (void) fetch:(nullable NSString*)keyName
withParameters:(nullable NSDictionary*)parameters
       success:(nullable void (^)(id __nonnull responseObject, NSInteger newObjects))success
       failure:(nullable void (^)(NSError* __nullable error))failure {
    RDSRequestConfiguration* configuration = [[RDSManager defaultManager].configurator configurationForObject:self
                                                                                                      keyPath:keyName
                                                                                                       scheme:RDSRequestSchemeFetch];
    [self fetch:keyName withParameters:parameters byReplacingData:configuration.replace success:success failure:failure];
}

- (void) fetch:(nullable NSString*)keyName
withParameters:(nullable NSDictionary*)parameters
byReplacingData:(BOOL)replace
       success:(nullable void (^)(id __nonnull responseObject, NSInteger newObjects))success
       failure:(nullable void (^)(NSError* __nullable error))failure {
    if(![NSThread isMainThread]) {
        @throw [NSException exceptionWithName:@"RDS Error" reason:@"method can be used from main thread only" userInfo:nil];
    }
    RDSRequestConfiguration* configuration = [[RDSManager defaultManager].configurator configurationForObject:self
                                                                                                      keyPath:keyName
                                                                                                       scheme:RDSRequestSchemeFetch];
    //so keyName maps to the config key in a hashtable somewhere to get a config object.  keyName after this point, points to the var that the factory will fill.  This is bad because if we want to fill the root object (I.E user) then it's an empty string "" and it doesn't work in a hashtable in objective c.  This also is bad when we want to update an object (I.E medias) using a different url or config.  If we want to update medias by getting all the medias that have changed from a timestamp, we'd have to make a new var and update the old var manually.  The block of code below seperates the config hash key and the var name by having the config hash key able to have the var name and a ? and anything after it like cache busting for javascript files in browsers.
    NSString* keyNameInObj = keyName;
    NSRange lastQuestionmarkRange = [keyNameInObj rangeOfString:@"?" options:NSBackwardsSearch];
    if (lastQuestionmarkRange.location != NSNotFound) {
        keyNameInObj = [keyNameInObj substringToIndex:lastQuestionmarkRange.location];
    }
    
    NSURLSessionDataTask* task =
    [[RDSManager defaultManager].networkConnector dataTaskForObject:self
                                                  withConfiguration:configuration
                                               additionalParameters:parameters
                                                            success:^(NSURLSessionDataTask *task, id response) {
                                                                NSInteger newObjects = 0;
                                                                if (keyNameInObj && [keyNameInObj length] > 0) {
                                                                    newObjects = [[RDSManager defaultManager].objectFactory fillRelationshipOnManagedObject:self withKey:keyNameInObj fromData:response byReplacingData:replace];
                                                                } else {
                                                                    [[RDSManager defaultManager].objectFactory fillObject:self
                                                                                                                 fromData:response];
                                                                }
                                                                [[RDSManager defaultManager].dataStore save];
                                                                if(success) {
                                                                    success(response, newObjects);
                                                                }
                                                            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                                                if(failure) {
                                                                    failure(error);
                                                                }
                                                            }];
    [task resume];
   
}


@end

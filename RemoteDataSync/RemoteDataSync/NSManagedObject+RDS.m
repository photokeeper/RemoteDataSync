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
    NSURLSessionDataTask* task =
    [[RDSManager defaultManager].networkConnector dataTaskForObject:self
                                                  withConfiguration:configuration
                                               additionalParameters:parameters
                                                            success:^(NSURLSessionDataTask *task, id response) {
                                                                NSInteger newObjects = 0;
                                                                if (keyName && ![keyName isEqualToString:@"me"]) { //added me to modify self object.  config name maps to what to edit in the object.  not super great for objects with a ton of strings in them or primitive data types like "user"
                                                                    newObjects = [[RDSManager defaultManager].objectFactory fillRelationshipOnManagedObject:self withKey:keyName fromData:response byReplacingData:replace];
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

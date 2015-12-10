//
//  RDSObjectFactoryCache.m
//  PhotoKeeper
//
//  Created by Anton Remizov on 12/7/15.
//  Copyright © 2015 PhotoKeeper. All rights reserved.
//

#import "RDSObjectFactoryCache.h"

@interface RDSObjectFactoryCache ()
{
    NSMutableDictionary* cache;
}

@end
@implementation RDSObjectFactoryCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        cache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id) cachedObjectOfType:(Class)type withValue:(id<NSCopying>)value forKey:(NSString*)key
{
    NSDictionary* cachedObjectsByType = cache[NSStringFromClass(type)];
    NSDictionary* cachedObjectsByKey = cachedObjectsByType[key];
    return cachedObjectsByKey[value];
}

- (void) cacheObject:(id)object forKey:(NSString*)key
{
    if (!key) {
        NSLog(@"RDSObjectFactoryCache Warning: Can't cache objects with no primaryKey");        
        return;
    }
    NSString* dictKey = [object valueForKey:key];
    if (!dictKey.length) {
        NSLog(@"RDSObjectFactoryCache Warning: Can't cache object with nil value for primaryKey");
        return;
    }
    
    NSMutableDictionary* cachedObjectsByType = cache[NSStringFromClass([object class])];
    if (!cachedObjectsByType) {
        cachedObjectsByType = [NSMutableDictionary dictionary];
        cache[NSStringFromClass([object class])] = cachedObjectsByType;
    }
    NSMutableDictionary* cachedObjectsByKey = cachedObjectsByType[key];
    if (!cachedObjectsByKey) {
        cachedObjectsByKey = [NSMutableDictionary dictionary];
        cachedObjectsByType[key] = cachedObjectsByKey;
    }
    if(cachedObjectsByKey[[object valueForKey:key]] && ![cachedObjectsByKey[[object valueForKey:key]] isEqual:object]) {
        NSLog(@"RDSObjectFactoryCache Warning: 2 Objects have same id but not equal, cache will overwrite the object with the new value: %@, %@",cachedObjectsByKey[[object valueForKey:key]],object);
    }
    cachedObjectsByKey[dictKey] = object;
}

- (void) clearCache {
    [cache removeAllObjects];
}

- (void) clearCacheForType:(Class)type {
    [cache removeObjectForKey:NSStringFromClass(type)];
}

@end

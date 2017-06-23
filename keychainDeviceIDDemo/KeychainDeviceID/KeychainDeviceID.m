//
//  KeychainDeviceID.m
//  KeychainDeviceID
//
//  Created by C.K.Lian on 16/3/11.
//  Copyright © 2016年 C.K.Lian. All rights reserved.
//

#import "KeychainDeviceID.h"
#import <Security/Security.h>
#include "OpenUDID.h"

//在Keychain中的标识，这里取bundleIdentifier + UUID / OpenUDID
#define KEYCHAIN_IDENTIFIER(a)  ([NSString stringWithFormat:@"%@_%@",[[NSBundle mainBundle] bundleIdentifier],a])

#define KCIDisNull(a) (a==nil ||\
                   a==NULL ||\
                   (NSNull *)(a)==[NSNull null] ||\
                   ((NSString *)a).length==0)

@implementation KeychainDeviceID

+ (NSString *)getUUID {
    //读取keychain缓存
    NSString *deviceID = [self load:KEYCHAIN_IDENTIFIER(@"UUID")];
    //不存在，生成UUID
    if (KCIDisNull(deviceID))
    {
        CFUUIDRef uuid_ref = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef uuid_string_ref= CFUUIDCreateString(kCFAllocatorDefault, uuid_ref);
        
        CFRelease(uuid_ref);
        deviceID = [NSString stringWithString:(__bridge NSString*)uuid_string_ref];
        deviceID = [deviceID lowercaseString];
        if (!KCIDisNull(deviceID))
        {
            [self save:KEYCHAIN_IDENTIFIER(@"UUID") data:deviceID];
        }
        CFRelease(uuid_string_ref);
    }
    if (KCIDisNull(deviceID)) {
        NSLog(@"get deviceID error!");
    }
    return deviceID;
}

+ (NSString *)getOpenUDID {
    //读取keychain缓存
    NSString *deviceID = [self load:KEYCHAIN_IDENTIFIER(@"OpenUDID")];
    if (KCIDisNull(deviceID))
    {
        //不存在，生成openUDID
        deviceID = [OpenUDID value];
        
        if (!KCIDisNull(deviceID))
        {
            [self save:KEYCHAIN_IDENTIFIER(@"OpenUDID") data:deviceID];
        }
    }
    if (KCIDisNull(deviceID)) {
        NSLog(@"get deviceID error!");
    }
    return deviceID;
}

+ (void)deleteDeviceID {
    [self delete:KEYCHAIN_IDENTIFIER(@"UUID")];
    [self delete:KEYCHAIN_IDENTIFIER(@"OpenUDID")];
}


#pragma mark - Private Method Keychain相关
+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service {
    //第一次解锁后可访问，备份
    NSDictionary *dic = @{
                          (__bridge_transfer id)kSecClass:(__bridge_transfer id)kSecClassGenericPassword,
                          (__bridge_transfer id)kSecAttrService:service,
                          (__bridge_transfer id)kSecAttrAccount:service,
                          (__bridge_transfer id)kSecAttrAccessible:(__bridge_transfer id)kSecAttrAccessibleAfterFirstUnlock
                          };
    NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:3];
    [resultDic addEntriesFromDictionary:dic];
    return resultDic;
    
}

+ (void)save:(NSString *)service data:(id)data {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge_retained CFDictionaryRef)(keychainQuery));
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data]
                      forKey:(__bridge_transfer id<NSCopying>)(kSecValueData)];
    SecItemAdd((__bridge_retained CFDictionaryRef)(keychainQuery), NULL);
    
    if (keychainQuery) {
        CFRelease((__bridge CFTypeRef)(keychainQuery));
    }
}

+ (id)load:(NSString *)service {
    id ret = @"";
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(__bridge_transfer id<NSCopying>)(kSecReturnData)];
    [keychainQuery setObject:(__bridge_transfer id)(kSecMatchLimitOne) forKey:(__bridge_transfer id<NSCopying>)(kSecMatchLimit)];
    
    CFTypeRef result = NULL;
    if (SecItemCopyMatching((__bridge_retained CFDictionaryRef)keychainQuery, &result) == noErr)
    {
        ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge_transfer NSData*)result];
    }
    
    if (keychainQuery) {
        CFRelease((__bridge CFTypeRef)(keychainQuery));
    }
    return ret;
}

+ (void)delete:(NSString *)service {
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge_retained CFDictionaryRef)(keychainQuery));
    if (keychainQuery) {
        CFRelease((__bridge CFTypeRef)(keychainQuery));
    }
}

@end

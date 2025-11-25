#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>
#include <dirent.h>
#include <unistd.h>
#include <dlfcn.h>
#include <assert.h>
#include <errno.h>
#include <pwd.h>
#include <dlfcn.h>
#include <Foundation/Foundation.h>
#include <Foundation/Foundation.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <mach-o/fat.h>
#include <mach-o/arch.h>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach/error.h>
#include <mach/message.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <ptrauth.h>
#include <execinfo.h>
#include <Foundation/Foundation.h>
#include <Foundation/NSProcessInfo.h>
#include <SystemConfiguration/SystemConfiguration.h>
#include <Security/SecTrust.h>
#include <unistd.h>
#include <pwd.h>

#include "CaptainHook.h"

#define _disused \
    __attribute__((__unused__))

#define TRY_BEGIN @try {
#define TRY_END     }   \
    @catch (NSException *exception) {}  \
    @finally  {}

#define SAFE_RELEASE(ptr)  do {       \
    if (ptr) CFRelease(ptr);          \
    } while (0)

NSMutableDictionary* MutableDictionaryWithPList(NSString* jsonString){
    if (jsonString == nil) {
        return nil;
    }
    NSData *plistData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSPropertyListFormat format; 
    NSString *errorDesc = nil; 
    NSMutableDictionary* dict = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
    if (errorDesc != nil) {
        [errorDesc release]; 
    }
    return dict;
}

NSData* NSMutableDictionaryToNSDataPlist(NSMutableDictionary* dict) {
    NSString *err = nil;
    NSData *plist;
    plist = [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListXMLFormat_v1_0 errorDescription:&err];
    if(plist == nil) {
        return nil;
    }
    return plist;
}

NSDictionary* MetaDataToNSDict(NSString* metadata) {
    NSData *metadata_data = [[NSData alloc] initWithBase64EncodedString:metadata options:0];
    NSError *error;
    NSDictionary *tempDict = [[NSDictionary alloc] init];
    tempDict = [NSPropertyListSerialization propertyListWithData:metadata_data options:0 format:NULL error:&error];
    if (tempDict == nil) {
        return nil;
    }
    return tempDict;
}


NSString* X_Apple_I_SRL_NO() {
    assert(dlopen("/System/Library/PrivateFrameworks/AuthKit.framework/AuthKit", RTLD_LAZY | RTLD_GLOBAL) != NULL);
    Class AKDevice = NSClassFromString(@"AKDevice");
    return [[AKDevice currentDevice] serialNumber];
}

NSData* FilterSpecifyFormat(NSString* resp) {
    NSMutableDictionary* GET_RECORDS_DATA = MutableDictionaryWithPList(resp);
    if (GET_RECORDS_DATA == nil) {
        return nil;
    }
    NSString* serialNumber = X_Apple_I_SRL_NO();
    NSArray* backup_metadataList = [GET_RECORDS_DATA valueForKey:@"metadataList"];
    if (backup_metadataList == nil) {
        return nil;
    }
    // NSLog(@"xxxxx:%@", backup_metadataList);
    // int arr[256] = {-1};
    // for( int i = 0; (backup_metadataList != nil && i < backup_metadataList.count); i++) {
    //     NSString* metadata = [[backup_metadataList objectAtIndex:i] valueForKey:@"metadata"];
    //     NSDictionary *tempDict = MetaDataToNSDict(metadata);
    //     // NSLog(@"src serialNumber:%@-dst serialNumber:%@", [[backup_metadataList objectAtIndex:i] valueForKey:@"label"], serialNumber);
    //     NSString* label = [[backup_metadataList objectAtIndex:i] valueForKey:@"label"];
    //     bool is_eq = [label isEqualToString:@"com.apple.protectedcloudstorage.record"];
    //     if (is_eq) {
    //         NSLog(@"xxxxx2:%@", label);
    //         NSLog(@"!!!!!!DEVICE_SERIAL:            %@", tempDict[@"serial"]);
    //         NSLog(@"!!!!!!DEVICE_MODEL_VERSION:     %@", tempDict[@"ClientMetadata"][@"device_model_version"]);
    //         NSLog(@"!!!!!!DEVICE_NAME:              %@", tempDict[@"ClientMetadata"][@"device_name"]);
    //         NSLog(@"!!!!!!DEVICE_MODEL:             %@", tempDict[@"ClientMetadata"][@"device_model"]);
    //         arr[i] = -1;
    //         break;
    //     }
    //     else {
    //         NSLog(@"xxxxx1:%@", label);
    //         arr[i] = i;
    //     }
    // }
    // for (int i = 0; arr[i] != -1; i++) {
    //     [backup_metadataList removeObjectAtIndex:0];
    // }
    // [backup_metadataList removeObjectAtIndex:0];
    // NSLog(@"xxxxx:%@", backup_metadataList);
    // NSArray *arr1 = [NSArray array];
    // GET_RECORDS_DATA[@"metadataList"] = arr1;
    // [backup_metadataList removeObjectAtIndex:backup_metadataList.count - 1];
    // for (int i = 0; i < (backup_metadataList.count - 1); i++) {
    //     [backup_metadataList removeObjectAtIndex:0];
    // }
    // GET_RECORDS_DATA[@"metadataList"] = backup_metadataList;
    return NSMutableDictionaryToNSDataPlist(GET_RECORDS_DATA);
}

CHDeclareClass(LakituResponse); // declare class

CHOptimizedMethod2(self, LakituResponse*, LakituResponse, initWithURLResponse, NSHTTPURLResponse*, resp, data, NSData*, data) {
    if ([resp isKindOfClass:[NSHTTPURLResponse class]]) {
        // NSLog(@"+[network_hook] LakituResponse:%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSData* dat = FilterSpecifyFormat([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        if (dat != nil) {
            return CHSuper2(LakituResponse, initWithURLResponse, resp, data, dat);
        }
    }
    return CHSuper2(LakituResponse, initWithURLResponse, resp, data, data);
}

void LakituResponse_initWithURLResponse() {
    TRY_BEGIN
    CHLoadLateClass(LakituResponse);
    CHClassHook2(LakituResponse, initWithURLResponse, data);
    TRY_END
}

CHDeclareClass(EscrowGenericResponse); // declare class

CHOptimizedMethod2(self, EscrowGenericResponse*, EscrowGenericResponse, initWithURLResponse, NSHTTPURLResponse*, resp, data, NSData*, data) {
    if ([resp isKindOfClass:[NSHTTPURLResponse class]]) {
        // NSLog(@"+[network_hook] EscrowGenericResponse:%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSData* dat = FilterSpecifyFormat([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        if (dat != nil) {
            return CHSuper2(EscrowGenericResponse, initWithURLResponse, resp, data, dat);
        }
    }
    return CHSuper2(EscrowGenericResponse, initWithURLResponse, resp, data, data);
}

void EscrowGenericResponse_initWithURLResponse() {
    TRY_BEGIN
    CHLoadLateClass(EscrowGenericResponse);
    CHClassHook2(EscrowGenericResponse, initWithURLResponse, data);
    TRY_END
}

__attribute__((__constructor__)) static void _MSInitialize(void) {
    static bool is_initialized = false;
    if (is_initialized) {
        return;
    }
    NSLog(@"+[network_hook] hook network");
    dlopen("libsystem_kernel.dylib", RTLD_LAZY | RTLD_NOW);
    dlopen("libsystem_c.dylib", RTLD_LAZY | RTLD_NOW);
    dlopen("libcommonCrypto.dylib", RTLD_LAZY | RTLD_NOW);
    dlopen("libmis.dylib", RTLD_LAZY | RTLD_NOW);
    dlopen("libmacho.dylib", RTLD_LAZY | RTLD_NOW);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    LakituResponse_initWithURLResponse();
    EscrowGenericResponse_initWithURLResponse();
    [pool drain];
    is_initialized = true;
}
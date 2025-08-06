/********* AppDelegate+JotURL.m Cordova Plugin *******/
//// Created by André Grillo ////

#import "AppDelegate.h"
#import <objc/runtime.h>

// Static variable to store the initial deep link URL
static NSString *_initialDeepLinkURL = nil;

@implementation AppDelegate (UniversalLinks)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        // Swizzle didFinishLaunchingWithOptions
        SEL originalSelector = @selector(application:didFinishLaunchingWithOptions:);
        SEL swizzledSelector = @selector(swizzled_application:didFinishLaunchingWithOptions:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
        // Swizzle continueUserActivity
        SEL originalContinueSelector = @selector(application:continueUserActivity:restorationHandler:);
        SEL swizzledContinueSelector = @selector(swizzled_application:continueUserActivity:restorationHandler:);
        
        Method originalContinueMethod = class_getInstanceMethod(class, originalContinueSelector);
        Method swizzledContinueMethod = class_getInstanceMethod(class, swizzledContinueSelector);
        
        BOOL didAddContinueMethod = class_addMethod(class, originalContinueSelector, method_getImplementation(swizzledContinueMethod), method_getTypeEncoding(swizzledContinueMethod));
        
        if (didAddContinueMethod) {
            class_replaceMethod(class, swizzledContinueSelector, method_getImplementation(originalContinueMethod), method_getTypeEncoding(originalContinueMethod));
        } else {
            method_exchangeImplementations(originalContinueMethod, swizzledContinueMethod);
        }
    });
}

- (BOOL)swizzled_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    
    // Clear any previous deep link data from memory
    _initialDeepLinkURL = nil;
    
    // Check if app was launched via universal link
    if (launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey]) {
        NSDictionary *userActivityDict = launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey];
        NSUserActivity *userActivity = userActivityDict[@"UIApplicationLaunchOptionsUserActivityKey"];
        
        if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
            NSURL *url = userActivity.webpageURL;
            if (url) {
                NSLog(@"App launched with universal link: %@", url.absoluteString);
                _initialDeepLinkURL = [url.absoluteString copy];
            }
        }
    }
    
    // Call the original method
    return [self swizzled_application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)swizzled_application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *url = userActivity.webpageURL;
        if (url) {
            NSLog(@"App opened with universal link while running: %@", url.absoluteString);
            // Send custom notification with URL as userInfo (keep this for runtime links)
            NSDictionary *userInfo = @{@"url": url.absoluteString};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UniversalLinkReceived"
                                                                object:nil
                                                              userInfo:userInfo];
            return YES;
        }
    }
    
    // Call the original method if it exists
    if ([self respondsToSelector:@selector(swizzled_application:continueUserActivity:restorationHandler:)]) {
        return [self swizzled_application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    
    return NO;
}

@end

// MARK: - Bridge class to expose deep link methods to Swift
@interface JotURLBridge : NSObject
+ (NSString * _Nullable)getInitialDeepLinkURL;
+ (void)clearInitialDeepLinkURL;
+ (BOOL)hasInitialDeepLinkURL;
@end

@implementation JotURLBridge

+ (NSString * _Nullable)getInitialDeepLinkURL {
    return _initialDeepLinkURL;
}

+ (void)clearInitialDeepLinkURL {
    _initialDeepLinkURL = nil;
}

+ (BOOL)hasInitialDeepLinkURL {
    return (_initialDeepLinkURL != nil && _initialDeepLinkURL.length > 0);
}

@end


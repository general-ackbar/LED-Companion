//
//  AppDelegate.m
//  LED Companion
//
//  Created by Jonatan Yde on 20/09/2020.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    

    NSString * display_width = [[NSUserDefaults standardUserDefaults] objectForKey:@"pref_width"];
    NSString * display_height = [[NSUserDefaults standardUserDefaults] objectForKey:@"pref_height"];
    NSString * host = [[NSUserDefaults standardUserDefaults] objectForKey:@"pref_host"];
    NSString * port = [[NSUserDefaults standardUserDefaults] objectForKey:@"pref_port"];
    
    if (!display_width || !display_height || !host || !port) {
        [self registerDefaultsFromSettingsBundle];
        /*
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:^(BOOL success) {
            
        }];
         */
    }
    
    
    return YES;
}




-(void)registerDefaultsFromSettingsBundle
{
     NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
     if(!settingsBundle) {
         NSLog(@"Could not find Settings.bundle");
         return;
     }

     NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
     NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];

     NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
     for(NSDictionary *prefSpecification in preferences) {
         NSString *key = [prefSpecification objectForKey:@"Key"];
         if(key) {
             [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
             //NSLog(@"writing as default %@ to the key %@",[prefSpecification objectForKey:@"DefaultValue"],key);
             [[NSUserDefaults standardUserDefaults] setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
         }
     }

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end

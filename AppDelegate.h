//
//  AppDelegate.h
//  NGTabBarControllerDemo
//
//  Created by Tretter Matthias on 16.02.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "NGTabBarController.h"
#import "GridViewController.h"
#import "IASKAppSettingsViewController.h"


#define sharedAppDelegate (AppDelegate *) [[UIApplication sharedApplication] delegate]

@class MediaLibrary, ALAssetsLibrary, PlaybackViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, NGTabBarControllerDelegate, UITextViewDelegate, AQGridViewDelegate, AQGridViewDataSource> {
    int currentIndex;
    MediaLibrary* mediaIndex;
    NGTabBarController *tbc;
    GridViewController *gvc;
	ALAssetsLibrary *assetsLibrary;    
    NSMutableArray *viewControllers;
    NSMutableArray *favorites;
    NSMutableArray *history;
	PlaybackViewController* playbackViewController;
    UINavigationController* videoPlaybackController;
    UINavigationController* nc;
}

-(void)indexIPodLibrary;
-(NSString*)getMarksPath;
-(NSMutableDictionary*)loadMarks;
-(void)saveMarks;
-(BOOL)logHistory:(NSDictionary*)item;
-(BOOL)toggleFavorite:(NSDictionary*)item;
-(void)playVideoWithURL:(AVURLAsset*)url andTitle:(NSString*)title;

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) int currentIndex;
@property (nonatomic) MediaLibrary* mediaIndex;
@property (nonatomic, strong) NSMutableArray* favorites;
@property (nonatomic, strong) NSMutableArray* history;
@property (nonatomic, strong) UINavigationController* videoPlaybackController;
@property (nonatomic, strong) UINavigationController* nc;

@end

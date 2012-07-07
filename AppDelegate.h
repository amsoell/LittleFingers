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
#import "IASKAppSettingsViewController.h"


#define sharedAppDelegate (AppDelegate *) [[UIApplication sharedApplication] delegate]

@class MediaLibrary, ALAssetsLibrary, PlaybackViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, NGTabBarControllerDelegate, UITextViewDelegate> {
    int currentIndex;
    MediaLibrary* mediaIndex;
    NGTabBarController *tbc;
	ALAssetsLibrary *assetsLibrary;    
    NSMutableArray *viewControllers;
    NSMutableArray *favorites;
    NSMutableArray *history;
    UITableView *tbfavorite;
    UITableView *tbhistory;
	PlaybackViewController* playbackViewController;
    UINavigationController* videoPlaybackController;
}

-(void)indexIPodLibrary;
-(NSString*)getMarksPath;
-(NSMutableDictionary*)loadMarks;
-(void)saveMarks;
-(void)logHistory:(NSDictionary*)item;
-(BOOL)toggleFavorite:(NSDictionary*)item;
-(void)playVideoWithURL:(AVURLAsset*)url andTitle:(NSString*)title;

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) int currentIndex;
@property (nonatomic) MediaLibrary* mediaIndex;
@property (nonatomic, strong) NSMutableArray* favorites;
@property (nonatomic, strong) NSMutableArray* history;
@property (nonatomic, strong) UINavigationController* videoPlaybackController;

@end

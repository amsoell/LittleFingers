//
//  AppDelegate.h
//  NGTabBarControllerDemo
//
//  Created by Tretter Matthias on 16.02.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NGTabBarController.h"
#import "IASKAppSettingsViewController.h"

#define sharedAppDelegate (AppDelegate *) [[UIApplication sharedApplication] delegate]

@class MediaLibrary, ALAssetsLibrary;

@interface AppDelegate : UIResponder <UIApplicationDelegate, NGTabBarControllerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate> {
    int currentIndex;
    MediaLibrary* mediaIndex;
    NGTabBarController *tbc;
	ALAssetsLibrary *assetsLibrary;    
    NSMutableArray *viewControllers;
    NSMutableArray *favorites;
    NSMutableArray *history;
    UITableView *tbfavorite;
    UITableView *tbhistory;
}

-(void)indexIPodLibrary;
-(NSString*)getMarksPath;
-(NSMutableDictionary*)loadMarks;
-(void)saveMarks;
-(void)logHistory:(NSDictionary*)item;
-(BOOL)toggleFavorite:(NSDictionary*)item;

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) int currentIndex;
@property (nonatomic) MediaLibrary* mediaIndex;
@property (nonatomic, strong) NSMutableArray* favorites;
@property (nonatomic, strong) NSMutableArray* history;

@end

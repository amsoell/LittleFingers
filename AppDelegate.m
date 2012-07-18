//
//  AppDelegate.m
//  NGTabBarControllerDemo
//
//  Created by Tretter Matthias on 16.02.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "AppDelegate.h"
#import "MediaLibrary.h"
#import "NGVTabBarController.h"
#import "GridViewController.h"
#import "GridViewCell.h"
#import "CollectionBrowser.h"
#import "PlaybackViewController.h"
#import "WelcomeViewController.h"
#import "IASKAppSettingsViewController.h"
#import "iRate.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/QuartzCore.h>

@implementation AppDelegate

@synthesize window = _window;
@synthesize currentIndex, mediaIndex, favorites, history, videoPlaybackController, nc, shortAppName, longAppName;


+(void) initialize {
    [iRate sharedInstance].debug = NO;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0) {
        [iRate sharedInstance].appStoreID = 544428007;
        [iRate sharedInstance].usesUntilPrompt = 5;
        [iRate sharedInstance].ratingsURL = [NSURL URLWithString:@"http://itunes.apple.com/us/app/littlefingers-video-player/id544428007?mt=8"];
    }    
}

- (AppDelegate*) init {
    if (!assetsLibrary) assetsLibrary = [[ALAssetsLibrary alloc] init];
    if (!viewControllers) viewControllers = [[NSMutableArray alloc] init];
    history = [[self loadMarks] objectForKey:@"history"];
    favorites = [[self loadMarks] objectForKey:@"favorites"];
    shortAppName = @"LittleFingers";
    longAppName = [NSString stringWithFormat:@"%@ Video Player", shortAppName];
    
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]] forKey:@"version"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return [super init];
}

- (NSString*)getMarksPath {
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"marks.plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath: path]) {
        NSString *bundle = [[NSBundle mainBundle] pathForResource:@"marks" ofType:@"plist"];
        
        [fileManager copyItemAtPath:bundle toPath:path error:&error];
    }
    
    return path;
}

- (NSMutableDictionary*)loadMarks {
    NSString* path = [self getMarksPath];
    NSMutableDictionary *objects = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    
    NSLog(@"loading marks %@ from %@", objects, path);    
    
    if (![objects objectForKey:@"history"]) [objects setObject:[[NSMutableArray alloc] init] forKey:@"history"];
    if (![objects objectForKey:@"favorites"]) [objects setObject:[[NSMutableArray alloc] init] forKey:@"favorites"];    
    
    // Convert url properties to NSURLs
    for (NSMutableDictionary* item in [objects objectForKey:@"history"]) {
        NSURL* url = [NSURL URLWithString:[item objectForKey:@"url"]];
        if (url != nil) [item setObject:url forKey:@"url"];
    }
    for (NSMutableDictionary* item in [objects objectForKey:@"favorites"]) {
        NSURL* url = [NSURL URLWithString:[item objectForKey:@"url"]];
        if (url != nil) [item setObject:url forKey:@"url"];
    }

    
    NSLog(@"loaded: %@", objects);
    
    return objects;
}

- (void)saveMarks {
    NSString* path = [self getMarksPath];    
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    NSLog(@"presave: %@", data);

    NSMutableArray* h = [[NSMutableArray alloc] init];
    NSMutableArray* f = [[NSMutableArray alloc] init];

    // Convert NSURLs to NSStrings
    for (NSMutableDictionary* item in history) {
        NSDictionary* r = [NSDictionary dictionaryWithObjectsAndKeys:[[item objectForKey:@"url"] absoluteString], @"url", [item objectForKey:@"title"], @"title", nil];
        if (r.count>0) [h addObject:r];
    }

    for (NSMutableDictionary* item in favorites) {
        NSDictionary* r = [NSDictionary dictionaryWithObjectsAndKeys:[[item objectForKey:@"url"] absoluteString], @"url", [item objectForKey:@"title"], @"title", nil];
        if (r.count>0) [f addObject:r];
    }
    
    [data setObject:h forKey:@"history"];
    [data setObject:f forKey:@"favorites"];  
    [data writeToFile:path atomically:YES];
}

- (BOOL)logHistory:(NSDictionary *)item {
    for (NSDictionary* vid in history) if ([[vid objectForKey:@"url"] isEqual:[item objectForKey:@"url"]]) return NO;

    [history insertObject:item atIndex:0];
    if (history.count>3) {
        [history removeObjectsInRange:NSMakeRange(3, history.count - 3)];
    }
    return YES;
}

- (BOOL)toggleFavorite:(NSDictionary*)item {
    for (NSDictionary* fav in favorites) {
        if ([fav isEqualToDictionary:item]) {
            // remove it
            [favorites removeObject:fav];
            NSLog(@"Removed. New favorites: %@", favorites);                
            return false;
        }
    }
    // add it
    [favorites addObject:item];
    
    NSLog(@"Added. New favorites: %@", favorites);    
    return true;
}

- (void)indexIPodLibrary {
    [[NSUserDefaults standardUserDefaults] synchronize];            
    // Take a look at the movies library and determine media types
    MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeAnyVideo] forProperty:MPMediaItemPropertyMediaType];    
    MPMediaQuery *videoQuery = [[MPMediaQuery alloc] initWithFilterPredicates:[NSSet setWithObject:predicate]];    
    NSArray* videos = [videoQuery items];    
    
    // Iterate through videos to build index
    NSInteger mediaType;
	for (MPMediaItem *video in videos) {  
        [mediaIndex addItem:video];        
        
        mediaType = [[video valueForProperty:MPMediaItemPropertyMediaType] integerValue];
        if (mediaType & MPMediaTypeVideoITunesU) [mediaIndex addItem:video toCollection:@"ITunesU" withCollectionTitle:@"iTunes U"];
        if (mediaType & MPMediaTypeMusicVideo) [mediaIndex addItem:video toCollection:@"MusicVideo" withCollectionTitle:@"Music Videos"];
        if (mediaType & MPMediaTypeVideoPodcast) [mediaIndex addItem:video toCollection:@"VideoPodcast" withCollectionTitle:@"Podcasts"];
        if (mediaType & MPMediaTypeTVShow) [mediaIndex addItem:video toCollection:@"TVShow" withCollectionTitle:@"TV Shows"];
        if (mediaType & MPMediaTypeMovie) [mediaIndex addItem:video toCollection:@"Movie" withCollectionTitle:@"Movies"];
    }    
}

- (void)indexCameraRoll {
    
    ALAssetsLibrary *assetLibrary = assetsLibrary;
    NSMutableArray* cameraCollection = [[NSMutableArray alloc] init];        
    
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
            [group enumerateAssetsUsingBlock:
             ^(ALAsset *asset, NSUInteger index, BOOL *stop)
             {
                 if (asset) {
                     ALAssetRepresentation *defaultRepresentation = [asset defaultRepresentation];
                     NSString *uti = [defaultRepresentation UTI];
                     NSURL *URL = [[asset valueForProperty:ALAssetPropertyURLs] valueForKey:uti];
                     NSString *title = [NSString stringWithFormat:@"%@ %i", NSLocalizedString(@"Video", nil), [cameraCollection count]+1];
                     
                     NSMutableDictionary* details = [NSMutableDictionary dictionaryWithObjectsAndKeys:title, @"title", URL, @"url", nil];
                     NSLog(@"Found camera item %@ at %@", title, URL);                     
                     [cameraCollection addObject:details];
                 }
             }];
        }
        // group == nil signals we are done iterating.
        else {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"askedForLocation"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if (cameraCollection.count > 0) {    
                if (cameraCollectionBrowser.isViewLoaded) {
                    // tabbar controller already exists.
                    // remove the explanation uilabels
                    for (UIView* view in cameraCollectionBrowser.view.subviews) {
                        NSLog(@"view: %@", view);
                        if (view.tag == 1) {
                            [view removeFromSuperview];
                        }
                    }

                    // now set up the datasource
                    [cameraCollectionBrowser setDataSource:[NSDictionary dictionaryWithObjectsAndKeys:cameraCollection, @"Camera Roll", nil]];
                    [cameraCollectionBrowser setEmptyText:nil];
                    [cameraCollectionBrowser.tv reloadData];
                } else {   
                    NSLog(@"i don't think this should ever get reached");
                    // We're being called from launch
                    NSLog(@"adding camera collection");
                    
                    cameraCollectionBrowser = [[CollectionBrowser alloc] init];  
                    cameraCollectionBrowser.disableSecondaryDataSource = YES;
                    cameraCollectionBrowser.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"Camera Roll" image:[UIImage imageNamed:@"CameraRoll"]];    
                    cameraCollectionBrowser.ng_tabBarItem.mediaIndex = @"CameraRoll";
                    cameraCollectionBrowser.title = @"Camera Roll";
                    
                    [cameraCollectionBrowser setDataSource:[NSDictionary dictionaryWithObjectsAndKeys:cameraCollection, @"Camera Roll", nil]];
                    [cameraCollectionBrowser.tv reloadData];
                    
                    [viewControllers addObject:cameraCollectionBrowser];  
                }
            } else {
                NSLog(@"skipping camera collection");
            }
            
            if (!cameraCollectionBrowser.isViewLoaded) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"view controllers: %@", viewControllers);
                    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {                       
                        // Assign iPad tabs
                        [self updateTabBarController:tbc];
                    } else {
                        // Assign iPhone / iPod Touch buttons
                        [gvc.gridView reloadData];
                        NSLog(@"assign iphone / ipod buttons");
                    }
                });            
            }
        }
    } failureBlock:^(NSError *error) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"askedForLocation"];
        [[NSUserDefaults standardUserDefaults] synchronize];        
        NSLog(@"error enumerating AssetLibrary groups %@\n", error);
        
        if (!cameraCollectionBrowser.isViewLoaded) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"view controllers: %@", viewControllers);
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {                       
                    // Assign iPad tabs
                    [self updateTabBarController:tbc];
                } else {
                    // Assign iPhone / iPod Touch buttons
                    [gvc.gridView reloadData];
                    NSLog(@"assign iphone / ipod buttons");
                }
            });            
        } else {
            for (UIView* view in cameraCollectionBrowser.view.subviews) {
                NSLog(@"view: %@", view);
                if (view.tag == 1) {
                    [view removeFromSuperview];
                }
            }
            [tbc setSelectedIndex:0];
     
             UILabel *logo = [[UILabel alloc] init];
             NSString *logoText = @"Camera Roll Access Unavailable";
             UIFont *logoFont = [UIFont fontWithName:@"HoneyScript-SemiBold" size:45.0f];
             [logo setTag:1]; // mark for removal
             [logo setText:logoText];
             [logo setFont:logoFont];
             [logo setMinimumFontSize:32.0f];
             [logo setAdjustsFontSizeToFitWidth:YES];
             [logo setTextColor:[UIColor darkGrayColor]];
             [logo setBackgroundColor:[UIColor clearColor]];
             [logo setShadowColor:[UIColor whiteColor]];
             [logo setShadowOffset:CGSizeMake(0, -0.5)];
             [logo setAdjustsFontSizeToFitWidth:YES];
             
             CGRect frame = logo.frame;
             frame.origin.x = 30;
             frame.origin.y = 20;
             [logo setFrame:frame];
             [logo sizeToFit];
     
            [cameraCollectionBrowser.view addSubview:logo];
     
        }
        
    }];      
}

- (void)checkLocationPermissions {
    [[NSUserDefaults standardUserDefaults] synchronize];            
    BOOL askedForLocation = [[NSUserDefaults standardUserDefaults] boolForKey:@"askedForLocation"];    
    NSLog(@"camera access: %d", askedForLocation);

    
    if (askedForLocation) {
        [self indexCameraRoll];
    } else {
        // User has not been asked for location access yet

        cameraCollectionBrowser = [[CollectionBrowser alloc] init];
        cameraCollectionBrowser.disableSecondaryDataSource = YES;        
        cameraCollectionBrowser.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"Camera Roll" image:[UIImage imageNamed:@"CameraRoll"]];    
        cameraCollectionBrowser.ng_tabBarItem.mediaIndex = @"CameraRoll";
        cameraCollectionBrowser.title = @"Camera Roll";
        
        UILabel *logo = [[UILabel alloc] init];
        NSString *logoText = @"Why we ask for your location";
        UIFont *logoFont = [UIFont fontWithName:@"HoneyScript-SemiBold" size:45.0f];
        [logo setTag:1]; // mark for removal
        [logo setText:logoText];
        [logo setFont:logoFont];
        [logo setMinimumFontSize:32.0f];
        [logo setAdjustsFontSizeToFitWidth:YES];
        [logo setTextColor:[UIColor darkGrayColor]];
        [logo setBackgroundColor:[UIColor clearColor]];
        [logo setShadowColor:[UIColor whiteColor]];
        [logo setShadowOffset:CGSizeMake(0, -0.5)];
        [logo setAdjustsFontSizeToFitWidth:YES];
        
        CGRect frame = logo.frame;
        frame.origin.x = 30;
        frame.origin.y = 20;
        [logo setFrame:frame];
        [logo sizeToFit];
                
        NSString *copyText = [NSString stringWithFormat:@"Because the videos you have taken may contain information about where they were recorded, we are required to ask your permission before we can use them in %@. Rest assured that %@ does not collect any information about your location at any time. If you are ok with us having access to the videos that you have taken, press the button below to confirm this.", [sharedAppDelegate shortAppName], [sharedAppDelegate shortAppName]];
        UIFont *copyFont = [UIFont fontWithName:@"Baskerville" size:(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?20.0f:16.0f)];        
        UILabel *copy = [[UILabel alloc] initWithFrame:CGRectMake(30, 80, cameraCollectionBrowser.view.bounds.size.width-60, (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?80:220))];     
        [copy setTag:1]; // mark for removal
        [copy setContentMode:UIViewContentModeScaleAspectFit];
        [copy setText:copyText];
        [copy setFont:copyFont];
        [copy setNumberOfLines:0];
        [copy setLineBreakMode:UILineBreakModeWordWrap];
        [copy setTextColor:[UIColor darkGrayColor]];
        [copy setBackgroundColor:[UIColor clearColor]];
        [copy setShadowColor:[UIColor whiteColor]];
        [copy setShadowOffset:CGSizeMake(0, -0.5)];
        [copy setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin];  
        [copy setMinimumFontSize:16.0f];
        [copy setAdjustsFontSizeToFitWidth:YES];
        
        UIButton *locationPrompt = [UIButton buttonWithType:UIButtonTypeCustom];
        [locationPrompt setTag:1]; // mark for removal
        [locationPrompt setFrame:CGRectMake(60, (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?280:320), 200, 50)];
        [locationPrompt setTitle:@"Include Camera Roll" forState:UIControlStateNormal];
        [locationPrompt setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin]; 
        [locationPrompt.layer setCornerRadius:5.0f];
        [locationPrompt setBackgroundColor:[UIColor blackColor]];

        // Add Border
        CALayer *layer = locationPrompt.layer;
        layer.cornerRadius = 8.0f;
        layer.masksToBounds = YES;
        layer.borderWidth = 1.0f;
        layer.borderColor = [UIColor colorWithWhite:0.5f alpha:0.2f].CGColor;
        
        // Add Shine
        CAGradientLayer *shineLayer = [CAGradientLayer layer];
        shineLayer.frame = layer.bounds;
        shineLayer.colors = [NSArray arrayWithObjects:
                             (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                             (id)[UIColor colorWithWhite:1.0f alpha:0.2f].CGColor,
                             (id)[UIColor colorWithWhite:0.75f alpha:0.2f].CGColor,
                             (id)[UIColor colorWithWhite:0.4f alpha:0.2f].CGColor,
                             (id)[UIColor colorWithWhite:1.0f alpha:0.4f].CGColor,
                             nil];
        shineLayer.locations = [NSArray arrayWithObjects:
                                [NSNumber numberWithFloat:0.0f],
                                [NSNumber numberWithFloat:0.5f],
                                [NSNumber numberWithFloat:0.5f],
                                [NSNumber numberWithFloat:0.8f],
                                [NSNumber numberWithFloat:1.0f],
                                nil];
        [layer addSublayer:shineLayer];

        [locationPrompt.titleLabel setFont:[UIFont fontWithName:copyFont.fontName size:18.0f]];
        [locationPrompt addTarget:self action:@selector(indexCameraRoll) forControlEvents:UIControlEventTouchUpInside];
        
        UIView *content = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cameraCollectionBrowser.view.bounds.size.width, cameraCollectionBrowser.view.bounds.size.height)];
        [content setTag:1]; // mark for removal
        [content setAutoresizesSubviews:YES];
        [content setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin];
        [content addSubview:logo];
        [content addSubview:copy];
        [content addSubview:locationPrompt];
        
        [cameraCollectionBrowser.view setAutoresizesSubviews:YES];
        [cameraCollectionBrowser.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin];
        [cameraCollectionBrowser.view setContentMode:UIViewContentModeScaleAspectFit];
        [cameraCollectionBrowser.view addSubview:content];
        
        [viewControllers addObject:cameraCollectionBrowser];      
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"view controllers: %@", viewControllers);
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {                       
                // Assign iPad tabs
                [self updateTabBarController:tbc];
            } else {
                // Assign iPhone / iPod Touch buttons
                [gvc.gridView reloadData];
                NSLog(@"assign iphone / ipod buttons");
            }
        });            
        
        
    }
}

- (void)createTabBarControllerViews {
    [viewControllers removeAllObjects];

    // Add Home / Recent / Favorites button    
    CollectionBrowser *vcHome = [[CollectionBrowser alloc] initWithCollection:[NSDictionary dictionaryWithObjectsAndKeys:history, @"Recent", favorites, @"Favorites", nil]];
    vcHome.disableSecondaryDataSource = YES;
    vcHome.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"Home" image:[UIImage imageNamed:@"Home"]];    
    vcHome.ng_tabBarItem.mediaIndex = @"Home";
#ifndef BLANKSLATE        
    vcHome.title = @"Home";
    [vcHome setEmptyText:@"Thanks again for your help testing this app out! I'm hopeful that this version is pretty close to final, so now is the time I really, really need your help. Take a look at it and please give me any feedback you have, especially negative feedback, as soon as you can. You should have seen the walkthrough instructions already, but if you need to see them again just tap on the life preserver icon in the lower left.\n\nThanks again!\nandy"];
    
    UILabel *logo = [[UILabel alloc] init];
    NSString *logoText = [sharedAppDelegate longAppName];
    UIFont *logoFont = [UIFont fontWithName:@"HoneyScript-SemiBold" size:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad?45.0f:36.0f)];
    [logo setText:logoText];
    [logo setFont:logoFont];
    [logo setTextColor:[UIColor darkGrayColor]];
    [logo setBackgroundColor:[UIColor clearColor]];
    [logo setShadowColor:[UIColor whiteColor]];
    [logo setShadowOffset:CGSizeMake(0, -0.5)];
    
    
    CGRect frame = logo.frame;
    frame.origin.x = 50;
    frame.origin.y = 80;
    [logo setFrame:frame];
    [logo sizeToFit];
    
    [vcHome setIntro:logo];
#endif        

    [viewControllers addObject:vcHome];


#ifndef BLANKSLATE        
    // Add buttons for each media collection
    NSLog(@"starting loop");
    for (NSString* key in mediaIndex.collections) {
        CollectionBrowser *vc = [[CollectionBrowser alloc] initWithCollection:[NSDictionary dictionaryWithObjectsAndKeys:[[mediaIndex.collections objectForKey:key] objectForKey:@"media"], [[mediaIndex.collections objectForKey:key] objectForKey:@"title"], nil]];
        UIImage* image = [UIImage imageNamed:key];
        vc.ng_tabBarItem = [NGTabBarItem itemWithTitle:[[mediaIndex.collections objectForKey:key] objectForKey:@"title"] image:image];    
        NSLog(@"looking for image named %@", key);
        vc.ng_tabBarItem.mediaIndex = key;
        vc.title = key;
        [viewControllers addObject:vc];
    }
    NSLog(@"ending loop");
    
    
    // Check the Documents folder for media shared via iTunes sharing
    NSLog(@"searching Documents");
    NSArray *validExtensions = [NSArray arrayWithObjects:@"mp4", @"mov", @"qt", @"3gp", @"3gpp", nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSMutableArray* iTunesSharedCollection = [[NSMutableArray alloc] init];    
    
    for (NSString* filename in [fileManager contentsOfDirectoryAtPath:[paths objectAtIndex:0] error:NULL]) if ([validExtensions containsObject:[filename pathExtension]]) {
        
        NSMutableDictionary* details = [NSMutableDictionary dictionaryWithObjectsAndKeys:[[[filename stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "] capitalizedString], @"title", [NSURL fileURLWithPath:[[paths objectAtIndex:0] stringByAppendingPathComponent:filename]], @"url", nil];
        [iTunesSharedCollection addObject:details];
    }
    
    if (iTunesSharedCollection.count > 0) {        
        CollectionBrowser *vc = [[CollectionBrowser alloc] initWithCollection:[NSDictionary dictionaryWithObjectsAndKeys:iTunesSharedCollection, @"iTunes", nil]];
        vc.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"iTunes" image:[UIImage imageNamed:@"iTunesShared"]];    
        vc.ng_tabBarItem.mediaIndex = @"iTunesShared";
        vc.title = @"iTunes";
        [viewControllers addObject:vc];        
        
        NSLog(@"iTunes shared media: %@", iTunesSharedCollection);
    }
    
    // Check the camera roll
    [self checkLocationPermissions];
#else
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {                       
        // Assign iPad tabs
        [self updateTabBarController:tbc];
    } else {
        // Assign iPhone / iPod Touch buttons
        [gvc.gridView reloadData];
        NSLog(@"assign iphone / ipod buttons");
    }
    
#endif    
}

- (void)updateTabBarController:(NGTabBarController*)controller {	
    // Add button for settings gear
    [TestFlight passCheckpoint:@"Media Loaded"];
    [controller setViewControllers:viewControllers];
}

- (void) settingsChanged {
    [[NSUserDefaults standardUserDefaults] synchronize];     
    [tbc.view setNeedsLayout];
    [[(CollectionBrowser*)tbc.selectedViewController tv] reloadData];
    [gvc.gridView reloadData];
}

- (void)playVideoWithURL:(AVURLAsset *)url andTitle:(NSString*)title {
    if (!playbackViewController)
    {
        playbackViewController = [[PlaybackViewController alloc] init];
    }
    
    [playbackViewController setURL:url.URL];
    
    UIBarButtonItem* done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(dismissVideoPlayer)];
    
    [playbackViewController setVideotitle:title];
    
    videoPlaybackController = [[UINavigationController alloc] initWithRootViewController:playbackViewController];
    [videoPlaybackController setTitle:title];
    NSLog(@"Setting title: %@", title);
    [videoPlaybackController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    playbackViewController.navigationItem.leftBarButtonItem = done;
    
    [self.window.rootViewController presentViewController:videoPlaybackController animated:YES completion:nil];
    
}

- (void) dismissVideoPlayer {
    NSLog(@"dismiss!");
    [videoPlaybackController dismissViewControllerAnimated:YES completion:nil];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifndef DEVELOPMENT
    [TestFlight takeOff:@"1271acd37624091e4a1afc0fc79d9a38_MTAwNzEwMjAxMi0wNi0xOCAxMzo1MDozNS40Nzg0NzA"];    
    [[LocalyticsSession sharedLocalyticsSession] startSession:@"52f16fd1c7e37fed5b0c353-fe2feb12-c869-11e1-4434-00ef75f32667"];
#ifdef TESTING
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#endif    
#endif
    
    
    // Set up application defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]; 
	NSDictionary *appDefaults = [[NSDictionary alloc] initWithObjectsAndKeys:
								 [NSNumber numberWithBool:NO], @"hideprotected",
                                 @"321", @"unlockcode",
                                 [NSNumber numberWithBool:NO], @"autolock",
                                 [NSNumber numberWithInt:NO], @"rotationlock",
                                 [NSNumber numberWithBool:NO], @"repeat", nil];
                                 
    [defaults registerDefaults:appDefaults];     
    
    mediaIndex = [[MediaLibrary alloc] init];
    currentIndex = 0;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self indexIPodLibrary];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {       
        // iPad Version
        
        // Create Vertical Tabbar        
        tbc = [[NGVTabBarController alloc] initWithDelegate:self];
        [tbc setAnimation:NGTabBarControllerAnimationNone];
        [tbc setTabBarPosition:NGTabBarPositionLeft];
        [tbc.tabBar setLayoutStrategy:NGTabBarLayoutStrategyStrungTogether];
        [tbc.tabBar setTintColor:[UIColor blackColor]];    
        [self createTabBarControllerViews];
        
        self.window.rootViewController = tbc;        
    } else {
        // Non-iPad version
        
        
        // Create the gridview...
        gvc = [GridViewController alloc];
        gvc.gridView.autoresizesSubviews = YES;
        gvc.gridView.delegate = self;
        gvc.gridView.dataSource = self;
        gvc.gridView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gridviewBg"]]; // [UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0];// colorWithPatternImage:[UIImage imageNamed:@"UIPinStripe"]];
        
        NSString *appName = [sharedAppDelegate shortAppName];
        UIFont *displayFont = [UIFont fontWithName:@"HoneyScript-SemiBold" size:30.f];
        CGRect frame = CGRectMake(0, 0, [appName sizeWithFont:displayFont].width , [appName sizeWithFont:displayFont].height);
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        label.backgroundColor = [UIColor clearColor];
        label.font = displayFont;
        label.textAlignment = UITextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.text = appName;
        // emboss in the same way as the native title
        [label setShadowColor:[UIColor darkGrayColor]];
        [label setShadowOffset:CGSizeMake(0, -0.5)];
        gvc.navigationItem.titleView = label;    
        
        UIImage *gearImage = [UIImage imageNamed:@"GearLittle"];
        UIImage *helpImage = [UIImage imageNamed:@"LifePreserverLittle"];
        
        UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:gearImage style:UIBarButtonItemStylePlain target:self action:@selector(pushSettings:)];
        UIBarButtonItem *flexspace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]; 
        UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithImage:helpImage style:UIBarButtonItemStylePlain target:self action:@selector(pushWalkthrough:)];

        // ...and put it in a NavigationController
        nc = [[UINavigationController alloc] initWithRootViewController:gvc];
        [nc setDelegate:self];
        [nc.toolbar setBarStyle:UIBarStyleBlackTranslucent];
        [gvc setToolbarItems:[NSArray arrayWithObjects:settingsButton,  flexspace, helpButton, nil]];
        
        self.window.rootViewController = nc;
        
        [self createTabBarControllerViews];        
        [gvc.gridView reloadData];
    }
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged) name:@"kAppSettingChanged" object:nil];
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];    
    
    return YES;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [navigationController setToolbarHidden:(viewController!=gvc) animated:YES];        
}

- (void)pushSettings:(id)sender {
    IASKAppSettingsViewController *appSettingsViewController = [[IASKAppSettingsViewController alloc] initWithNibName:@"IASKAppSettingsView" bundle:nil];
    appSettingsViewController.delegate = self;
    appSettingsViewController.showDoneButton = NO;
    
    [nc pushViewController:appSettingsViewController animated:YES];
}

- (void)pushWalkthrough:(id)sender {
    WelcomeViewController *welcomeController = [[WelcomeViewController alloc] initWithNibName:@"Welcome"];
    [welcomeController.navigationBar setTintColor:[UIColor colorWithRed:0.0/255.0f green:85.0f/255.0f blue:20.0f/255.0f alpha:1.0f]];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {                    
        [welcomeController setModalPresentationStyle:UIModalPresentationFormSheet];
        [welcomeController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [welcomeController setModalInPopover:YES];
    }
    
    [nc presentModalViewController:welcomeController animated:YES];    
}

- (NSArray*)viewControllersWithoutProtectedContent {
    NSMutableArray *vcs = [[NSMutableArray alloc] initWithArray:viewControllers];
    CollectionBrowser *vc;
    bool dobreak = false;
    for (int j=0; j<vcs.count;) {
         vc = [vcs objectAtIndex:j];
        if ([vc.title isEqualToString:@"Home"] ||
            [vc.title isEqualToString:@"Camera Roll"]) {
            j++;
            continue;
        }

        for (NSString *dsKey in vc.dataSource.allKeys) {
            for (int i=0; i<[[vc.dataSource objectForKey:dsKey] count];) {
                NSLog(@"%d, %d", j, i);
                if ([[[[vc.dataSource objectForKey:dsKey] objectAtIndex:i] objectForKey:@"hasProtectedContent"] compare:[NSNumber numberWithBool:NO]]==NSOrderedSame) {
                    dobreak = true;
                    break;            
                }
                i++;
            }
            if (dobreak) {
                dobreak = false;
                j++;
                break;
            }
            
            NSLog(@"removing: %@", vc.title);
            [vcs removeObjectAtIndex:j];            
        }
    }


    return [NSArray arrayWithArray:vcs];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveMarks];
#ifndef DEVELOPMENT
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];    
#endif
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self saveMarks];    
#ifndef DEVELOPMENT
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];    
#endif
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
#ifndef DEVELOPMENT
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];    
#endif
}


////////////////////////////////////////////////////////////////////////
#pragma mark - NGTabBarControllerDelegate
////////////////////////////////////////////////////////////////////////

- (CGSize)tabBarController:(NGTabBarController *)tabBarController sizeOfItemForViewController:(UIViewController *)viewController atIndex:(NSUInteger)index                  position:(NGTabBarPosition)position {
    BOOL hideProtected = [[NSUserDefaults standardUserDefaults] boolForKey:@"hideprotected"];    
    
    if (index>0 && 
        ![[[viewControllers objectAtIndex:index] title] isEqualToString:@"Camera Roll"] && 
        hideProtected && 
        ![[viewControllers objectAtIndex:index] hasUnprotectedContent]) {
        return CGSizeMake(0.0f, 0.0f);
    } else {
        return CGSizeMake(100.f, 60.f);
    }
}

- (void)tabBarController:(NGTabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index{
    currentIndex = index;    
}


#pragma mark -
#pragma mark Grid View Data Source

- (NSUInteger) numberOfItemsInGridView: (AQGridView *) aGridView
{
#ifdef BLANKSLATE
    return 0;
#else
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hideprotected"]) {
        int items = [self viewControllersWithoutProtectedContent].count;
        for (CollectionBrowser *vc in [self viewControllersWithoutProtectedContent]) {
                if (![vc.title isEqualToString:@"Home"] &&
                    ![vc.title isEqualToString:@"Camera Roll"] &&
                    (vc.dataSourceWithoutProtectedContent.count <= 0)) {
                    items--;
                }
        }
        return items;
    } else {
        return viewControllers.count;
    }
#endif
}

- (AQGridViewCell *) gridView: (AQGridView *) aGridView cellForItemAtIndex: (NSUInteger) index
{
    GridViewCell * cell = (GridViewCell *)[gvc.gridView dequeueReusableCellWithIdentifier:@"gvcell"];
    if ( cell == nil ) {
        CGRect cellSize;
        if (viewControllers.count <= 8) {
            cellSize = CGRectMake(0.0, 0.0, 160.0, 93.0);            
        } else {
            cellSize = CGRectMake(0.0, 0.0, 106.0, 70.0);
        }

        cell = [[GridViewCell alloc] initWithFrame:cellSize reuseIdentifier:@"gvcell"];
        [cell addBorders];        
    }
    
    CollectionBrowser *vc;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hideprotected"]) {
        vc = [[self viewControllersWithoutProtectedContent] objectAtIndex:index];
    } else {
        vc = [viewControllers objectAtIndex:index];
    }
    
    UIImage *img = [[vc ng_tabBarItem] image];
    NSString *caption = [[vc ng_tabBarItem] title];
    [cell setImage:img];
    [cell setTitle:caption];
        
    return cell;
}

- (void) gridView: (AQGridView *) gridView didSelectItemAtIndex: (NSUInteger) index {
    UIViewController *vc;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hideprotected"]) {
        vc = [[self viewControllersWithoutProtectedContent] objectAtIndex:index];
    } else {
        vc = [viewControllers objectAtIndex:index];
    }
    
    [nc pushViewController:vc animated:YES];
    [gridView deselectItemAtIndex:index animated:YES];
}

- (CGSize) portraitGridCellSizeForGridView: (AQGridView *) aGridView
{
    if (([[NSUserDefaults standardUserDefaults] boolForKey:@"hideprotected"] && [[self viewControllersWithoutProtectedContent] count]) || 
        viewControllers.count <= 8 ) {
        return CGSizeMake(160.0, 93.0);        
    } else {        
        return CGSizeMake(106.0, 70.0);
    }
}


@end

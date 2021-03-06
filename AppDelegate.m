#import "AppDelegate.h"
#import "MediaLibrary.h"
#import "NGVTabBarController.h"
#import "GridViewController.h"
#import "GridViewCell.h"
#import "CollectionBrowser.h"
#import "CollectionTable.h"
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
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];        
    NSString *privDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/privdata"];    
    if (![[NSFileManager defaultManager] fileExistsAtPath:privDirectory isDirectory:nil]) {
        // Create the privdata folder
        if ([[NSFileManager defaultManager] createDirectoryAtPath:privDirectory withIntermediateDirectories:YES attributes:nil error:nil]) {
            // Move the marks.plist file if it exists in the Documents folder. Version 1.0.x used to keep it there
            [[NSFileManager defaultManager] moveItemAtPath:[documentsDirectory stringByAppendingPathComponent:@"marks.plist"] toPath:[privDirectory stringByAppendingPathComponent:@"marks.plist"] error:nil];
        }
    }
    
    NSString *path = [privDirectory stringByAppendingPathComponent:@"marks.plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:path]) {
        NSString *bundle = [[NSBundle mainBundle] pathForResource:@"marks" ofType:@"plist"];
        
        [fileManager copyItemAtPath:bundle toPath:path error:&error];
    }
    
    return path;
}

- (NSMutableDictionary*)loadMarks {
    NSString* path = [self getMarksPath];
    NSMutableDictionary *objects = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    
    if (![objects objectForKey:@"history"]) [objects setObject:[[NSMutableArray alloc] init] forKey:@"history"];
    if (![objects objectForKey:@"favorites"]) [objects setObject:[[NSMutableArray alloc] init] forKey:@"favorites"];    
    
    // Make sure history and favorites are updated for 1.1 compatability
    srand(time(NULL));         
    for (NSMutableDictionary* v in [objects objectForKey:@"history"]) {
        if (![v objectForKey:@"id"]) {
            [v setValue:[NSNumber numberWithInt:rand()%1000000] forKey:@"id"];
        }
    }

    for (NSMutableDictionary* v in [objects objectForKey:@"favorites"]) {
        if (![v objectForKey:@"id"]) {
            [v setValue:[NSNumber numberWithInt:rand()%1000000] forKey:@"id"];
        }
    }
    
    
    return objects;
}

- (void)saveMarks {
    NSString* path = [self getMarksPath];    
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    
    [data setObject:history forKey:@"history"];
    [data setObject:favorites forKey:@"favorites"];  
    [data writeToFile:path atomically:YES];
}

- (BOOL)logHistory:(NSDictionary *)item {
    for (NSDictionary* vid in history) if ([[vid objectForKey:@"url"] isEqual:[item objectForKey:@"url"]]) return NO;

    [history insertObject:item atIndex:0];
    if (history.count>3) {
        [history removeObjectsInRange:NSMakeRange(3, history.count - 3)];
    }
    
    NSLog(@"New history: %@", history);                    
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
                     NSString *URL = [[[asset valueForProperty:ALAssetPropertyURLs] valueForKey:uti] absoluteString];
                     NSString *title = [NSString stringWithFormat:@"%@ %i", NSLocalizedString(@"Video", nil), [cameraCollection count]+1];
                     
                     NSLog(@"video date: %@", [asset valueForProperty:ALAssetPropertyDate]);
                     NSMutableDictionary* details = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                     title, @"title", 
                                                     URL, @"url", 
                                                     [NSNumber numberWithDouble:[[asset valueForProperty:ALAssetPropertyDate] timeIntervalSince1970]], @"id",
                                                     nil];
                     NSLog(@"Found camera item %@ at %@", title, URL);                     
                     [cameraCollection addObject:details];
                 }
             }];
        }
        // group == nil signals we are done iterating.
        else {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"askedForLocation"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [TestFlight passCheckpoint:@"Location Approved"];
            
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
                    [cameraCollectionBrowser setDataSource:[NSDictionary dictionaryWithObjectsAndKeys:cameraCollection, NSLocalizedString(@"TITLE_CAMERAROLL", nil), nil]];
                    [cameraCollectionBrowser setEmptyText:nil];
                    [cameraCollectionBrowser.tv reloadData];
                } else {   
                    NSLog(@"i don't think this should ever get reached");
                    // We're being called from launch
                    NSLog(@"adding camera collection");
                    
                    cameraCollectionBrowser = [[CollectionBrowser alloc] init];  
                    cameraCollectionBrowser.disableSecondaryDataSource = YES;
                    cameraCollectionBrowser.ng_tabBarItem = [NGTabBarItem itemWithTitle:NSLocalizedString(@"TITLE_CAMERAROLL", nil) image:[UIImage imageNamed:@"CameraRoll"]];    
                    cameraCollectionBrowser.ng_tabBarItem.mediaIndex = @"CameraRoll";
                    cameraCollectionBrowser.title = NSLocalizedString(@"TITLE_CAMERAROLL", nil);
                    
                    [cameraCollectionBrowser setDataSource:[NSDictionary dictionaryWithObjectsAndKeys:cameraCollection, NSLocalizedString(@"TITLE_CAMERAROLL", nil), nil]];
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
        NSLog(@"error enumerating AssetLibrary groups %@\n", error);
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"askedForLocation"]) [TestFlight passCheckpoint:@"Location Denied"];        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"askedForLocation"];
        [[NSUserDefaults standardUserDefaults] synchronize];        

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
             NSString *logoText = NSLocalizedString(@"CAMERAROLL_ACCESS_DENIED", nil);
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
        NSString *logoText = NSLocalizedString(@"LOCATION_REQUEST_TITLE", nil);
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
                
        NSString *copyText = NSLocalizedString(@"LOCATION_REQUEST_INTRO", nil);
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
    CollectionBrowser *vcHome = [[CollectionBrowser alloc] initWithCollection:[NSDictionary dictionaryWithObjectsAndKeys:history, NSLocalizedString(@"RECENT", nil), favorites, NSLocalizedString(@"FAVORITES", nil), nil]];
    vcHome.disableSecondaryDataSource = YES;
    NSString *title;
#ifndef BLANKSLATE
    title = NSLocalizedString(@"TITLE_HOME", nil);
#endif
    vcHome.ng_tabBarItem = [NGTabBarItem itemWithTitle:title image:[UIImage imageNamed:@"Home"]];    
    vcHome.ng_tabBarItem.mediaIndex =title;
#ifndef BLANKSLATE        
    vcHome.title = NSLocalizedString(@"TITLE_HOME", nil);
    [vcHome setEmptyText:NSLocalizedString(@"WELCOME_MESSAGE", nil)];    
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
        vc.ng_tabBarItem.mediaIndex = key;
        vc.title = [[mediaIndex.collections objectForKey:key] objectForKey:@"title"];
        [viewControllers addObject:vc];
    }
    NSLog(@"ending loop");
    
    
    // Check the Documents folder for media shared via iTunes sharing
    NSArray *validExtensions = [NSArray arrayWithObjects:@"mp4", @"mov", @"qt", @"3gp", @"3gpp", @"m4v", nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSMutableArray* iTunesSharedCollection = [[NSMutableArray alloc] init];    
    
    for (NSString* filename in [fileManager contentsOfDirectoryAtPath:[paths objectAtIndex:0] error:NULL]) if ([validExtensions containsObject:[filename pathExtension]]) {
        
        NSMutableDictionary* details = [NSMutableDictionary dictionaryWithObjectsAndKeys:[[[filename stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "] capitalizedString], @"title", [[paths objectAtIndex:0] stringByAppendingPathComponent:filename], @"url", nil];
        [iTunesSharedCollection addObject:details];
    }
    
    if (iTunesSharedCollection.count > 0) {        
        CollectionBrowser *vc = [[CollectionBrowser alloc] initWithCollection:[NSDictionary dictionaryWithObjectsAndKeys:iTunesSharedCollection, NSLocalizedString(@"TITLE_ITUNES", nil), nil]];
        vc.ng_tabBarItem = [NGTabBarItem itemWithTitle:NSLocalizedString(@"TITLE_ITUNES", nil) image:[UIImage imageNamed:@"iTunesShared"]];    
        vc.ng_tabBarItem.mediaIndex = @"iTunesShared";
        vc.title = NSLocalizedString(@"TITLE_ITUNES", nil);
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
    
    UIBarButtonItem* done = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"DONE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(dismissVideoPlayer)];
    
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
                                 @"AVLayerVideoGravityResizeAspect", @"zoom",
                                 [NSNumber numberWithBool:NO], @"autolock",
                                 [NSNumber numberWithInt:NO], @"rotationlock",
                                 [NSNumber numberWithBool:NO], @"repeat", nil];
                                 
    [defaults registerDefaults:appDefaults];     
    
    mediaIndex = [[MediaLibrary alloc] init];
    currentIndex = 0;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [mediaIndex load];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {       
        // iPad Version
        
        // Create Vertical Tabbar        
        tbc = [[NGVTabBarController alloc] initWithDelegate:self];
        [tbc setAnimation:NGTabBarControllerAnimationNone];
        [tbc setTabBarPosition:NGTabBarPositionLeft];
        [tbc.tabBar setLayoutStrategy:NGTabBarLayoutStrategyStrungTogether];
        [tbc.tabBar.layer setShadowOffset:CGSizeMake(0, 0)];
        [tbc.tabBar.layer setShadowRadius:5];
        [tbc.tabBar.layer setShadowOpacity:0.8];
        [tbc.tabBar.layer setMasksToBounds:NO];
        [tbc.tabBar setClipsToBounds:NO];
        [tbc.tabBar.layer setZPosition:100.0];
        [tbc.tabBar setTintColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"TabBarControllerBg"]]];    
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
                
#ifndef BLANKSLATE        
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
#endif
        
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

- (BOOL)isFirstLaunch {
    BOOL fl;
    if ([[NSUserDefaults standardUserDefaults] valueForKey:@"lastVersionLaunched"] == nil) {
        fl = YES;
    } else {
        fl = NO;
    }
    [[NSUserDefaults standardUserDefaults] setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"lastVersionLaunched"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return fl;
}

- (BOOL)isFirstLaunchThisVersion {
    return NO;
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
        if ([vc.title isEqualToString:NSLocalizedString(@"TITLE_HOME", nil)] ||
            [vc.title isEqualToString:NSLocalizedString(@"TITLE_CAMERAROLL", nil)]) {
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
    [playbackViewController.mPlayer pause];
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
    // If playback screen is locked, start playback
    if ([playbackViewController.navigationController.navigationBar isHidden]) {
        [playbackViewController.mPlayer play];        
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark - NGTabBarControllerDelegate
////////////////////////////////////////////////////////////////////////

- (CGSize)tabBarController:(NGTabBarController *)tabBarController sizeOfItemForViewController:(UIViewController *)viewController atIndex:(NSUInteger)index                  position:(NGTabBarPosition)position {
    BOOL hideProtected = [[NSUserDefaults standardUserDefaults] boolForKey:@"hideprotected"];    
    
#ifdef BLANKSLATE
    return CGSizeMake(100.f, 0.0f);
#endif
    if (index>0 && 
        ![[[viewControllers objectAtIndex:index] title] isEqualToString:NSLocalizedString(@"TITLE_CAMERAROLL", nil)] && 
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
                if (![vc.title isEqualToString:NSLocalizedString(@"TITLE_HOME", nil)] &&
                    ![vc.title isEqualToString:NSLocalizedString(@"TITLE_CAMERAROLL", nil)] &&
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

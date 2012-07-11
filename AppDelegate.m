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
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/QuartzCore.h>

@implementation AppDelegate

@synthesize window = _window;
@synthesize currentIndex, mediaIndex, favorites, history, videoPlaybackController, nc;

- (AppDelegate*) init {
    if (!assetsLibrary) assetsLibrary = [[ALAssetsLibrary alloc] init];
    if (!viewControllers) viewControllers = [[NSMutableArray alloc] init];
    history = [[self loadMarks] objectForKey:@"history"];
    favorites = [[self loadMarks] objectForKey:@"favorites"];;
    
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
    
    NSLog(@"saving marks %@ to %@. Successful? %@", data, path, ([data writeToFile:path atomically:YES]?@"yes":@"no"));    
}

- (BOOL)logHistory:(NSDictionary *)item {
    for (NSDictionary* vid in history) if ([[vid objectForKey:@"url"] isEqual:[item objectForKey:@"url"]]) return NO;

    [history insertObject:item atIndex:0];
    history = [NSMutableArray arrayWithArray:[history subarrayWithRange:NSMakeRange(0, history.count<3?history.count:3)]];
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
    BOOL hideProtected = [[NSUserDefaults standardUserDefaults] boolForKey:@"hideprotected"];    
    
    // Take a look at the movies library and determine media types
    MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeAnyVideo] forProperty:MPMediaItemPropertyMediaType];    
    MPMediaQuery *videoQuery = [[MPMediaQuery alloc] initWithFilterPredicates:[NSSet setWithObject:predicate]];    
    NSArray* videos = [videoQuery items];    
    
    // Iterate through videos to build index
    NSInteger mediaType;
	for (MPMediaItem *video in videos) {  
        if (!(hideProtected && (([video valueForProperty:MPMediaItemPropertyAssetURL]==nil) || [[AVAsset assetWithURL:[video valueForProperty:MPMediaItemPropertyAssetURL]] hasProtectedContent]))) {
            [mediaIndex addItem:video];        
            
            mediaType = [[video valueForProperty:MPMediaItemPropertyMediaType] integerValue];
            if (mediaType & MPMediaTypeVideoITunesU) [mediaIndex addItem:video toCollection:@"ITunesU" withCollectionTitle:@"iTunes U"];
            if (mediaType & MPMediaTypeMusicVideo) [mediaIndex addItem:video toCollection:@"MusicVideo" withCollectionTitle:@"Music Videos"];
            if (mediaType & MPMediaTypeVideoPodcast) [mediaIndex addItem:video toCollection:@"VideoPodcast" withCollectionTitle:@"Podcasts"];
            if (mediaType & MPMediaTypeTVShow) [mediaIndex addItem:video toCollection:@"TVShow" withCollectionTitle:@"TV Shows"];
            if (mediaType & MPMediaTypeMovie) [mediaIndex addItem:video toCollection:@"Movie" withCollectionTitle:@"Movies"];
        }
    }    
}

- (void)indexCameraRoll {
    NSLog(@"checking camera roll");
    ALAssetsLibrary *assetLibrary = assetsLibrary;
    NSMutableArray* cameraCollection = [[NSMutableArray alloc] init];        
    NSLog(@"%@", assetLibrary);
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
            if (cameraCollection.count > 0) {    
                NSLog(@"adding camera collection");
                CollectionBrowser *vc = [[CollectionBrowser alloc] initWithCollection:[NSDictionary dictionaryWithObjectsAndKeys:cameraCollection, @"Camera Roll", nil] andOwner:tbc];
                vc.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"Camera Roll" image:[UIImage imageNamed:@"CameraRoll"]];    
                vc.ng_tabBarItem.mediaIndex = @"CameraRoll";
                vc.title = @"Camera Roll";
                [viewControllers addObject:vc];        
            } else {
                NSLog(@"skipping camera collection");
            }
            
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
    } failureBlock:^(NSError *error) {
        NSLog(@"error enumerating AssetLibrary groups %@\n", error);
    }];    
}

- (void)createTabBarControllerViews {
    [viewControllers removeAllObjects];

    // Add Home / Recent / Favorites button    
    CollectionBrowser *vcHome = [[CollectionBrowser alloc] initWithCollection:[NSDictionary dictionaryWithObjectsAndKeys:[history subarrayWithRange:NSMakeRange(0, history.count<3?history.count:3)], @"Recent", favorites, @"Favorites", nil] andOwner:tbc];
    vcHome.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"Home" image:[UIImage imageNamed:@"Home"]];    
    vcHome.ng_tabBarItem.mediaIndex = @"Home";
    vcHome.title = @"Home";
    
    UILabel* introTextCopy = [[UILabel alloc] init];
    [introTextCopy setFont:[UIFont fontWithName:@"Trebuchet MS" size:14.0f]];
    [introTextCopy setTextColor:[UIColor darkGrayColor]];
    [introTextCopy setBackgroundColor:[UIColor clearColor]];
    [introTextCopy setNumberOfLines:0]; // Enable word wrapping
    [introTextCopy setText:@"Welcome to LittleFingers Video Player! Thank you for agreeing to help test this app out. On the left, you will see icons for each of the categories of videos on your device. As you use this app, the 'Home' tab will show you the most recently viewed videos as well as videos you have flagged as your favorites.\n\nIf you come across any problems, please let me know by tapping the bug button in the lower left corner. There will undoubtedly be many bugs and crashes, and the more you tell me about what happened when you did run into trouble, the better I can make the final version of the app.\n\nOf course, please feel free to let me know about any other thoughts or suggestions you have, and thanks again!"];
    [vcHome setIntro:introTextCopy];

    [viewControllers addObject:vcHome];


    
    // Add buttons for each media collection
    NSLog(@"starting loop");
    for (NSString* key in mediaIndex.collections) {
        CollectionBrowser *vc = [[CollectionBrowser alloc] initWithCollection:[NSDictionary dictionaryWithObjectsAndKeys:[[mediaIndex.collections objectForKey:key] objectForKey:@"media"], [[mediaIndex.collections objectForKey:key] objectForKey:@"title"], nil] andOwner:tbc];
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
        CollectionBrowser *vc = [[CollectionBrowser alloc] initWithCollection:[NSDictionary dictionaryWithObjectsAndKeys:iTunesSharedCollection, @"iTunes", nil] andOwner:tbc];
        vc.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"iTunes" image:[UIImage imageNamed:@"iTunesShared"]];    
        vc.ng_tabBarItem.mediaIndex = @"iTunesShared";
        vc.title = @"iTunes";
        [viewControllers addObject:vc];        
        
        NSLog(@"iTunes shared media: %@", iTunesSharedCollection);
    }
    
    // Check the camera roll
    [self indexCameraRoll];
}

- (void)updateTabBarController:(NGTabBarController*)controller {	
    // Add button for settings gear
    [TestFlight passCheckpoint:@"Media Loaded"];
    [controller setViewControllers:viewControllers];
}

- (void) settingsChanged {
    NSLog(@"settings changed!");
    [[NSUserDefaults standardUserDefaults] synchronize];     
    //todo: reload tabs and content if "hide protected" has changed
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
								 [NSNumber numberWithBool:YES], @"hideprotected",
                                 @"321", @"unlockcode",
                                 [NSNumber numberWithBool:NO], @"autolock",
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
        gvc.gridView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"UIPinStripe"]];
        
        NSString *appName = @"LittleFingers";
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

        UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(pushSettings:)];
        [gvc.navigationItem setRightBarButtonItem:settingsButton];        
        
        // ...and put it in a NavigationController
        nc = [[UINavigationController alloc] initWithRootViewController:gvc];
        
        self.window.rootViewController = nc;
        
        [self createTabBarControllerViews];        
        [gvc.gridView reloadData];
    }
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];    
    
    return YES;
}

- (void)pushSettings:(id)sender {
    NSLog(@"pushed!");
    IASKAppSettingsViewController *appSettingsViewController = [[IASKAppSettingsViewController alloc] initWithNibName:@"IASKAppSettingsView" bundle:nil];
    appSettingsViewController.delegate = self;
    appSettingsViewController.showDoneButton = NO;
    
    [nc pushViewController:appSettingsViewController animated:YES];
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
    if (NGTabBarIsVertical(position)) {
        return CGSizeMake(100.f, 60.f);
    } else {
        return CGSizeMake(60.f, 49.f);
    }
}

- (void)tabBarController:(NGTabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index{
    currentIndex = index;    
}


#pragma mark -
#pragma mark Grid View Data Source

- (NSUInteger) numberOfItemsInGridView: (AQGridView *) aGridView
{
    return viewControllers.count;
}

- (AQGridViewCell *) gridView: (AQGridView *) aGridView cellForItemAtIndex: (NSUInteger) index
{
    GridViewCell * cell = (GridViewCell *)[gvc.gridView dequeueReusableCellWithIdentifier:@"gvcell"];
    if ( cell == nil ) {
        CGRect cellSize;
        if (viewControllers.count <= 4) {
            cellSize = CGRectMake(0.0, 0.0, 140.0, 100.0);            
        } else {
            cellSize = CGRectMake(0.0, 0.0, 100.0, 70.0);
        }

        cell = [[GridViewCell alloc] initWithFrame:cellSize reuseIdentifier:@"gvcell"];
    }
    
    UIImage *img = [[[viewControllers objectAtIndex:index] ng_tabBarItem] image];
    NSString *caption = [[[viewControllers objectAtIndex:index] ng_tabBarItem] title];
    [cell setImage:img];
    [cell setTitle:caption];

    [cell.layer setShadowColor:[UIColor lightGrayColor].CGColor];
    [cell.layer setShadowRadius:5.0];
    [cell.layer setShadowOpacity:1.0];
    [cell.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    
/*    
    [cell.layer setCornerRadius:10];
    [cell.layer setMasksToBounds:NO];
    [cell setClipsToBounds:NO];
*/ 
    
    cell.layer.borderWidth = 1.0f;
    cell.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    return cell;
}

- (void) gridView: (AQGridView *) gridView didSelectItemAtIndex: (NSUInteger) index {
    [nc pushViewController:[viewControllers objectAtIndex:index] animated:YES];
    [gridView deselectItemAtIndex:index animated:YES];
}

- (CGSize) portraitGridCellSizeForGridView: (AQGridView *) aGridView
{
    if (viewControllers.count <= 4 ) {
        return CGSizeMake(160.0, 120.0);        
    } else {        
        return CGSizeMake(100.0, 80.0);
    }
}


#pragma mark -
- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForKey:(NSString*)key {
    
	if ([key isEqualToString:@"ButtonDemoAction1"]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Demo Action 1 called" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
	} else {
		NSString *newTitle = [[[NSUserDefaults standardUserDefaults] objectForKey:key] isEqualToString:@"Logout"] ? @"Login" : @"Logout";
		[[NSUserDefaults standardUserDefaults] setObject:newTitle forKey:key];
	}
}





@end

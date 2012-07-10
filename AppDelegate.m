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
#import "CollectionBrowser.h"
#import "PlaybackViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>

@implementation AppDelegate

@synthesize window = _window;
@synthesize currentIndex, mediaIndex, favorites, history, videoPlaybackController;

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
                vc.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"Camera Roll" image:[UIImage imageNamed:@"film"]];    
                vc.ng_tabBarItem.mediaIndex = @"CameraRoll";
                [viewControllers addObject:vc];        
            } else {
                NSLog(@"skipping camera collection");
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateTabBarController:tbc];
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
    vcHome.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"Home" image:[UIImage imageNamed:@"house"]];    
    vcHome.ng_tabBarItem.mediaIndex = @"Home";
    
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
        vc.ng_tabBarItem = [NGTabBarItem itemWithTitle:[[mediaIndex.collections objectForKey:key] objectForKey:@"title"] image:[UIImage imageNamed:key]];    
        vc.ng_tabBarItem.mediaIndex = key;
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
        [tbc.tabBar setTintColor:[UIColor redColor]];    
        [self createTabBarControllerViews];
        
        self.window.rootViewController = tbc;        
    } else {
        // Non-iPad version
        
    }
    
    self.window.rootViewController = tbc;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];    
    
    return YES;
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
    NSLog(@"seleted tab: %d", index);
    
    currentIndex = index;    
}


#pragma mark UITextViewDelegate (for CustomViewCell)
- (void)textViewDidChange:(UITextView *)textView {
/*    
    [[NSUserDefaults standardUserDefaults] setObject:textView.text forKey:@"customCell"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kIASKAppSettingChanged object:@"customCell"];
*/
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

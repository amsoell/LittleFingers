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

@implementation AppDelegate

@synthesize window = _window;
@synthesize currentIndex, mediaIndex, favorites, history;

- (AppDelegate*) init {
    if (!assetsLibrary) assetsLibrary = [[ALAssetsLibrary alloc] init];
    if (!viewControllers) viewControllers = [[NSMutableArray alloc] init];
    history = [[self loadMarks] objectForKey:@"history"];
    favorites = [[self loadMarks] objectForKey:@"favorites"];;
    
    return [super init];
}

- (NSString*)getMarksPath {
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //1
    NSString *documentsDirectory = [paths objectAtIndex:0]; //2
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"marks.plist"]; //3
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath: path]) {
        NSString *bundle = [[NSBundle mainBundle] pathForResource:@"marks" ofType:@"plist"]; //5
        
        [fileManager copyItemAtPath:bundle toPath:path error:&error]; //6
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
            NSLog(@"adding asset %@ at %@", [video valueForProperty:MPMediaItemPropertyTitle], [video valueForProperty:MPMediaItemPropertyAssetURL]);
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

- (void)createTabBarControllerViews:(NGTabBarController*)controller {
    [viewControllers removeAllObjects];

    // Add Home / Recent / Favorites button    
    UIViewController *vcHome = [[UIViewController alloc] initWithNibName:nil bundle:nil]; 
    vcHome.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"Home" image:[UIImage imageNamed:@"house"]];    
    [vcHome.view setBackgroundColor:[UIColor lightGrayColor]]; 
    [viewControllers addObject:vcHome];
    
    // Add buttons for each media collection
    NSLog(@"starting loop");
    for (NSString* key in mediaIndex.collections) {
        CollectionBrowser *vc = [[CollectionBrowser alloc] initWithCollection:[[mediaIndex.collections objectForKey:key] objectForKey:@"media"] andOwner:controller];
        vc.ng_tabBarItem = [NGTabBarItem itemWithTitle:[[mediaIndex.collections objectForKey:key] objectForKey:@"title"] image:[UIImage imageNamed:key]];    
        vc.ng_tabBarItem.mediaIndex = key;
        [viewControllers addObject:vc];
    }
    NSLog(@"ending loop");
    
    
    // Check the Documents folder for media shared via iTunes sharing
    NSLog(@"searching Documents");
    NSArray *validExtensions = [NSArray arrayWithObjects:@"mp4", nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSMutableArray* iTunesSharedCollection = [[NSMutableArray alloc] init];    
    
    for (NSString* filename in [fileManager contentsOfDirectoryAtPath:[paths objectAtIndex:0] error:NULL]) if ([validExtensions containsObject:[filename pathExtension]]) {
        
        NSMutableDictionary* details = [NSMutableDictionary dictionaryWithObjectsAndKeys:[[[filename stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "] capitalizedString], @"title", [NSURL fileURLWithPath:[[paths objectAtIndex:0] stringByAppendingPathComponent:filename]], @"url", nil];
        [iTunesSharedCollection addObject:details];
    }
    
    if (iTunesSharedCollection.count > 0) {        
        CollectionBrowser *vc = [[CollectionBrowser alloc] initWithCollection:iTunesSharedCollection andOwner:controller];
        vc.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"iTunes" image:[UIImage imageNamed:@"iTunesShared"]];    
        vc.ng_tabBarItem.mediaIndex = @"iTunesShared";
        [viewControllers addObject:vc];        
        
        NSLog(@"iTunes shared media: %@", iTunesSharedCollection);
    }
    
    // Check the camera roll
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
                CollectionBrowser *vc = [[CollectionBrowser alloc] initWithCollection:cameraCollection andOwner:controller];
                vc.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"Camera Roll" image:[UIImage imageNamed:@"film"]];    
                vc.ng_tabBarItem.mediaIndex = @"CameraRoll";
                [viewControllers addObject:vc];        
            } else {
                NSLog(@"skipping camera collection");
            }
            
			dispatch_async(dispatch_get_main_queue(), ^{
				[self updateTabBarController:controller];
			});            
		}
	} failureBlock:^(NSError *error) {
        NSLog(@"error enumerating AssetLibrary groups %@\n", error);
    }];
}

- (void)updateTabBarController:(NGTabBarController*)controller {	
    // Add button for settings gear
        
    [controller setViewControllers:viewControllers];
}

- (void) settingsChanged {
    NSLog(@"settings changed!");
    [[NSUserDefaults standardUserDefaults] synchronize];     
    //todo: reload tabs and content if "hide protected" has changed
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    mediaIndex = [[MediaLibrary alloc] init];
    currentIndex = 0;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self indexIPodLibrary];
            
    // Create Vertical Tabbar        
    tbc = [[NGVTabBarController alloc] initWithDelegate:self];
    [tbc setAnimation:NGTabBarControllerAnimationNone];
    [tbc setTabBarPosition:NGTabBarPositionLeft];
    [tbc.tabBar setLayoutStrategy:NGTabBarLayoutStrategyStrungTogether];
    [tbc.tabBar setTintColor:[UIColor redColor]];    
    [self createTabBarControllerViews:tbc];
    
    self.window.rootViewController = tbc;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];    
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveMarks];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self saveMarks];    
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
    if (index == 0) {
        tbhistory = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, viewController.view.frame.size.width, 200) style:UITableViewStyleGrouped];
        [tbhistory setDelegate:self];
        [tbhistory setDataSource:self];        
        
        tbfavorite = [[UITableView alloc] initWithFrame:CGRectMake(0, 200, viewController.view.frame.size.width, 400) style:UITableViewStyleGrouped];
        [tbfavorite setDelegate:self];
        [tbfavorite setDataSource:self];        
        
        [viewController.view addSubview:tbfavorite];
        [viewController.view addSubview:tbhistory];
    }
    
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
#pragma mark TableView Delegate


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"cell"];      
    NSDictionary *item = [history objectAtIndex:indexPath.row];    
    [cell.textLabel setText:[item objectForKey:@"title"]];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == tbfavorite) {
        return favorites.count;
    } else {
        return history.count>3?3:history.count;
    }
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == tbfavorite) {
        return @"Favorites";
    } else {
        return @"Recent";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Log it in history
    [[sharedAppDelegate history] insertObject:[NSDictionary dictionaryWithDictionary:[favorites objectAtIndex:indexPath.row]] atIndex:0];
    NSLog(@"posthistory: %@", [sharedAppDelegate history]);
    
//    if (tableView == tbfavorite) {    
    //AVURLAsset* urlAsset = [[AVURLAsset alloc] initWithURL:[[favorites objectAtIndex:indexPath.row] objectForKey:@"url"] options:nil];
/*
	if (urlAsset) {
        NSLog(@"Playing from asset URL");
		if (!playbackViewController)
		{
			playbackViewController = [[PlaybackViewController alloc] init];
		}
		
		[playbackViewController setURL:urlAsset.URL];
        
        UIBarButtonItem* done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        
        [playbackViewController setVideotitle:[[dataSource objectAtIndex:indexPath.row] objectForKey:@"title"]];
		
        videoPlaybackController = [[UINavigationController alloc] initWithRootViewController:playbackViewController];
        [videoPlaybackController setTitle:[[dataSource objectAtIndex:indexPath.row] objectForKey:@"title"]];
        NSLog(@"Setting title: %@", [[dataSource objectAtIndex:indexPath.row] objectForKey:@"title"]);
        [videoPlaybackController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
        playbackViewController.navigationItem.leftBarButtonItem = done;
        
		[owner presentViewController:videoPlaybackController animated:YES completion:nil];
	} else if (playbackViewController) {
		[playbackViewController setURL:nil];
	}
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

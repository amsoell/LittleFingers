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
#import "IASKSpecifier.h"
#import "IASKSettingsReader.h"
#import "CollectionBrowser.h"
#import "PlaybackViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@implementation AppDelegate

@synthesize window = _window;
@synthesize currentIndex, mediaIndex;

@synthesize appSettingsViewController;

- (IASKAppSettingsViewController*)appSettingsViewController {
	if (!appSettingsViewController) {
		appSettingsViewController = [[IASKAppSettingsViewController alloc] initWithNibName:@"IASKAppSettingsView" bundle:nil];
		appSettingsViewController.delegate = self;
	}
	return appSettingsViewController;
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

- (void)refreshTabBarController:(NGTabBarController*)controller {
    // Add Home / Recent / Favorites button
    NSLog(@"refreshing tbc");
    UIViewController *vcHome = [[UIViewController alloc] initWithNibName:nil bundle:nil]; 
    vcHome.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"Home" image:[UIImage imageNamed:@"house"]];    
    [vcHome.view setBackgroundColor:[UIColor redColor]]; 
    NSMutableArray *viewController = [[NSMutableArray alloc] initWithObjects:vcHome, nil];    
    
    // Add buttons for each media collection
    NSLog(@"starting loop");
    for (NSString* key in mediaIndex.collections) {
        CollectionBrowser *vc = [[CollectionBrowser alloc] initWithCollection:[[mediaIndex.collections objectForKey:key] objectForKey:@"media"] andOwner:controller];
        vc.ng_tabBarItem = [NGTabBarItem itemWithTitle:[[mediaIndex.collections objectForKey:key] objectForKey:@"title"] image:[UIImage imageNamed:key]];    
        vc.ng_tabBarItem.mediaIndex = key;
        [viewController addObject:vc];
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
        [viewController addObject:vc];        
        
        NSLog(@"iTunes shared media: %@", iTunesSharedCollection);
    }
    
    // Add button for settings gear
    UIViewController *vcSettings = [[UIViewController alloc] initWithNibName:nil bundle:nil]; 
    vcSettings.ng_tabBarItem = [NGTabBarItem itemWithTitle:@"Settings" image:[UIImage imageNamed:@"gear"]];    
    [vcSettings.view setBackgroundColor:[UIColor redColor]]; 
    [viewController addObject:vcSettings];    
    
    // Assign view controller tab buttons to vertical tabbar
    [controller setViewControllers:viewController];
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
    [self refreshTabBarController:tbc];
    
    self.window.rootViewController = tbc;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged) name:kIASKAppSettingChanged object:nil];    
    
    return YES;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - NGTabBarControllerDelegate
////////////////////////////////////////////////////////////////////////

- (CGSize)tabBarController:(NGTabBarController *)tabBarController 
sizeOfItemForViewController:(UIViewController *)viewController
                   atIndex:(NSUInteger)index 
                  position:(NGTabBarPosition)position {
    if (NGTabBarIsVertical(position)) {
        return CGSizeMake(60.f, 60.f);
    } else {
        return CGSizeMake(60.f, 49.f);
    }
}

- (void)tabBarController:(NGTabBarController *)tabBarController 
 didSelectViewController:(UIViewController *)viewController
                 atIndex:(NSUInteger)index{
    NSLog(@"%@", [tabBarController.tabBar.items objectAtIndex:index]);    

    if (index == (tabBarController.tabBar.items.count - 1)) {  
 
        // Set up the settings view
        appSettingsViewController = [[IASKAppSettingsViewController alloc] initWithNibName:@"IASKAppSettingsView" bundle:nil];
        appSettingsViewController.delegate = self;
        appSettingsViewController.showDoneButton = NO;
        UINavigationController *aNavController = [[UINavigationController alloc] initWithRootViewController:appSettingsViewController];

        // Set up the popover
        NGTabBarItem* buttonLocation = [tabBarController.tabBar.items objectAtIndex:index];
        CGRect buttonFrame = CGRectMake(buttonLocation.frame.origin.x , buttonLocation.frame.origin.y, buttonLocation.frame.size.width, buttonLocation.frame.size.height);
        popover = [[UIPopoverController alloc] initWithContentViewController:aNavController];
        
        // Put the settings view in the popover
        [popover presentPopoverFromRect:buttonFrame inView:self.window.rootViewController.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
        [tabBarController setSelectedIndex:currentIndex];        

        
    } else {    
        currentIndex = index;    
    }
}

#pragma mark -
#pragma mark IASKAppSettingsViewControllerDelegate protocol
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
//    [self dismissModalViewControllerAnimated:YES];
	
	// your code here to reconfigure the app for changed settings
}

// optional delegate method for handling mail sending result
- (void)settingsViewController:(id<IASKViewController>)settingsViewController mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    if ( error != nil ) {
        // handle error here
    }
    
    if ( result == MFMailComposeResultSent ) {
        // your code here to handle this result
    }
    else if ( result == MFMailComposeResultCancelled ) {
        // ...
    }
    else if ( result == MFMailComposeResultSaved ) {
        // ...
    }
    else if ( result == MFMailComposeResultFailed ) {
        // ...
    }
}
- (CGFloat)settingsViewController:(id<IASKViewController>)settingsViewContoller 
                        tableView:(UITableView *)tableView 
        heightForHeaderForSection:(NSInteger)section {
    NSString* key = [settingsViewContoller.settingsReader keyForSection:section];
	if ([key isEqualToString:@"IASKLogo"]) {
		return [UIImage imageNamed:@"Icon.png"].size.height + 25;
	} else if ([key isEqualToString:@"IASKCustomHeaderStyle"]) {
		return 55.f;    
    }
	return 0;
}

- (UIView *)settingsViewController:(id<IASKViewController>)settingsViewContoller 
                         tableView:(UITableView *)tableView 
           viewForHeaderForSection:(NSInteger)section {
    NSString* key = [settingsViewContoller.settingsReader keyForSection:section];
	if ([key isEqualToString:@"IASKLogo"]) {
		UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Icon.png"]];
		imageView.contentMode = UIViewContentModeCenter;
		return imageView;
	} else if ([key isEqualToString:@"IASKCustomHeaderStyle"]) {
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.textColor = [UIColor redColor];
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0, 1);
        label.numberOfLines = 0;
        label.font = [UIFont boldSystemFontOfSize:16.f];
        
        //figure out the title from settingsbundle
        label.text = [settingsViewContoller.settingsReader titleForSection:section];
        
        return label;
    }
	return nil;
}


#pragma mark UITextViewDelegate (for CustomViewCell)
- (void)textViewDidChange:(UITextView *)textView {
    [[NSUserDefaults standardUserDefaults] setObject:textView.text forKey:@"customCell"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kIASKAppSettingChanged object:@"customCell"];
}

- (CGFloat)tableView:(UITableView*)tableView heightForSpecifier:(IASKSpecifier*)specifier {
	if ([specifier.key isEqualToString:@"customCell"]) {
		return 44*3;
	}
	return 0;
}

/*
- (UITableViewCell*)tableView:(UITableView*)tableView cellForSpecifier:(IASKSpecifier*)specifier {
	CustomViewCell *cell = (CustomViewCell*)[tableView dequeueReusableCellWithIdentifier:specifier.key];
	
	if (!cell) {
		cell = (CustomViewCell*)[[[NSBundle mainBundle] loadNibNamed:@"CustomViewCell" 
															   owner:self 
															 options:nil] objectAtIndex:0];
	}
	cell.textView.text= [[NSUserDefaults standardUserDefaults] objectForKey:specifier.key] != nil ? 
    [[NSUserDefaults standardUserDefaults] objectForKey:specifier.key] : [specifier defaultStringValue];
	cell.textView.delegate = self;
	[cell setNeedsLayout];
	return cell;
}
*/


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

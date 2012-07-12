//
//  CollectionBrowser.m
//  NGVerticalTabBarControllerDemo
//
//  Created by Andy Soell on 7/3/12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "AppDelegate.h"
#import "CollectionBrowser.h"
#import "PlaybackViewController.h"
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

@interface CollectionBrowser ()

@end

@implementation CollectionBrowser
@synthesize dataSource;
@synthesize tv, intro, videoPlaybackController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCollection:(NSDictionary *)collection {
    dataSource = collection;
    return [super init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        [self.tv setBackgroundView:nil];
        [self.tv setBackgroundView:[[UIView alloc] init]];
        [self.tv setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"UIPinStripe"]]];
    }
}

- (void)viewWillAppear:(BOOL)animated {

    if ((self.tv.tableHeaderView==nil) && (intro != nil)) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [intro.text sizeWithFont:[UIFont fontWithName:intro.font.familyName size:intro.font.pointSize] constrainedToSize:CGSizeMake(self.view.frame.size.width-100, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap].height+50)];
        [intro setFrame:CGRectMake(50, 0, self.view.frame.size.width-100, [intro.text sizeWithFont:[UIFont fontWithName:intro.font.familyName size:intro.font.pointSize] constrainedToSize:CGSizeMake(self.view.frame.size.width-100, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap].height+50)];
        [headerView addSubview:intro];
        self.tv.tableHeaderView = headerView;        
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"reloading data");
    [tv reloadData];    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL) toggleFavorite:(id)sender forEvent:(UIEvent*)event {
    NSIndexPath *indexPath = [tv indexPathForRowAtPoint:[[[event touchesForView:sender] anyObject] locationInView:tv]];    
    NSLog(@"toggle favorite! %@", indexPath);
    NSArray* itemKeys = [dataSource allKeys];    
    BOOL isFavorited = [sharedAppDelegate toggleFavorite:[[dataSource objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row]];
    
    [tv reloadData];
    
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Toggled Favorite"];
    [TestFlight passCheckpoint:@"Toggled Favorite"];
    return isFavorited;
}

#pragma mark -
#pragma mark TableView Delegate

- (UIImage*)dotImage {
    UIView *dotView = [[UIView alloc] initWithFrame:CGRectMake(0,0,4,4)];
    dotView.backgroundColor = [UIColor darkGrayColor];
    dotView.alpha = 0.2;
    dotView.layer.cornerRadius = 2;    
    UIGraphicsBeginImageContext(dotView.bounds.size);
    [dotView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *dotImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();    
    
    return dotImg;
}

- (UIImage*)starImage {
    UIImage* starImg = [UIImage imageNamed:@"star"]; 
    
    return starImg;
}

- (BOOL)isFavorite:(NSDictionary*)item {
    for (NSDictionary* i in [sharedAppDelegate favorites]) if ([i isEqualToDictionary:item]) return true;
    return false;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"cell"];      
    
    NSArray* itemKeys = [dataSource allKeys];
    NSDictionary *item = [[dataSource objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];    
    [cell.textLabel setText:[item objectForKey:@"title"]];
    
    UIButton *accessory = [UIButton buttonWithType:UIButtonTypeCustom];
    
    
    [accessory setImage:([self isFavorite:item]?[self starImage]:[self dotImage]) forState:UIControlStateNormal];
    accessory.frame = CGRectMake(0, 0, 30, 30);
    accessory.userInteractionEnabled = YES;
    [accessory addTarget:self action:@selector(toggleFavorite:forEvent:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = accessory;    
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray* itemKeys = [dataSource allKeys];
    
    return [[dataSource objectForKey:[itemKeys objectAtIndex:section]] count];
}


 //todo: implement section headers
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray* itemKeys = [dataSource allKeys];
    
    if ([[dataSource objectForKey:[itemKeys objectAtIndex:section]] count]>0) {
        return [[dataSource allKeys] objectAtIndex:section];
    } else {
        return @"";
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];    
    
    NSArray* itemKeys = [dataSource allKeys];            
    NSDictionary *item = [[dataSource objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    NSLog(@"item: %@", item);
    
    // Make sure it's playable
    if ([item objectForKey:@"hasProtectedContent"] && ([[item objectForKey:@"hasProtectedContent"] compare:[NSNumber numberWithBool:YES]] == NSOrderedSame)) {
        // DRM. Let user know they can hide these.
        //todo: let user hide them
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot play" message:@"Some videos purchased via iTunes cannot be played with LittleFingers. This is one of those videos." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];        
    } else if ([item objectForKey:@"url"] == nil) {
        // No URL. Probably in the cloud
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot play" message:@"This video must be downloaded from iCloud before it can be played in LittleFingers" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];        
    } else {
        
        // Log it in history
        [sharedAppDelegate logHistory:[NSDictionary dictionaryWithDictionary:item]];
        
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Played video" attributes:[NSDictionary dictionaryWithObject:[[NSDictionary dictionaryWithDictionary:item] objectForKey:@"title"] forKey:@"Title"]];
        [TestFlight passCheckpoint:@"Selected video"];
        
        AVURLAsset* urlAsset = [[AVURLAsset alloc] initWithURL:[item objectForKey:@"url"] options:nil];

        if (urlAsset) {
            NSLog(@"Playing from asset URL");
            [sharedAppDelegate playVideoWithURL:urlAsset andTitle:[item objectForKey:@"title"]];
    //	} else if (playbackViewController) {
    //		[playbackViewController setURL:nil];
        }        
    }
}

@end

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
#import "SPDeepCopy.h"
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

@interface CollectionBrowser ()

@end

@implementation CollectionBrowser
@synthesize dataSource, dataSourceWithoutProtectedContent;
@synthesize tv, intro, videoPlaybackController, emptyText;

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
    dataSourceWithoutProtectedContent =  [collection mutableDeepCopy];

    for (NSString *dsKey in dataSourceWithoutProtectedContent.allKeys) {
        for (int i=0; i<[[dataSourceWithoutProtectedContent objectForKey:dsKey] count];) {
            if ([[[[dataSourceWithoutProtectedContent objectForKey:dsKey] objectAtIndex:i] objectForKey:@"hasProtectedContent"] compare:[NSNumber numberWithBool:YES]]==NSOrderedSame) {
                [[dataSourceWithoutProtectedContent objectForKey:dsKey] removeObjectAtIndex:i];               
            } else {
                i++;
            }
        }
    }

    NSLog(@"datasource: %@, datasourcewitout: %@", dataSource, dataSourceWithoutProtectedContent);
    
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
        
        // Add logo
        CGRect newFrame = intro.frame;
        newFrame.origin.x = 50;
        newFrame.origin.y = 10;
        [intro setFrame:newFrame];

        UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, intro.frame.size.width+intro.frame.origin.x, intro.frame.size.height+intro.frame.origin.y)];        
        [headerView addSubview:intro];
        
        
        if (emptyText != nil) {
            NSInteger sections = tv.numberOfSections;
            NSInteger cellCount = 0;
            for (NSInteger i = 0; i < sections; i++) {
                cellCount += [tv numberOfRowsInSection:i];
            }
            
            if (cellCount <= 0) {
                // Add emptyText header
                UILabel* introText = [[UILabel alloc] init];
                [introText setTag:YES]; // tagged indicates it should be removed later
                [introText setText:emptyText];
                [introText setTextColor:[UIColor darkGrayColor]];
                [introText setBackgroundColor:[UIColor clearColor]];
                [introText setFont:[UIFont fontWithName:@"TrebuchetMS" size:16.0f]];
                NSLog(@"the width it: %f", self.view.frame.size.width);
                CGRect newFrame = introText.frame;
                newFrame.origin.x = 50;
                newFrame.origin.y = headerView.frame.size.height+10;
                newFrame.size = [emptyText sizeWithFont:introText.font constrainedToSize:CGSizeMake(self.view.frame.size.width-100, MAXFLOAT)];
                [introText setFrame:newFrame];
                [introText setNumberOfLines:0];
                [introText sizeToFit];
                
                [headerView addSubview:introText];
            }
        }
        
        [tv setTableHeaderView:headerView];
        [tv.tableHeaderView.layer setBorderColor:[UIColor greenColor].CGColor];
    }
    
    [tv reloadData];    
    if (tv.tableHeaderView!=nil) {
        NSInteger sections = tv.numberOfSections;
        NSInteger cellCount = 0;
        for (NSInteger i = 0; i < sections; i++) {
            cellCount += [tv numberOfRowsInSection:i];
        }
        
        if (cellCount > 0) {
            [self setEmptyText:nil];
            for (UILabel *v in tv.tableHeaderView.subviews) {
                if (v.tag) [v setText:@""];
            }
        }
    }
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"reloading data");
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
    NSArray* itemKeys = [[self dataSourceRef] allKeys];    
    BOOL isFavorited = [sharedAppDelegate toggleFavorite:[[[self dataSourceRef] objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row]];
    
    [tv reloadData];
    
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Toggled Favorite"];
    [TestFlight passCheckpoint:@"Toggled Favorite"];
    return isFavorited;
}

- (BOOL)hasUnprotectedContent {
    for (NSString *dsKey in [self dataSourceRef].allKeys) {
        for (int i=0; i<[[[self dataSourceRef] objectForKey:dsKey] count]; i++) {
            if ([[[[[self dataSourceRef] objectForKey:dsKey] objectAtIndex:i] objectForKey:@"hasProtectedContent"] compare:[NSNumber numberWithBool:NO]]==NSOrderedSame) {
                return YES;                
            }
        }
    }
    
    return NO;
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
    UIImage* starImg = [UIImage imageNamed:@"Star"]; 
    
    return starImg;
}

- (BOOL)isFavorite:(NSDictionary*)item {
    for (NSDictionary* i in [sharedAppDelegate favorites]) if ([i isEqualToDictionary:item]) return true;
    return false;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"cell"];      
    
    NSArray* itemKeys = [[self dataSourceRef] allKeys];
    NSDictionary *item = [[[self dataSourceRef] objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];    
    [cell.textLabel setText:[item objectForKey:@"title"]];
    
    UIButton *accessory = [UIButton buttonWithType:UIButtonTypeCustom];
    
    
    [accessory setImage:([self isFavorite:item]?[self starImage]:[self dotImage]) forState:UIControlStateNormal];
    accessory.frame = CGRectMake(0, 0, 30, 30);
    accessory.userInteractionEnabled = YES;
    [accessory addTarget:self action:@selector(toggleFavorite:forEvent:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = accessory;  
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hideprotected"] &&
        ([item objectForKey:@"hasProtectedContent"] && ([[item objectForKey:@"hasProtectedContent"] compare:[NSNumber numberWithBool:YES]] == NSOrderedSame))) 
        [cell.textLabel setText:@"**redacted**"];
    
    return cell;
}

- (NSDictionary*)dataSourceRef {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hideprotected"]) {
        return dataSourceWithoutProtectedContent;
    } else {     
        return dataSource;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self dataSourceRef].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray* itemKeys = [[self dataSourceRef] allKeys];
    
    return [[[self dataSourceRef] objectForKey:[itemKeys objectAtIndex:section]] count];
}


 //todo: implement section headers
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray* itemKeys = [[self dataSourceRef] allKeys];
    
    if ([[[self dataSourceRef] objectForKey:[itemKeys objectAtIndex:section]] count]>0) {
        return [[[self dataSourceRef] allKeys] objectAtIndex:section];
    } else {
        return @"";
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];    
    
    NSArray* itemKeys = [[self dataSourceRef] allKeys];            
    NSDictionary *item = [[[self dataSourceRef] objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    NSLog(@"item: %@", item);
    
    // Make sure it's playable
    if ([item objectForKey:@"hasProtectedContent"] && ([[item objectForKey:@"hasProtectedContent"] compare:[NSNumber numberWithBool:YES]] == NSOrderedSame)) {
        // DRM. Let user know they can hide these.
        //todo: let user hide them
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot play" message:[NSString stringWithFormat:@"Some videos purchased via iTunes cannot be played with %@. This is one of those videos.", [sharedAppDelegate shortAppName]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];        
    } else if ([item objectForKey:@"url"] == nil) {
        // No URL. Probably in the cloud
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot play" message:[NSString stringWithFormat:@"This video must be downloaded from iCloud before it can be played in %@", [sharedAppDelegate shortAppName]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
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

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

@interface CollectionBrowser ()

@end

@implementation CollectionBrowser
@synthesize dataSource;
@synthesize owner, videoPlaybackController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCollection:(NSDictionary *)collection andOwner:(UIViewController *)viewController {
    dataSource = collection;
    owner = viewController;
    return [super init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

- (void) dismiss {
    NSLog(@"dismiss!");
    [videoPlaybackController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark TableView Delegate


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"cell"];      
    
    NSArray* itemKeys = [dataSource allKeys];
    NSDictionary *item = [[dataSource objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];    
    
    [cell.textLabel setText:[item objectForKey:@"title"]];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray* itemKeys = [dataSource allKeys];
    
    return [[dataSource objectForKey:[itemKeys objectAtIndex:section]] count];
}


 //todo: implement section headers
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[dataSource allKeys] objectAtIndex:section];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Log it in history
    
    NSArray* itemKeys = [dataSource allKeys];    

    [[sharedAppDelegate history] insertObject:[NSDictionary dictionaryWithDictionary:[[dataSource objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row]] atIndex:0];
    NSLog(@"posthistory: %@", [sharedAppDelegate history]);
    
    AVURLAsset* urlAsset = [[AVURLAsset alloc] initWithURL:[[[dataSource objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] objectForKey:@"url"] options:nil];

	if (urlAsset) {
        NSLog(@"Playing from asset URL");
		if (!playbackViewController)
		{
			playbackViewController = [[PlaybackViewController alloc] init];
		}
		
		[playbackViewController setURL:urlAsset.URL];
        
        UIBarButtonItem* done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
        
        [playbackViewController setVideotitle:[[[dataSource objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] objectForKey:@"title"]];
		
        videoPlaybackController = [[UINavigationController alloc] initWithRootViewController:playbackViewController];
        [videoPlaybackController setTitle:[[[dataSource objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] objectForKey:@"title"]];
        NSLog(@"Setting title: %@", [[[dataSource objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] objectForKey:@"title"]);
        [videoPlaybackController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
        playbackViewController.navigationItem.leftBarButtonItem = done;
        
		[owner presentViewController:videoPlaybackController animated:YES completion:nil];
	} else if (playbackViewController) {
		[playbackViewController setURL:nil];
	}
}

@end

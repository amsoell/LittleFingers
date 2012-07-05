//
//  CollectionBrowser.m
//  NGVerticalTabBarControllerDemo
//
//  Created by Andy Soell on 7/3/12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

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

- (id)initWithCollection:(NSArray *)collection andOwner:(UIViewController *)viewController {
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

#pragma mark -
#pragma mark TableView Delegate


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"cell"];      
    
    NSDictionary *item = [dataSource objectAtIndex:indexPath.row];    
    
    [cell.textLabel setText:[item objectForKey:@"title"]];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return dataSource.count;
}

- (void) dismiss {
    NSLog(@"dismiss!");
    [videoPlaybackController dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AVURLAsset* urlAsset = [[AVURLAsset alloc] initWithURL:[[dataSource objectAtIndex:indexPath.row] objectForKey:@"url"] options:nil];

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
//        videoPlaybackController.navigationBar title = [[dataSource objectAtIndex:indexPath.row] objectForKey:@"title"];
        playbackViewController.navigationItem.leftBarButtonItem = done;
        
		[owner presentViewController:videoPlaybackController animated:YES completion:nil];
	} else if (playbackViewController) {
		[playbackViewController setURL:nil];
	}

}

@end

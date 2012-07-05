//
//  MediaLibrary.m
//  NGVerticalTabBarControllerDemo
//
//  Created by Andy Soell on 6/27/12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "MediaLibrary.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation MediaLibrary
@synthesize collections, items;

-(id)init {
    items = [[NSMutableArray alloc] init];
    collections = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)addItem:(MPMediaItem*)item toCollection:(NSString*)collection withCollectionTitle:(NSString*)title {
    NSMutableDictionary* details = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[item valueForProperty:MPMediaItemPropertyTitle], @"title", [item valueForProperty:MPMediaItemPropertyAssetURL], @"url", nil];
    
    // Add it to the collection index
    NSMutableDictionary* c = [collections objectForKey:collection];
    if (c == nil) c = [[NSMutableDictionary alloc] initWithObjectsAndKeys:title, @"title", nil];
    NSMutableArray *v = [c objectForKey:@"media"];
    if (v == nil) v = [[NSMutableArray alloc] init];
    [v addObject:details];
    [c setObject:v forKey:@"media"];
    [collections setObject:c forKey:collection];
}

- (void)addItem:(MPMediaItem*)item {
    NSMutableDictionary* details = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[item valueForProperty:MPMediaItemPropertyTitle], @"title", nil];
    
    // Add it to the master index
    [items addObject:details];
}

- (NSArray*)getMediaInCollection:(NSString*)collection {
    NSDictionary* c = [collections objectForKey:collection];
    
    return (c==nil?false:[c objectForKey:@"media"]);
}


@end

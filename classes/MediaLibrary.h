//
//  MediaLibrary.h
//  NGVerticalTabBarControllerDemo
//
//  Created by Andy Soell on 6/27/12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPMediaItem;
@interface MediaLibrary : NSObject {
    @public NSMutableArray* items;
    @public NSMutableDictionary* collections;
}

@property (nonatomic) NSMutableArray* items;
@property (nonatomic) NSMutableDictionary* collections;

- (void)addItem:(MPMediaItem*)item toCollection:(NSString*)collection withCollectionTitle:(NSString*)title;
- (void)addItem:(MPMediaItem*)item;
- (NSArray*)getMediaInCollection:(NSString*)collection;

@end

#import "MediaLibrary.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@implementation MediaLibrary
@synthesize collections, index;

-(id)init {
    collections = [[NSMutableDictionary alloc] init];
    index = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)addItem:(MPMediaItem*)item toCollection:(NSString*)collection withCollectionTitle:(NSString*)title {
    NSMutableDictionary* details = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                    [item valueForProperty:MPMediaItemPropertyPersistentID], @"id",
                                    [item valueForProperty:MPMediaItemPropertyTitle], @"title", 
                                    [item valueForProperty:MPMediaItemPropertyAlbumTitle], @"album",
                                    [[item valueForProperty:MPMediaItemPropertyAssetURL] absoluteString], @"url", 
                                    [NSNumber numberWithInt:[[item valueForProperty:MPMediaItemPropertyPlaybackDuration] intValue]], @"duration",
                                    [NSNumber numberWithBool:[[AVAsset assetWithURL:[item valueForProperty:MPMediaItemPropertyAssetURL]] hasProtectedContent]?YES:NO], @"hasProtectedContent",
                                    nil];
    
    NSLog(@"adding asset %@: %@", title, details);
    // Add it to the collection index
    NSMutableDictionary* c = [collections objectForKey:collection];
    if (c == nil) c = [[NSMutableDictionary alloc] initWithObjectsAndKeys:title, @"title", nil];
    NSMutableArray *v = [c objectForKey:@"media"];
    if (v == nil) v = [[NSMutableArray alloc] init];
    [v addObject:details];
    [c setObject:v forKey:@"media"];
    [collections setObject:c forKey:collection];
    
    [index setObject:details forKey:[details objectForKey:@"id"]];    
}


- (NSArray*)getMediaInCollection:(NSString*)collection {
    NSDictionary* c = [collections objectForKey:collection];
    
    return (c==nil?false:[c objectForKey:@"media"]);
}

- (NSArray*)mediaOnDevice {
    NSArray* videos;
    
    [[NSUserDefaults standardUserDefaults] synchronize];            
    // Take a look at the movies library and determine media types
    MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeAnyVideo] forProperty:MPMediaItemPropertyMediaType];    
    MPMediaQuery *videoQuery = [[MPMediaQuery alloc] initWithFilterPredicates:[NSSet setWithObject:predicate]];    
    videos = [videoQuery items];   

    return videos;
}

- (void)load {
    NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:@"mediaLibrary.plist"];
    collections = (path != nil ? [NSMutableDictionary dictionaryWithContentsOfFile:path] : nil );
    
    if (collections == nil) {
        collections = [[NSMutableDictionary alloc] init];
        index = [[NSMutableDictionary alloc] init];
    } else {
        [self buildIndex];        
    }

#if TARGET_IPHONE_SIMULATOR
#else
    [self purgeRemoved];
    [self addNew];
    [self save];
#endif
}

- (void)save {
#if TARGET_IPHONE_SIMULATOR
#else
    if ([collections writeToFile:[[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:@"mediaLibrary.plist"] atomically:NO]) {
        NSLog(@"Media Library saved successfully");
    } else {
        NSLog(@"COULDN'T SAVE MEDIA LIBRARY");
    }
#endif
}

- (void)buildIndex {
    for (NSString* collectionKey in collections.allKeys) {
        for (NSDictionary* video in [[collections objectForKey:collectionKey] objectForKey:@"media"]) {
            [index setObject:video forKey:[video objectForKey:@"id"]];
        }
    }
}

- (void)removeById:(NSNumber*)id {
    for (NSString* collectionKey in collections.allKeys) {
        [[[collections objectForKey:collectionKey] objectForKey:@"media"] removeObject:[index objectForKey:id]];
    }
    [index removeObjectForKey:id];
}

- (void)purgeRemoved {
    NSLog(@"purging");
    
    NSArray* videos = [self mediaOnDevice];
    NSMutableArray* pid = [[NSMutableArray alloc] init];
    // Iterate through videos to build index
	for (MPMediaItem *video in videos) {  
        [pid addObject:[video valueForProperty:MPMediaItemPropertyPersistentID]];
    }
    
    for (NSNumber* key in index.allKeys) {
        if (![pid containsObject:key]) {
            NSLog(@"removing: %@", key);
            [self removeById:key];        
        }            
    }
    
    // remove empty categories
    for (NSString* collectionKey in collections.allKeys) {
        // if cateogry is empty, remove it
        if ([[[collections objectForKey:collectionKey] objectForKey:@"media"] count] == 0) {
            [collections removeObjectForKey:collectionKey];
        }
    }
}

- (void)addNew {
    NSArray* videos = [self mediaOnDevice];
    NSInteger mediaType;
    
    // Iterate through videos to build index
	for (MPMediaItem *video in videos) {  
        if (![index.allKeys containsObject:[video valueForProperty:MPMediaItemPropertyPersistentID]]) {
            mediaType = [[video valueForProperty:MPMediaItemPropertyMediaType] integerValue];
            if (mediaType & MPMediaTypeVideoITunesU) [self addItem:video toCollection:@"ITunesU" withCollectionTitle:NSLocalizedString(@"TITLE_ITUNESU", nil)];
            if (mediaType & MPMediaTypeMusicVideo) [self addItem:video toCollection:@"MusicVideo" withCollectionTitle:NSLocalizedString(@"TITLE_MUSICVIDEOS", nil)];
            if (mediaType & MPMediaTypeVideoPodcast) [self addItem:video toCollection:@"VideoPodcast" withCollectionTitle:NSLocalizedString(@"TITLE_PODCASTS", nil)];
            if (mediaType & MPMediaTypeTVShow) [self addItem:video toCollection:@"TVShow" withCollectionTitle:NSLocalizedString(@"TITLE_TVSHOWS", nil)];
            if (mediaType & MPMediaTypeMovie) [self addItem:video toCollection:@"Movie" withCollectionTitle:NSLocalizedString(@"TITLE_MOVIES", nil)];
        }
    }
}


@end

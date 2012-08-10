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
                                    [[item valueForProperty:MPMediaItemPropertyAssetURL] absoluteString], @"url", 
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
    
    // generate thumbnail
    [self generateThumbnailForAsset:details];
}

- (void) generateThumbnailForAsset:(NSDictionary*)asset {
    
    AVAsset *a = [AVAsset assetWithURL:[NSURL URLWithString:[asset objectForKey:@"url"]]];
	generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:a];	
	generator.appliesPreferredTrackTransform = YES;
	
//	if ( mode == AssetBrowserItemFillModeAspectFit )
//		imageGenerator.maximumSize = size;
//	if ( mode == AssetBrowserItemFillModeCrop )
    generator.maximumSize = CGSizeMake(96.0, 64.0);
	
	NSValue *imageTimeValue = [NSValue valueWithCMTime:CMTimeMake(2, 1)];
	
    NSLog(@"heading in... %@", a);
	[generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:imageTimeValue] completionHandler:
	 ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) 
	 {	
         NSLog(@"what is going on?");
		 if (result == AVAssetImageGeneratorFailed) {
//			 dispatch_sync(assetQueue, ^(void) {
//				 canGenerateThumbnails = NO;
//				 [self generateNonVideoThumbnailWithSize:size fillMode:mode completionHandler:handler];
//			 });
             NSLog(@"...failed!");
		 }
		 else {
             NSLog(@"...still going...");
			 UIImage *thumbUIImage = nil;
			 if (image) {
//				 if (mode == AssetBrowserItemFillModeCrop) {
                 thumbUIImage = [self copyImageFromCGImage:image croppedToSize:CGSizeMake(96.0, 64.0)];
                 NSLog(@"generated... now to save");
                 NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/thumbnails"];
                 if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
                     [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
                 }
                 NSString *assetName = [path stringByAppendingPathComponent:[[asset objectForKey:@"id"] stringValue]];
                 NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(thumbUIImage)];
                 if ([imageData writeToFile:[assetName stringByAppendingString:@".png"] atomically:YES]) {
                     NSLog(@"thumbnail generated for: %@", [asset objectForKey:@"title"]);
                 } else {
                     NSLog(@"thumbnail *NOT* generated for: %@", [asset objectForKey:@"title"]);
                 }
                 
//				 }
//				 else {
//					 thumbUIImage = [[UIImage alloc] initWithCGImage:image];
//				 }
			 } else {
                 NSLog(@"not image :(");
             }
/*             
			 dispatch_async(dispatch_get_main_queue(), ^{
				 self.thumbnailImage = thumbUIImage;
				 [thumbUIImage release];
				 
				 if (handler) {
					 handler(self.thumbnailImage);
				 }
			 });
*/
		 }
		 
	 }];

}

- (UIImage*)copyImageFromCGImage:(CGImageRef)image croppedToSize:(CGSize)size {
	UIImage *thumbUIImage = nil;
	
	CGRect thumbRect = CGRectMake(0.0, 0.0, CGImageGetWidth(image), CGImageGetHeight(image));
	CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(size, thumbRect);
	cropRect.origin.x = round(cropRect.origin.x);
	cropRect.origin.y = round(cropRect.origin.y);
	cropRect = CGRectIntegral(cropRect);
	CGImageRef croppedThumbImage = CGImageCreateWithImageInRect(image, cropRect);
	thumbUIImage = [[UIImage alloc] initWithCGImage:croppedThumbImage];
	CGImageRelease(croppedThumbImage);
	
	return thumbUIImage;
}

- (NSArray*)getMediaInCollection:(NSString*)collection {
    NSDictionary* c = [collections objectForKey:collection];
    
    return (c==nil?false:[c objectForKey:@"media"]);
}

- (NSArray*)mediaOnDevice {
    NSArray* videos;
    
    if (true) {
        [[NSUserDefaults standardUserDefaults] synchronize];            
        // Take a look at the movies library and determine media types
        MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeAnyVideo] forProperty:MPMediaItemPropertyMediaType];    
        MPMediaQuery *videoQuery = [[MPMediaQuery alloc] initWithFilterPredicates:[NSSet setWithObject:predicate]];    
        videos = [videoQuery items];   
    } else {
        // THIS TEST DATA DOESN'T WORK ANYMORE. GOTTA FIX IT.
        NSMutableDictionary* c;    
        NSMutableArray *v    ;
        NSArray* details;
        
        // iTunes U
        {
            details = [NSArray arrayWithObjects:
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"12345", @"id",
                        @"Polymorphism", @"title", 
                        @"12345", @"id",
                        @"", @"url", 
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Jump Start Java", @"title", 
                        @"12346", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Jump Start C#", @"title", 
                        @"12347", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Jump Start Objective C", @"title", 
                        @"12348", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Introduction to C Style Syntax", @"title", 
                        @"12349", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       
                       nil];
        }
        v = [NSMutableArray arrayWithArray:details];
        c = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"iTunes U", @"title", v, @"media", nil];    
        [collections setObject:c forKey:@"ITunesU"];       
        
        // Music Videos
        {
            details = [NSArray arrayWithObjects:
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Thriller", @"title", 
                        @"123410", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Fell in Love with a Girl", @"title", 
                        @"123411", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Clint Eastwood", @"title", 
                        @"123412", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       nil];
        }
        v = [NSMutableArray arrayWithArray:details];
        c = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Music Videos", @"title", v, @"media", nil];    
        [collections setObject:c forKey:@"MusicVideo"];    
        
        // Podcasts
        {
            details = [NSArray arrayWithObjects:
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Gov't to makeup artists: Put down the blush, or we'll shut you down", @"title", 
                        @"123413", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Is your state pulling a medical CON job?", @"title", 
                        @"123414", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Caveman Blogger Fights for Free Speech and Internet Freedom", @"title", 
                        @"123415", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Should You Need the Government's Permission to Work?", @"title", 
                        @"123416", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       nil];
        }
        v = [NSMutableArray arrayWithArray:details];
        c = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Podcasts", @"title", v, @"media", nil];    
        [collections setObject:c forKey:@"VideoPodcast"];        
        
        // TV
        {
            details = [NSArray arrayWithObjects:
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Turtle Tracks", @"title", 
                        @"123417", @"id",
                        @"file://localhost/Users/asoell/Library/Application%20Support/iPhone%20Simulator/5.1/Applications/4342A7E9-87BA-488E-816B-DBC1A02EDA69/Documents/sample.mov", @"url", 
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Enter the Shredder", @"title", 
                        @"123418", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"A Thing About Rats", @"title", 
                        @"123419", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Hot-Rodding Teenagers from Dimension X", @"title", 
                        @"123420", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Shredder & Splintered", @"title", 
                        @"123421", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"The Fabulous Belding Boys", @"title", 
                        @"123422", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],   
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Breaking Up is Hard to Undo", @"title", 
                        @"123422", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],      
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"The Glee Club", @"title", 
                        @"123423", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],      
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"The Last Dance", @"title", 
                        @"123425", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Zack's Birthday Party", @"title", 
                        @"123426", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],               
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"The Aftermath", @"title", 
                        @"123427", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],                    nil];
        }
        v = [NSMutableArray arrayWithArray:details];
        c = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"TV Shows", @"title", v, @"media", nil];    
        [collections setObject:c forKey:@"TVShow"];
        
        // Movies
        {
            details = [NSArray arrayWithObjects:
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Beauty and the Beast", @"title", 
                        @"1231", @"id",
                        @"file://localhost/Users/asoell/Library/Application%20Support/iPhone%20Simulator/5.1/Applications/4342A7E9-87BA-488E-816B-DBC1A02EDA69/Documents/BeautyAndTheBeast.mp4", @"url", 
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Cinderella", @"title", 
                        @"123428", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Ice Age", @"title", 
                        @"123429", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Madagascar", @"title", 
                        @"123430", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Madagascar 2", @"title", 
                        @"123431", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Sleeping Beauty", @"title", 
                        @"123432", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],   
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Tangled", @"title", 
                        @"1232", @"id",
                        @"file://localhost/Users/asoell/Library/Application%20Support/iPhone%20Simulator/5.1/Applications/4342A7E9-87BA-488E-816B-DBC1A02EDA69/Documents/Tangled.mp4", @"url", 
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],      
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Toy Story", @"title", 
                        @"123433", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],      
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Toy Story 2", @"title", 
                        @"123434", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Toy Story 3", @"title", 
                        @"123435", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],               
                       nil];
        }
        v = [NSMutableArray arrayWithArray:details];
        c = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Movies", @"title", v, @"media", nil];    
        [collections setObject:c forKey:@"Movie"];    
        
        // iTunes Sharing
        {
            details = [NSArray arrayWithObjects:
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Lucy's first steps", @"title", 
                        @"123436", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"Halloween 2011", @"title", 
                        @"123437", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"2010 Year in Review", @"title", 
                        @"123438", @"id",
                        @"", @"url",  
                        [NSNumber numberWithBool:NO], @"hasProtectedContent",
                        nil],        
                       nil];
        }
        v = [NSMutableArray arrayWithArray:details];
        c = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"iTunes", @"title", v, @"media", nil];    
        //    [mediaIndex.collections setObject:c forKey:@"iTunesShared"];        
    }

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

    [self purgeRemoved];
    [self addNew];
    [self regenerateThumbnails];
    [self save];
}

- (void)save {
    if ([collections writeToFile:[[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:@"mediaLibrary.plist"] atomically:NO]) {
        NSLog(@"Media Library saved successfully");
    } else {
        NSLog(@"COULDN'T SAVE MEDIA LIBRARY");
    }
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
            if (mediaType & MPMediaTypeVideoITunesU) [self addItem:video toCollection:@"ITunesU" withCollectionTitle:@"iTunes U"];
            if (mediaType & MPMediaTypeMusicVideo) [self addItem:video toCollection:@"MusicVideo" withCollectionTitle:@"Music Videos"];
            if (mediaType & MPMediaTypeVideoPodcast) [self addItem:video toCollection:@"VideoPodcast" withCollectionTitle:@"Podcasts"];
            if (mediaType & MPMediaTypeTVShow) [self addItem:video toCollection:@"TVShow" withCollectionTitle:@"TV Shows"];
            if (mediaType & MPMediaTypeMovie) [self addItem:video toCollection:@"Movie" withCollectionTitle:@"Movies"];
        }
    }
}

- (void)regenerateThumbnails {
    NSArray *keys = index.allKeys;
    for (NSNumber* key in keys) {
        NSLog(@"generating for %@", [[index objectForKey:key] objectForKey:@"title"]);        
        [self generateThumbnailForAsset:[index objectForKey:key]];
    }
}


@end

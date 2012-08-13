#import <Foundation/Foundation.h>

@class MPMediaItem;
@interface MediaLibrary : NSObject {
    @public NSMutableDictionary* collections;
    @public NSMutableDictionary* index;    
}

@property (nonatomic) NSMutableDictionary* collections;
@property (nonatomic) NSMutableDictionary* index;

- (void)addItem:(MPMediaItem*)item toCollection:(NSString*)collection withCollectionTitle:(NSString*)title;
- (NSArray*)getMediaInCollection:(NSString*)collection;
- (void)save;
- (void)load;
- (void)removeById:(NSNumber*)id;

@end

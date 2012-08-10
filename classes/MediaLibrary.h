#import <Foundation/Foundation.h>

@class MPMediaItem, AVAssetImageGenerator;
@interface MediaLibrary : NSObject {
    @public NSMutableDictionary* collections;
    @public NSMutableDictionary* index;
    AVAssetImageGenerator *generator;
}

@property (nonatomic) NSMutableDictionary* collections;
@property (nonatomic) NSMutableDictionary* index;

- (void)addItem:(MPMediaItem*)item toCollection:(NSString*)collection withCollectionTitle:(NSString*)title;
- (void) generateThumbnailForAsset:(NSDictionary*)asset;
- (UIImage*)copyImageFromCGImage:(CGImageRef)image croppedToSize:(CGSize)size;
- (NSArray*)getMediaInCollection:(NSString*)collection;
- (void)save;
- (void)load;
- (void)removeById:(NSNumber*)id;

@end

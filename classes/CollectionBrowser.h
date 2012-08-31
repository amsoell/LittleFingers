#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@class CollectionTable;
@interface CollectionBrowser : UIViewController <UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate,MFMailComposeViewControllerDelegate> {
    NSDictionary *dataSource;   // Dictionary (category), whose members are arrays (collection) of dictionaries (media item)
    NSMutableDictionary *dataSourceWithoutProtectedContent;
    IBOutlet CollectionTable *tv;
    UIView *intro;
    NSString* emptyText;
    BOOL disableSecondaryDataSource;
    NSIndexPath* prevSelected;
}

- (id)initWithCollection:(NSDictionary *)collection;
- (BOOL)hasUnprotectedContent;
- (void)actionEmailComposer;

@property (nonatomic, strong) IBOutlet CollectionTable *tv;
@property (nonatomic, strong) UIView *intro;
@property (nonatomic, strong) NSDictionary *dataSource;
@property (nonatomic, strong) NSDictionary *dataSourceWithoutProtectedContent;
@property (nonatomic, strong) UINavigationController* videoPlaybackController;
@property (nonatomic, strong) NSString* emptyText;
@property (nonatomic) BOOL disableSecondaryDataSource;
@property (nonatomic) NSIndexPath* prevSelected;

@end

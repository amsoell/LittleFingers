#import "AppDelegate.h"
#import "CollectionBrowser.h"
#import "CollectionBrowserCell.h"
#import "CollectionHeader.h"
#import "CollectionTable.h"
#import "PlaybackViewController.h"
#import "SPDeepCopy.h"
#import "NSData+Gzip.h"
#import "UIDevice+Hardware.h"
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

@interface CollectionBrowser ()

@end

@implementation CollectionBrowser
@synthesize dataSource, dataSourceWithoutProtectedContent;
@synthesize tv, intro, videoPlaybackController, emptyText, disableSecondaryDataSource, prevSelected;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        disableSecondaryDataSource = NO;
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
    disableSecondaryDataSource = NO;
    
    return [super init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        [self.tv setBackgroundView:nil];
        [self.tv setBackgroundView:[[UIView alloc] init]];
        [self.tv setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"UIPinStripe"]]];
    } else {
        [self.tv setBackgroundView:nil];
        [self.tv setBackgroundView:[[UIView alloc] init]];
        [self.tv setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"furley_bg"]]];        
    }
}

- (void)viewWillAppear:(BOOL)animated {

    if ((self.tv.tableHeaderView==nil) && (intro != nil)) {
        
        // Add logo
        CGRect newFrame = intro.frame;
        newFrame.origin.x = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad?50:20);
        newFrame.origin.y = 10;
        [intro setFrame:newFrame];

        UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, intro.frame.size.width+intro.frame.origin.x, intro.frame.size.height+intro.frame.origin.y)];        
        [headerView addSubview:intro];
        
        
        if ((emptyText != nil)) {
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
                [introText setFont:[UIFont fontWithName:@"Baskerville" size:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad?24.0f:18.0)]];
                
                CGRect newFrame = introText.frame;
                newFrame.origin.x = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad?50:20);
                newFrame.origin.y = headerView.frame.size.height+10;
                newFrame.size.width = 200;//self.view.bounds.size.width-100;// = [emptyText sizeWithFont:introText.font constrainedToSize:CGSizeMake(self.view.frame.size.width-100, MAXFLOAT)];
                newFrame.size.height = 300;
                [introText setFrame:newFrame];
                [introText setNumberOfLines:0];
                [introText setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin];
                
                [headerView addSubview:introText];
//                [headerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin];
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"buttonIndex: %d", alertView.tag);
    switch (alertView.tag) {
        case 1: // Hide DRM alert view
            if (buttonIndex == 1) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"hideprotected"];
                [sharedAppDelegate settingsChanged];
            }
            break;
        case 2: // Handle missing URL alert view
            NSLog(@"handle missing url alertview");
            switch (buttonIndex) {
                case 1: // Open videos app
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"videos://"]];
                    break;
                case 2: // Send support email
                    [self actionEmailComposer];
                    break;
            }
    }
        
}


- (NSDictionary*)dataSourceRef {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hideprotected"] && !disableSecondaryDataSource) {
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?127.0f:63.0f);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CollectionBrowserCell *cell;
    if (indexPath.row != ([tableView numberOfRowsInSection:indexPath.section]-1)) 
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];   
    
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad?@"CollectionBrowserCell-iPad":@"CollectionBrowserCell") owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];   
    }
    
    NSArray* itemKeys = [[self dataSourceRef] allKeys];
    NSDictionary *item = [[[self dataSourceRef] objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];    
    [cell setDetails:[NSDictionary dictionaryWithObjectsAndKeys:
                      [item objectForKey:@"title"], @"title",
                      [item objectForKey:@"url"], @"url",
                      [item objectForKey:@"id"], @"id", 
                      [item objectForKey:@"duration"], @"duration",
                      [item objectForKey:@"album"], @"album",
                      nil]];
    
    UIButton *accessory = [UIButton buttonWithType:UIButtonTypeCustom];
    
    
    [accessory setImage:([self isFavorite:item]?[self starImage]:[self dotImage]) forState:UIControlStateNormal];
    accessory.frame = CGRectMake(0, 0, 30, 30);
    accessory.userInteractionEnabled = YES;
    [accessory addTarget:self action:@selector(toggleFavorite:forEvent:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = accessory;  
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hideprotected"] &&
        ([item objectForKey:@"hasProtectedContent"] && ([[item objectForKey:@"hasProtectedContent"] compare:[NSNumber numberWithBool:YES]] == NSOrderedSame))) 
        [cell.textLabel setText:@"**redacted**"];
    
    CGRect b = cell.bounds;
    b.size.width +=1;
    b.size.height +=1;
    
    if (indexPath.row == 0) {    
        cell.backgroundView = [[UITableViewCell alloc] initWithFrame:cell.bounds];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"CollectionBrowserCellBg"]];
        [cell.backgroundView.layer setBorderColor:[UIColor lightGrayColor].CGColor];
        [cell.backgroundView.layer setBorderWidth:1.0];
    } else if (indexPath.row == ([tableView numberOfRowsInSection:indexPath.section]-1)) {
        cell.thumbnail.image = [cell roundCornersOfImage:cell.thumbnail.image roundTop:NO roundBottom:YES];
    }
    
    
    
    return cell;
}




- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSArray* itemKeys = [[self dataSourceRef] allKeys];
    UIView *header;
    
    if ([[[self dataSourceRef] objectForKey:[itemKeys objectAtIndex:section]] count]>0) {        
        header = [[CollectionHeader alloc] init];        
        if ([[[self dataSourceRef] objectForKey:[itemKeys objectAtIndex:section]] count]>0) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(55.0, 7.0, 300.0, 25.0)];
            [label setText:[[[self dataSourceRef] allKeys] objectAtIndex:section]];
            [label setFont:[UIFont fontWithName:@"Optima" size:20.0f]];
            [label setTextColor:[UIColor whiteColor]];
            [label setBackgroundColor:[UIColor clearColor]];     
            [label setShadowColor:[UIColor darkGrayColor]];
            [label setShadowOffset:CGSizeMake(0, -0.5)];
            
            [header addSubview:label];
            NSLog(@"adding title: %@", [[[self dataSourceRef] allKeys] objectAtIndex:section]);
        }
    } else {
        header = [[UIView alloc] init];
    }
    return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; 
    [self setPrevSelected:indexPath];
    
    NSArray* itemKeys = [[self dataSourceRef] allKeys];            
    NSDictionary *item = [[[self dataSourceRef] objectForKey:[itemKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    NSLog(@"item: %@", item);
    
    // Make sure it's playable
    if ([item objectForKey:@"hasProtectedContent"] && ([[item objectForKey:@"hasProtectedContent"] compare:[NSNumber numberWithBool:YES]] == NSOrderedSame)) {
        // DRM. Let user know they can hide these.
        //todo: let user hide them
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CANNOT_PLAY", nil) message:[NSString stringWithFormat:NSLocalizedString(@"CANNOT_PLAY_DRM", nil), [sharedAppDelegate shortAppName]] delegate:self cancelButtonTitle:NSLocalizedString(@"NO", nil) otherButtonTitles:nil];
        [alert addButtonWithTitle:NSLocalizedString(@"YES", nil)];
        [alert setTag:1];
		[alert show];        
    } else if (([item objectForKey:@"url"] == nil) || [[item objectForKey:@"url"] isEqualToString:@""]) {
        // No URL. Probably in the cloud
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CANNOT_PLAY", nil) message:NSLocalizedString(@"CANNOT_PLAY_MISSING_URL", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) otherButtonTitles:nil];
        [alert addButtonWithTitle:NSLocalizedString(@"OPEN_VIDEO", nil)];        
        [alert addButtonWithTitle:NSLocalizedString(@"TROUBLESHOOT", nil)];        
        [alert setTag:2];
		[alert show];            
    } else {
        
        // Log it in history
        [sharedAppDelegate logHistory:[NSDictionary dictionaryWithDictionary:item]];
        
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Played video" attributes:[NSDictionary dictionaryWithObject:[[NSDictionary dictionaryWithDictionary:item] objectForKey:@"title"] forKey:@"Title"]];
        [TestFlight passCheckpoint:@"Selected video"];
        
        NSURL* vidUrl;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[item objectForKey:@"url"]]) {
            vidUrl = [NSURL fileURLWithPath:[item objectForKey:@"url"]];
        } else {
            vidUrl = [NSURL URLWithString:[item objectForKey:@"url"]];            
        }
        
        AVURLAsset* urlAsset = [[AVURLAsset alloc] initWithURL:vidUrl options:nil];

        if (urlAsset) {
            NSLog(@"Playing from asset URL");
            [sharedAppDelegate playVideoWithURL:urlAsset andTitle:[item objectForKey:@"title"]];
    //	} else if (playbackViewController) {
    //		[playbackViewController setURL:nil];
        }        
    }
}

- (void)actionEmailComposer {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        [mailViewController setToRecipients:[NSArray arrayWithObject:[NSString stringWithString:@"support@littlefingersapp.com"]]];
        [mailViewController setSubject:NSLocalizedString(@"TROUBLESHOOTING_EMAIL_SUBJECT_CANNOT_PLAY_MISSING_URL", nil)];
        [mailViewController setMessageBody:NSLocalizedString(@"TROUBLESHOOTING_EMAIL_BODY_CANNOT_PLAY_MISSING_URL", nil) isHTML:NO];

        NSArray* itemKeys = [[self dataSourceRef] allKeys];            
        NSDictionary* dataDump = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSDictionary dictionaryWithContentsOfFile:[[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:@"mediaLibrary.plist"]], @"mediaLibrary",
                                    [NSDictionary dictionaryWithContentsOfFile:[sharedAppDelegate getMarksPath]], @"marks",
                                    [[[self dataSourceRef] objectForKey:[itemKeys objectAtIndex:prevSelected.section]] objectAtIndex:prevSelected.row], @"selectedIndex",
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     [[UIDevice currentDevice] model], @"model",
                                     [[UIDevice currentDevice] platform], @"platform",
                                     [[UIDevice currentDevice] systemVersion], @"systemVersion",
                                     [[NSLocale preferredLanguages] objectAtIndex:0], @"language",
                                     [[NSLocale currentLocale] localeIdentifier], @"localeIdentifier",
                                     [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], @"appVersion",
                                     [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], @"appBuild",                                     
                                     nil], @"device",
                                    nil];
        [mailViewController addAttachmentData:[[NSPropertyListSerialization dataFromPropertyList:dataDump format:NSPropertyListXMLFormat_v1_0 errorDescription:nil] gzipDeflate] mimeType:@"application/xml" fileName:@"errorLog.plist.gz"];
        

        [self presentModalViewController:mailViewController animated:YES];
          
    } else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR", nil) message:NSLocalizedString(@"TROUBLESHOOTING_EMAIL_NOT_CONFIGURED", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
		[alert show];        

    }          
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissModalViewControllerAnimated:YES];
    if (result == MFMailComposeResultSent) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"THANKS", nil) message:NSLocalizedString(@"TROUBLESHOOTING_EMAIL_SENT", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
		[alert show];        
        
    }
}


@end

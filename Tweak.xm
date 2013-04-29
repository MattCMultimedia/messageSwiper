


#import <ChatKit/CKTranscriptController.h>
#import <ChatKit/CKConversationList.h>
#import <ChatKit/CKConversation.h>
#import <MobileSMS/CKMessagesController.h>
#import <UIKit/UIGestureRecognizer.h>
#import <UIKit/UIKit.h>


#import <WhatsApp/ChatManager.h>
#import <WhatsApp/WAChatSession.h>
#import <WhatsApp/ConversationViewController.h>
#import <WhatsApp/ChatListViewController.h>
#import <WhatsApp/WAChatStorage.h>
#import <WhatsApp/ChatNavigationController.h>
#import <WhatsApp/WAScrollView.h>
#import <WhatsApp/WhatsAppAppDelegate.h>



//static NSString *test;
static NSMutableArray *convos = [[NSMutableArray alloc] init];
static CKMessagesController *ckMessagesController;
static unsigned int currentConvoIndex = 0;
static UIView *backPlacard;
static BOOL isFirstLaunch = YES;
static BOOL customSwipeSettings = NO;

static BOOL globalEnable = YES;
static BOOL switchShortSwipeDirections = NO;
static BOOL longSwipesEnabled = YES;
static BOOL wrapAroundEnabled = NO;
static BOOL enableAnimations = YES;
static BOOL hideBackButton = NO;
static BOOL updateFrequently = YES;

//values
static int longSwipeDistance = 200;
static int shortSwipeDistance = 50;

static UILabel *leftContactNameLabel;
static UILabel *rightContactNameLabel;
static UILabel *leftMostRecentMessageLabel;
static UILabel *rightMostRecentMessageLabel;
static UIImage *previewImage;
static UIImage *flippedPreviewImage;
static NSDictionary *preferences = nil;

static CGPoint originalLocation;

#define PrefPath [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.mattcmultimedia.messageswiper.plist"]

// static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
//     [preferences release];
//     preferences = [[NSDictionary alloc] initWithContentsOfFile:PrefPath];
//     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"pref changed"
//         message:[NSString stringWithFormat:@"%@", @"Test"]
//         delegate:nil
//         cancelButtonTitle:@"K"
//         otherButtonTitles:nil];
//     [alert show];
//     [alert release];

// }

static NSString *getsuffix() {

    if ([[UIScreen mainScreen] scale] < 2.0f)
        return @"";

    return @"@2x";

}



//animation UIView interfaces and stuff
@interface MSNextMessagePreviewView : UIImageView
@property (assign) NSString *contactName;
@property (assign) NSString *mostRecentMessage;

- (void) setConversation:(CKConversation *)convo;

@end
@implementation MSNextMessagePreviewView
@synthesize contactName = _contactName;
@synthesize mostRecentMessage = _mostRecentMessage;

- (void) setConversation:(CKConversation *)convo
{
    self.contactName = [convo name];
    //would set mostRecentMessage here
    self.mostRecentMessage = [[convo latestMessage] previewText]; //returns CKIMMessage => NSString


}


- (void)baseInit {
    _contactName = NULL;
    _contactName = @"Unknown - Error";
    _mostRecentMessage = @"Error Retrieving Message.";
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self baseInit];
    }
    return self;
}

@end

static MSNextMessagePreviewView *leftPreviewView = [[MSNextMessagePreviewView alloc] initWithFrame:CGRectMake(-60,10,120,160)];
static MSNextMessagePreviewView *rightPreviewView = [[MSNextMessagePreviewView alloc] initWithFrame:CGRectMake(backPlacard.frame.size.width+60,10,120,160)];




@interface MSSwipeDelegate : NSObject <UIGestureRecognizerDelegate>

-(void)messageSwiper_handlePan:(UIPanGestureRecognizer *)recognizer;
-(void)createPreviewImages;
@end
@implementation MSSwipeDelegate

-(void)createPreviewImages {
    NSBundle *bundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/MessageSwiper/"];
    NSString *imagePath = [bundle pathForResource:[NSString stringWithFormat:@"/previewImage%@", getsuffix()] ofType:@"png"];
    previewImage = [UIImage imageWithContentsOfFile:imagePath];
    UIImageOrientation flippedOrientation = UIImageOrientationUpMirrored;
    flippedPreviewImage = [UIImage imageWithCGImage:previewImage.CGImage scale:previewImage.scale orientation:flippedOrientation];

    leftPreviewView.image = previewImage;
    rightPreviewView.image = flippedPreviewImage;

    [bundle release];
    [imagePath release];
}

-(void)messageSwiper_handlePan:(UIPanGestureRecognizer *)recognizer
{

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        //if new touch
        originalLocation = [recognizer locationInView:recognizer.view];

    }
    //if convos are empty and stuff, just don't do anything, also if global enable off
    if (!globalEnable) {
        return;
    }
    if ((convos == NULL) || ([convos count] == 0)) {
        return;
    }
    CGPoint tempLoc = [recognizer locationInView:recognizer.view];
    CGPoint translation;//[recognizer translationInView:recognizer.view];
    if (tempLoc.x >= originalLocation.x) {
        translation = CGPointMake(tempLoc.x - originalLocation.x, originalLocation.y);
    } else {
        translation = CGPointMake(-1* (originalLocation.x - tempLoc.x), originalLocation.y);
    }
    unsigned int nextConvoIndex;

    //positive == right
    //negative == left
    if (switchShortSwipeDirections) {
        translation.x = -1 * translation.x;
    }
    if (translation.x > 0) {
        //is an ongoing swipe to the right
        rightPreviewView.center = CGPointMake(recognizer.view.frame.size.width+60, leftPreviewView.center.y);
        rightPreviewView.hidden = YES;

        nextConvoIndex = currentConvoIndex - 1;
        if (currentConvoIndex == 0) {
            if (wrapAroundEnabled) {
                nextConvoIndex = [convos count] - 1 ;
            } else {
                nextConvoIndex = 0;
                //maybe show bounce animation here
            }
        }
        if (enableAnimations) {
            //show animations here

            if (![leftPreviewView isDescendantOfView:recognizer.view]) {
                //if not added to view, go ahead and grab the image and add it to the view
                if (previewImage == NULL) {
                    [self createPreviewImages];
                }
                [recognizer.view addSubview:leftPreviewView];

                leftContactNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(9, 15, 75, 50)];
                [leftContactNameLabel setTextColor:[UIColor blackColor]];
                [leftContactNameLabel setBackgroundColor:[UIColor clearColor]];
                [leftContactNameLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
                [leftContactNameLabel setNumberOfLines:4];
                [leftContactNameLabel setLineBreakMode:NSLineBreakByWordWrapping];
                [leftPreviewView addSubview:leftContactNameLabel];

                //add message label here
                leftMostRecentMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(9,69,75, 79)];
                [leftMostRecentMessageLabel setTextColor:[UIColor blackColor]];
                [leftMostRecentMessageLabel setBackgroundColor:[UIColor clearColor]];
                [leftMostRecentMessageLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 12.0f]];
                [leftMostRecentMessageLabel setNumberOfLines:10];
                [leftMostRecentMessageLabel setLineBreakMode:NSLineBreakByWordWrapping];
                [leftPreviewView addSubview:leftMostRecentMessageLabel];
            }
            [leftPreviewView setConversation:[convos objectAtIndex:nextConvoIndex]];
            leftContactNameLabel.text = leftPreviewView.contactName;
            leftMostRecentMessageLabel.text = leftPreviewView.mostRecentMessage;
            //update message label here
            [recognizer.view bringSubviewToFront:leftPreviewView];
            leftPreviewView.hidden = NO;
            if ((translation.x > longSwipeDistance) && longSwipesEnabled) {
                leftContactNameLabel.text = @"Convo List";
                leftMostRecentMessageLabel.text = @"Release to Return to List.";
            }

            //actual animations

            int scalar;
            if (shortSwipeDistance > 120) {
                scalar = 1;
            } else {
                scalar = (120/shortSwipeDistance);
            }
            //float slideFactor = 0.1 * slideMult; // Increase for more of a slide
            CGPoint finalPoint = CGPointMake(-60 + (translation.x * scalar),
                                             leftPreviewView.center.y);
            finalPoint.x = MIN(finalPoint.x, 60);
            //finalPoint.y = MIN(MAX(finalPoint.y, 0), recognizer.view.bounds.size.height);
            if (translation.x > shortSwipeDistance+8) {
                leftPreviewView.alpha = 1.0f;
            } else {
                leftPreviewView.alpha = 0.75f;
            }

            leftPreviewView.center = finalPoint;

        }

    } else {
        //is an ongoing swipe left
        leftPreviewView.hidden = YES;
        leftPreviewView.center = CGPointMake(-60, leftPreviewView.center.y);
        nextConvoIndex = currentConvoIndex + 1;
        if (nextConvoIndex >= [convos count]) {
            if (wrapAroundEnabled) {
                nextConvoIndex = 0;
            } else {
                nextConvoIndex = currentConvoIndex;
                //maybe display bounce animation here
            }
        }
        if (enableAnimations) {
            //show animations here

            //previewImage.imageOrientation = UIImageOrientationUpMirrored;
            if (![rightPreviewView isDescendantOfView:recognizer.view]) {
                if (flippedPreviewImage == NULL) {
                    [self createPreviewImages];
                }

                [recognizer.view addSubview:rightPreviewView];

                rightContactNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(39, 15, 75, 50)];
                [rightContactNameLabel setTextColor:[UIColor blackColor]];
                [rightContactNameLabel setBackgroundColor:[UIColor clearColor]];
                [rightContactNameLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
                [rightContactNameLabel setNumberOfLines:4];
                [rightContactNameLabel setLineBreakMode:NSLineBreakByWordWrapping];
                [rightPreviewView addSubview:rightContactNameLabel];

                rightMostRecentMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(39,69,75, 79)];
                [rightMostRecentMessageLabel setTextColor:[UIColor blackColor]];
                [rightMostRecentMessageLabel setBackgroundColor:[UIColor clearColor]];
                [rightMostRecentMessageLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 12.0f]];
                [rightMostRecentMessageLabel setNumberOfLines:10];
                [rightMostRecentMessageLabel setLineBreakMode:NSLineBreakByWordWrapping];
                [rightPreviewView addSubview:rightMostRecentMessageLabel];
            }

            [rightPreviewView setConversation:[convos objectAtIndex:nextConvoIndex]];
            rightContactNameLabel.text = rightPreviewView.contactName;
            rightMostRecentMessageLabel.text = rightPreviewView.mostRecentMessage;
            [recognizer.view bringSubviewToFront:rightPreviewView];
            rightPreviewView.hidden = NO;

            if ((-1*translation.x > longSwipeDistance) && longSwipesEnabled) {
                //set to first convo
                [rightPreviewView setConversation:[convos objectAtIndex:0]];
                rightContactNameLabel.text = rightPreviewView.contactName;
                rightMostRecentMessageLabel.text = rightPreviewView.mostRecentMessage;
            }

            //actually animate ImageView here
            int scalar;
            if (shortSwipeDistance > 120) {
                scalar = 1;
            } else {
                scalar = (120/shortSwipeDistance);
            }
            CGPoint finalPoint = CGPointMake(recognizer.view.frame.size.width+60 + (translation.x * scalar), leftPreviewView.center.y);
            finalPoint.x = MAX(finalPoint.x, recognizer.view.frame.size.width - 60);
            //finalPoint.y = MIN(MAX(finalPoint.y, 0), recognizer.view.bounds.size.height);
            if (-1*translation.x > (shortSwipeDistance+8)) {
                rightPreviewView.alpha = 1.0f;
            } else {
                rightPreviewView.alpha = 0.75f;
            }

            rightPreviewView.center = finalPoint;
        }

    }
    //LIFTS FINGER

    //once user lifts finger, do whatever should happen within swipe range
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        //remove the UIView when this gets called


        leftPreviewView.hidden = YES;
        rightPreviewView.hidden = YES;
        leftPreviewView.center = CGPointMake(-60, leftPreviewView.center.y);
        rightPreviewView.center = CGPointMake(recognizer.view.frame.size.width+60, rightPreviewView.center.y);




        if (translation.x > 0) {

            //ended swipe on right side

            if ((translation.x >= longSwipeDistance) && longSwipesEnabled) {
                //if long swipe right, show list
                if (switchShortSwipeDirections) {
                    //but if switched, show newest message
                    convos = [[%c(CKConversationList) sharedConversationList] conversations];
                    [ckMessagesController showConversation:[convos objectAtIndex:0] animate:YES];
                } else {
                    [ckMessagesController showConversationList:YES];
                }
                return;
            }

            if (translation.x >= shortSwipeDistance) {
                //this is short swipe: show next convo
                [ckMessagesController showConversation:[convos objectAtIndex:nextConvoIndex] animate:YES];
                return;
            }

        } else {

            //ended swipe on left side
            //long swipe stuff left
            translation.x = -1 * translation.x;


            if ((translation.x >= longSwipeDistance) && longSwipesEnabled) {
                if (switchShortSwipeDirections) {
                    [ckMessagesController showConversationList:YES];
                } else {
                    convos = [[%c(CKConversationList) sharedConversationList] conversations];
                    [ckMessagesController showConversation:[convos objectAtIndex:0] animate:YES];
                }
                return;
            }
            //short swipe stuff left
            if (translation.x >= shortSwipeDistance) {
                //this is short swipe: show next convo

                [ckMessagesController showConversation:[convos objectAtIndex:nextConvoIndex] animate:YES];
                return;
            }
        }



    }

}

//delegate methods
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}
@end

static MSSwipeDelegate *swipeDelegate;

%hook CKTranscriptController

- (void)viewDidAppear:(BOOL)arg1
{
    //only run this part once or otherwise we'll have multiple gesturerecognizers and shit
    if (isFirstLaunch) {
        backPlacard = self.view;
        if (backPlacard) {
            isFirstLaunch = NO;
            if (!swipeDelegate) {
                swipeDelegate = [[MSSwipeDelegate alloc] init];
            }
            //just in case it isn't default
            backPlacard.userInteractionEnabled = YES;

            //testing pan gesture recognizer - works pretty well
            UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:swipeDelegate action:@selector(messageSwiper_handlePan:)];
            panRecognizer.maximumNumberOfTouches = 1;
            [backPlacard addGestureRecognizer:panRecognizer];

            //possibly add another panRecognizer to allow for two finger longSwipes
        }
    }

    if (longSwipesEnabled && hideBackButton && globalEnable) {
        [[self navigationItem] setHidesBackButton:YES];
    }


    %orig;

}

- (void)_messageReceived:(id)arg1
{

    %orig;
    if (updateFrequently) {
        convos = [[%c(CKConversationList) sharedConversationList] conversations];
        currentConvoIndex = [convos indexOfObject:[self conversation]];
    }

}
%end

//
%hook CKMessagesController
-(void)_conversationLeft:(id)left
{
    //if you delete a convo
    convos = [[%c(CKConversationList) sharedConversationList] conversations];


    %orig;
}

//
-(void)showConversation:(id)conversation animate:(BOOL)animate
{
    //resets currentConvoIndex

    currentConvoIndex = [convos indexOfObject:conversation];
    %orig;
}
-(void)showConversation:(id)conversation animate:(BOOL)animate forceToTranscript:(BOOL)transcript
{
    //preferences = [[NSDictionary alloc] initWithContentsOfFile:PrefPath];

    // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Test"
    //     message:[NSString stringWithFormat:@"Global: %@\ncustomSettings: %@\nflip: %@\nwrap: %@\nenable long: %@\nenable anim: %@\nhide back: %@\nupdate: %@\nlong: %d\nshort: %d\n%@",
    //                 globalEnable?@"YES":@"NO",customSwipeSettings?@"YES":@"NO",switchShortSwipeDirections?@"YES":@"NO",wrapAroundEnabled?@"YES":@"NO",longSwipesEnabled?@"YES":@"NO",enableAnimations?@"YES":@"NO",hideBackButton?@"YES":@"NO",updateFrequently?@"YES":@"NO", longSwipeDistance, shortSwipeDistance, preferences]
    //     delegate:nil
    //     cancelButtonTitle:@"K"
    //     otherButtonTitles:nil];
    // [alert show];
    // [alert release];

    currentConvoIndex = [convos indexOfObject:conversation];
    %orig;
}

-(BOOL)resumeToConversation:(id)conversation
{
    currentConvoIndex = [convos indexOfObject:conversation];
    return %orig;
}
//grabs the ckMessagesController object

-(id)init
{

    convos = [[%c(CKConversationList) sharedConversationList] conversations];

    ckMessagesController = self;

    // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"convos"
    //     message:[NSString stringWithFormat:@"%@", convos]
    //     delegate:nil
    //     cancelButtonTitle:@"K"
    //     otherButtonTitles:nil];
    // [alert show];
    // [alert release];


    return %orig;
    //init prefs again
    preferences = [[NSDictionary alloc] initWithContentsOfFile:PrefPath];
    if (preferences == nil) {
        globalEnable = YES;
    } else {
        //if the option exists make it that, else default
        if ([preferences valueForKey:@"globalEnable"] != nil) {
            globalEnable = [[preferences valueForKey:@"globalEnable"] boolValue];
        } else {
            globalEnable = YES;
        }
        if ([preferences valueForKey:@"customSwipeSettings"] != nil) {
            customSwipeSettings = [[preferences valueForKey:@"customSwipeSettings"] boolValue];
        } else {
            customSwipeSettings = NO;
        }
        if (customSwipeSettings) {
            if ([preferences valueForKey:@"switchShortSwipeDirections"] != nil) {
                switchShortSwipeDirections = [[preferences valueForKey:@"switchShortSwipeDirections"] boolValue];
            } else {
                switchShortSwipeDirections = NO;
            }
            if ([preferences valueForKey:@"wrapAroundEnabled"] != nil) {
                wrapAroundEnabled = [[preferences valueForKey:@"wrapAroundEnabled"] boolValue];
            } else {
                wrapAroundEnabled = NO;
            }
            if ([preferences valueForKey:@"enableAnimations"] != nil) {
                enableAnimations = [[preferences valueForKey:@"enableAnimations"] boolValue];
            } else {
                enableAnimations = YES;
            }
            if ([preferences valueForKey:@"longSwipesEnabled"] != nil) {
                longSwipesEnabled = [[preferences valueForKey:@"longSwipesEnabled"] boolValue];
            } else {
                longSwipesEnabled = YES;
            }
            if ([preferences valueForKey:@"hideBackButton"] != nil) {
                hideBackButton = [[preferences valueForKey:@"hideBackButton"] boolValue];
            } else {
                hideBackButton = NO;
            }
            if ([preferences valueForKey:@"updateFrequently"] != nil) {
                updateFrequently = [[preferences valueForKey:@"updateFrequently"] boolValue];
            } else {
                updateFrequently = YES;
            }
            if ([preferences valueForKey:@"longSwipeDistance"] != nil) {
                longSwipeDistance = [[preferences valueForKey:@"longSwipeDistance"] intValue];
            } else {
                longSwipeDistance = 200;
            }
            if ([preferences valueForKey:@"shortSwipeDistance"] != nil) {
                shortSwipeDistance = [[preferences valueForKey:@"shortSwipeDistance"] intValue];
            } else {
                shortSwipeDistance = 50;
            }
        } else {
            //defaults
            switchShortSwipeDirections = NO;
            wrapAroundEnabled = NO;
            enableAnimations = YES;
            longSwipesEnabled = YES;
            hideBackButton = NO;
            updateFrequently = YES;
            longSwipeDistance = 200;
            shortSwipeDistance = 50;
        }
    }
    [preferences release];
}

%end

%hook CKConversation

- (void)sendMessage:(id)arg1 newComposition:(BOOL)arg2
{
    if (updateFrequently) {
        convos = [[%c(CKConversationList) sharedConversationList] conversations];
        currentConvoIndex = [convos indexOfObject:self];
    }
    %orig;
}
- (void)sendMessage:(id)arg1 onService:(id)arg2 newComposition:(BOOL)arg3
{
    if (updateFrequently) {
        convos = [[%c(CKConversationList) sharedConversationList] conversations];
        currentConvoIndex = [convos indexOfObject:self];
    }
    %orig;

}

%end



%group WhatsAppStuff
static NSMutableArray *chatSessions;
//static NSMutableDictionary *chatViewControllers;

static ChatListViewController *clViewController;
static ChatNavigationController *cNavController;
static WhatsAppAppDelegate *whatsAppAppDelegate;
static int currentChatSessionIndex;

@interface MSWAPSwipeDelegate : NSObject <UIGestureRecognizerDelegate>
-(void)messageSwiperWAP_handlePan:(UIPanGestureRecognizer *)recognizer;
-(void)createPreviewImages;
@end
@implementation MSWAPSwipeDelegate

-(void)createPreviewImages {
    NSBundle *bundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/MessageSwiper/"];
    NSString *imagePath = [bundle pathForResource:[NSString stringWithFormat:@"/previewImage%@", getsuffix()] ofType:@"png"];
    previewImage = [UIImage imageWithContentsOfFile:imagePath];
    UIImageOrientation flippedOrientation = UIImageOrientationUpMirrored;
    flippedPreviewImage = [UIImage imageWithCGImage:previewImage.CGImage scale:previewImage.scale orientation:flippedOrientation];

    leftPreviewView.image = previewImage;
    rightPreviewView.image = flippedPreviewImage;

    [bundle release];
    [imagePath release];
}

-(void)messageSwiperWAP_handlePan:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        //if new touch
        originalLocation = [recognizer locationInView:recognizer.view];

    }
    //if convos are empty and stuff, just don't do anything, also if global enable off
    if (!globalEnable) {
        return;
    }
    if ((chatSessions == NULL) || ([chatSessions count] == 0)) {
        return;
    }

    CGPoint tempLoc = [recognizer locationInView:recognizer.view];
    CGPoint translation;//[recognizer translationInView:recognizer.view];
    if (tempLoc.x >= originalLocation.x) {
        translation = CGPointMake(tempLoc.x - originalLocation.x, originalLocation.y);
    } else {
        translation = CGPointMake(-1* (originalLocation.x - tempLoc.x), originalLocation.y);
    }
    unsigned int nextConvoIndex;

    //positive == right
    //negative == left
    if (switchShortSwipeDirections) {
        translation.x = -1 * translation.x;
    }
    if (translation.x > 0) {
        //is an ongoing swipe to the right
        rightPreviewView.center = CGPointMake(recognizer.view.frame.size.width+60, leftPreviewView.center.y);
        rightPreviewView.hidden = YES;

        nextConvoIndex = currentChatSessionIndex - 1;
        if (currentChatSessionIndex == 0) {
            if (wrapAroundEnabled) {
                nextConvoIndex = [chatSessions count] - 1 ;
            } else {
                nextConvoIndex = 0;
                //maybe show bounce animation here
            }
        }
        if (enableAnimations) {
            //show animations here

            if (![leftPreviewView isDescendantOfView:recognizer.view]) {
                //if not added to view, go ahead and grab the image and add it to the view
                if (previewImage == NULL) {
                    [self createPreviewImages];
                }
                [recognizer.view addSubview:leftPreviewView];

                leftContactNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(9, 15, 75, 50)];
                [leftContactNameLabel setTextColor:[UIColor blackColor]];
                [leftContactNameLabel setBackgroundColor:[UIColor clearColor]];
                [leftContactNameLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
                [leftContactNameLabel setNumberOfLines:4];
                [leftContactNameLabel setLineBreakMode:NSLineBreakByWordWrapping];
                [leftPreviewView addSubview:leftContactNameLabel];

                //add message label here
                leftMostRecentMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(9,69,75, 79)];
                [leftMostRecentMessageLabel setTextColor:[UIColor blackColor]];
                [leftMostRecentMessageLabel setBackgroundColor:[UIColor clearColor]];
                [leftMostRecentMessageLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 12.0f]];
                [leftMostRecentMessageLabel setNumberOfLines:10];
                [leftMostRecentMessageLabel setLineBreakMode:NSLineBreakByWordWrapping];
                [leftPreviewView addSubview:leftMostRecentMessageLabel];
            }

            // [leftPreviewView setConversation:[WAPconvos objectAtIndex:nextConvoIndex]];
            leftContactNameLabel.text = [[chatSessions objectAtIndex:nextConvoIndex] partnerName];
            leftMostRecentMessageLabel.text = [NSString stringWithFormat:@"%d", nextConvoIndex];
            //update message label here
            [recognizer.view bringSubviewToFront:leftPreviewView];
            leftPreviewView.hidden = NO;
            if ((translation.x > longSwipeDistance) && longSwipesEnabled) {
                leftContactNameLabel.text = @"Convo List";
                leftMostRecentMessageLabel.text = @"Release to Return to List.";
            }

            //actual animations

            int scalar;
            if (shortSwipeDistance > 120) {
                scalar = 1;
            } else {
                scalar = (120/shortSwipeDistance);
            }
            //float slideFactor = 0.1 * slideMult; // Increase for more of a slide
            CGPoint finalPoint = CGPointMake(-60 + (translation.x * scalar),
                                             leftPreviewView.center.y);
            finalPoint.x = MIN(finalPoint.x, 60);
            //finalPoint.y = MIN(MAX(finalPoint.y, 0), recognizer.view.bounds.size.height);
            if (translation.x > shortSwipeDistance+8) {
                leftPreviewView.alpha = 1.0f;
            } else {
                leftPreviewView.alpha = 0.75f;
            }

            leftPreviewView.center = finalPoint;

        }

    } else {
        //is an ongoing swipe left
        leftPreviewView.hidden = YES;
        leftPreviewView.center = CGPointMake(-60, leftPreviewView.center.y);
        nextConvoIndex = currentChatSessionIndex + 1;
        if (nextConvoIndex >= [chatSessions count]) {
            if (wrapAroundEnabled) {
                nextConvoIndex = 0;
            } else {
                nextConvoIndex = currentChatSessionIndex;
                //maybe display bounce animation here
            }
        }
        if (enableAnimations) {
            //show animations here

            //previewImage.imageOrientation = UIImageOrientationUpMirrored;
            if (![rightPreviewView isDescendantOfView:recognizer.view]) {
                if (flippedPreviewImage == NULL) {
                    [self createPreviewImages];
                }

                [recognizer.view addSubview:rightPreviewView];

                rightContactNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(39, 15, 75, 50)];
                [rightContactNameLabel setTextColor:[UIColor blackColor]];
                [rightContactNameLabel setBackgroundColor:[UIColor clearColor]];
                [rightContactNameLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
                [rightContactNameLabel setNumberOfLines:4];
                [rightContactNameLabel setLineBreakMode:NSLineBreakByWordWrapping];
                [rightPreviewView addSubview:rightContactNameLabel];

                rightMostRecentMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(39,69,75, 79)];
                [rightMostRecentMessageLabel setTextColor:[UIColor blackColor]];
                [rightMostRecentMessageLabel setBackgroundColor:[UIColor clearColor]];
                [rightMostRecentMessageLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 12.0f]];
                [rightMostRecentMessageLabel setNumberOfLines:10];
                [rightMostRecentMessageLabel setLineBreakMode:NSLineBreakByWordWrapping];
                [rightPreviewView addSubview:rightMostRecentMessageLabel];
            }

            // [rightPreviewView setConversation:[convos objectAtIndex:nextConvoIndex]];
            rightContactNameLabel.text = [[chatSessions objectAtIndex:nextConvoIndex] partnerName];
            rightMostRecentMessageLabel.text = [NSString stringWithFormat:@"%d", nextConvoIndex];
            [recognizer.view bringSubviewToFront:rightPreviewView];
            rightPreviewView.hidden = NO;

            if ((-1*translation.x > longSwipeDistance) && longSwipesEnabled) {
                //set to first convo
                //[rightPreviewView setConversation:[WAPconvos objectAtIndex:0]];
                rightContactNameLabel.text = @"0";
                //rightMostRecentMessageLabel.text = rightPreviewView.mostRecentMessage;
            }

            //actually animate ImageView here
            int scalar;
            if (shortSwipeDistance > 120) {
                scalar = 1;
            } else {
                scalar = (120/shortSwipeDistance);
            }
            CGPoint finalPoint = CGPointMake(recognizer.view.frame.size.width+60 + (translation.x * scalar), leftPreviewView.center.y);
            finalPoint.x = MAX(finalPoint.x, recognizer.view.frame.size.width - 60);
            //finalPoint.y = MIN(MAX(finalPoint.y, 0), recognizer.view.bounds.size.height);
            if (-1*translation.x > (shortSwipeDistance+8)) {
                rightPreviewView.alpha = 1.0f;
            } else {
                rightPreviewView.alpha = 0.75f;
            }

            rightPreviewView.center = finalPoint;
        }

    }
    //LIFTS FINGER



    if (recognizer.state == UIGestureRecognizerStateEnded) {

        // [cNavController popViewControllerAnimated:NO];
        // [cNavController pushViewController:[WAPconvos objectAtIndex:0] animated:NO];
        leftPreviewView.hidden = YES;
        rightPreviewView.hidden = YES;
        leftPreviewView.center = CGPointMake(-60, leftPreviewView.center.y);
        rightPreviewView.center = CGPointMake(recognizer.view.frame.size.width+60, rightPreviewView.center.y);




        if (translation.x > 0) {

            //ended swipe on right side

            if ((translation.x >= longSwipeDistance) && longSwipesEnabled) {
                //if long swipe right, show list
                if (switchShortSwipeDirections) {
                    //but if switched, show newest message
                    //update conversation list in case of new message
                    WAChatStorage *storage = [[%c(ChatManager) sharedManager] storage];
                    chatSessions = [storage chatSessions];

                    [cNavController popViewControllerAnimated:NO];
                    //change this line to work!
                    //push first chat
                    NSIndexPath *nextConvoIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
                    UITableView *table = [clViewController tableViewChats];
                    [clViewController tableView:table willSelectRowAtIndexPath:nextConvoIndexPath];
                    [clViewController tableView:table didSelectRowAtIndexPath:nextConvoIndexPath];

                    //[cNavController pushViewController:[WAPconvos objectAtIndex:0] animated:NO];
                } else {
                    [cNavController popViewControllerAnimated:YES];
                }
                return;
            }

            if (translation.x >= shortSwipeDistance) {
                //this is short swipe: show next convo
                [cNavController popViewControllerAnimated:NO];


                NSIndexPath *nextConvoIndexPath = [NSIndexPath indexPathForRow:nextConvoIndex inSection:1];
                UITableView *table = [clViewController tableViewChats];
                [clViewController tableView:table willSelectRowAtIndexPath:nextConvoIndexPath];
                [clViewController tableView:table didSelectRowAtIndexPath:nextConvoIndexPath];
                //[cNavController pushViewController:[WAPconvos objectAtIndex:nextConvoIndex] animated:YES];
                return;
            }

        } else {

            //ended swipe on left side
            //long swipe stuff left
            translation.x = -1 * translation.x;


            if ((translation.x >= longSwipeDistance) && longSwipesEnabled) {
                if (switchShortSwipeDirections) {
                    [cNavController popViewControllerAnimated:YES];
                } else {
                     WAChatStorage *storage = [[%c(ChatManager) sharedManager] storage];
                     chatSessions = [storage chatSessions];

                    [cNavController popViewControllerAnimated:NO];
                    //change this line!
                    NSIndexPath *nextConvoIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
                    UITableView *table = [clViewController tableViewChats];
                    [clViewController tableView:table willSelectRowAtIndexPath:nextConvoIndexPath];
                    [clViewController tableView:table didSelectRowAtIndexPath:nextConvoIndexPath];
                    //[cNavController pushViewController:[WAPconvos objectAtIndex:0] animated:NO];
                }
                return;
            }
            //short swipe stuff left
            if (translation.x >= shortSwipeDistance) {
                //this is short swipe: show next convo
                [cNavController popViewControllerAnimated:NO];
                //this one too!!
                NSIndexPath *nextConvoIndexPath = [NSIndexPath indexPathForRow:nextConvoIndex inSection:1];
                UITableView *table = [clViewController tableViewChats];
                [clViewController tableView:table willSelectRowAtIndexPath:nextConvoIndexPath];
                [clViewController tableView:table didSelectRowAtIndexPath:nextConvoIndexPath];
                //[cNavController pushViewController:[WAPconvos objectAtIndex:nextConvoIndex] animated:YES];
                return;
            }
        }

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"chatSessions"
            message:[NSString stringWithFormat:@"%@ \n %d", chatSessions, currentChatSessionIndex]
            delegate:nil
            cancelButtonTitle:@"K"
            otherButtonTitles:nil];
        [alert show];
        [alert release];


    }
}


//delegate methods
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}
@end

static MSWAPSwipeDelegate *swipeDelegateWAP;

%hook ChatListViewController

- (void)viewDidLoad
{
    %orig;
    clViewController = self;

    // UITableView *table = [self tableViewChats];
    // //NSInteger numberOfSections = [table numberOfSections];
    // //NSMutableArray *tableArray = [[NSMutableArray alloc] init];
    // NSMutableArray *JIDArray = [[NSMutableArray alloc] init];
    // //start at 1 to ignore first section, which is just buttons.
    // for (int i = 1; i < [table numberOfSections]; ++i)
    // {
    //     //for each section, grab number of rows
    //     //[tableArray addObject:[NSNumber numberWithInt:[table numberOfRowsInSection:i]]];
    //     for (int j = 0; j < [table numberOfRowsInSection:i]; ++j)
    //     {
    //         //now for each row, call did select and then pop the view controller?
    //         //- (void)tableView:(id)fp8 didSelectRowAtIndexPath:(id)fp12;
    //         NSIndexPath *tempIndexPath = [NSIndexPath indexPathForRow:j inSection:i];
    //         [self tableView:table didSelectRowAtIndexPath:tempIndexPath];
    //         [JIDArray addObject:[self selectedChatJID]];
    //         [cNavController popViewControllerAnimated:NO];

    //     }
    // }
    //now create array of viewControllers (convos) from chatViewControllers dict
    WAChatStorage *storage = [[%c(ChatManager) sharedManager] storage];
    chatSessions = [storage chatSessions];

}

- (void)tableView:(id)fp8 didSelectRowAtIndexPath:(id)fp12
{
    // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"didSelectRowAtIndexPath"
    //     message:[NSString stringWithFormat:@"%@", fp12]
    //     delegate:nil
    //     cancelButtonTitle:@"K"
    //     otherButtonTitles:nil];
    // [alert show];
    // [alert release];
    %orig;
}
- (id)tableView:(id)fp8 willSelectRowAtIndexPath:(id)fp12
{
    // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"willSelectRowAtIndexPath"
    //     message:[NSString stringWithFormat:@"%@", fp12]
    //     delegate:nil
    //     cancelButtonTitle:@"K"
    //     otherButtonTitles:nil];
    // [alert show];
    // [alert release];
    return %orig;
}



%end


%hook ChatManager

- (void)chatStorageDidDeleteChatSessions:(id)fp8
{
    %orig;
    //grab the chatSessions for use later
    WAChatStorage *storage = [[%c(ChatManager) sharedManager] storage];
    chatSessions = [storage chatSessions];

}


- (void)chatStorage:(id)fp8 didAddMessages:(id)fp12
{
    //called on send and receive?
    //update update list of conversations
    %orig;
    //grab the chatSessions for use later
    WAChatStorage *storage = [[%c(ChatManager) sharedManager] storage];
    chatSessions = [storage chatSessions];


}

// - (BOOL)isDelegateRegistered:(id)fp8
// {
//     return %orig;
//     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"isDelegateRegistered"
//         message:[NSString stringWithFormat:@"%@", fp8]
//         delegate:nil
//         cancelButtonTitle:@"K"
//         otherButtonTitles:nil];
//     [alert show];
//     [alert release];
// }

- (void)unregisterDelegate:(id)fp8
{
    //grab the chatSessions for use later - possibly remove
    %orig;
    WAChatStorage *storage = [[%c(ChatManager) sharedManager] storage];
    chatSessions = [storage chatSessions];


}
- (void)registerDelegate:(id)fp8
{
    //grab the chatSessions for use later
    %orig;
    WAChatStorage *storage = [[%c(ChatManager) sharedManager] storage];
    chatSessions = [storage chatSessions];

}

%end

//add delegate method to override and allow both scrolling and panning
%hook WAScrollView
%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}
%end

%hook ConversationViewController

- (void)viewDidLoad
{

    //grab the scrollview
    WAScrollView *scrollViewChat = [self scrollViewChat];
    //will be using delegate multiple times, sp if it's not already created, create it

    if (!swipeDelegateWAP)
        swipeDelegateWAP = [[MSWAPSwipeDelegate alloc] init];
    //should be default, but just in case, yea?
    scrollViewChat.userInteractionEnabled = YES;

    //create the recognizer and assign it to the view and our delegate
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:swipeDelegateWAP action:@selector(messageSwiperWAP_handlePan:)];
    panRecognizer.maximumNumberOfTouches = 1;
    [scrollViewChat addGestureRecognizer:panRecognizer];

    //test create invisible view to display previews on


    %orig;

}

//viewControllers stay open for the entirety of the app, unless it's closed. If closed, the view controllers are unloaded

%end

%hook ChatNavigationController

- (void)pushViewController:(UIViewController *)controller animated:(BOOL)animated
{



    //update chatViewControllers
    WAChatStorage *storage = [[%c(ChatManager) sharedManager] storage];
    chatSessions = [storage chatSessions];
    //get new current one based on push
    currentChatSessionIndex = [chatSessions indexOfObject:(WAChatSession *)[controller valueForKey:@"_chatSession"]];
    %orig;

}

// - (void)popViewControllerAnimated:(BOOL)animated
// {
//     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"popViewControllerAnimated"
//         message:[NSString stringWithFormat:@"%@\n%@", self, cNavController]
//         delegate:nil
//         cancelButtonTitle:@"K"
//         otherButtonTitles:nil];
//     [alert show];
//     [alert release];
//     %orig;
// }

- (id)init
{
    cNavController = self;
    return %orig;

    //[cNavController pushViewController:testController animated:YES];
}
- (void)reloadViewControllers
{
    %orig;
    //grab the chatSessions for use later
    WAChatStorage *storage = [[%c(ChatManager) sharedManager] storage];
    chatSessions = [storage chatSessions];
    // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"storage"
    //     message:[NSString stringWithFormat:@"%@", chatSessions]
    //     delegate:nil
    //     cancelButtonTitle:@"K"
    //     otherButtonTitles:nil];
    // [alert show];
    // [alert release];

    // ConversationViewController *testController = [[%c(ConversationViewController) alloc] initWithChatSession:[chatSessions objectAtIndex:0]];
    // [[%c(ChatManager) sharedManager] registerDelegate:testController];
    //-(void)pushViewController:(id)controller transition:(int)transition;
    //[cNavController pushViewController:testController transition:0];

}

%end

%hook WhatsAppAppDelegate

- (id)init {
    whatsAppAppDelegate = self;
    return %orig;
}

%end




%end

//END WHATS APP STUFF





%ctor {

   //init prefs again
    preferences = [[NSDictionary alloc] initWithContentsOfFile:PrefPath];
    if (preferences == nil) {
        globalEnable = YES;
    } else {
        //if the option exists make it that, else default
        if ([preferences valueForKey:@"globalEnable"] != nil) {
            globalEnable = [[preferences valueForKey:@"globalEnable"] boolValue];
        } else {
            globalEnable = YES;
        }
        if ([preferences valueForKey:@"customSwipeSettings"] != nil) {
            customSwipeSettings = [[preferences valueForKey:@"customSwipeSettings"] boolValue];
        } else {
            customSwipeSettings = NO;
        }
        if (customSwipeSettings) {
            if ([preferences valueForKey:@"switchShortSwipeDirections"] != nil) {
                switchShortSwipeDirections = [[preferences valueForKey:@"switchShortSwipeDirections"] boolValue];
            } else {
                switchShortSwipeDirections = NO;
            }
            if ([preferences valueForKey:@"wrapAroundEnabled"] != nil) {
                wrapAroundEnabled = [[preferences valueForKey:@"wrapAroundEnabled"] boolValue];
            } else {
                wrapAroundEnabled = NO;
            }
            if ([preferences valueForKey:@"enableAnimations"] != nil) {
                enableAnimations = [[preferences valueForKey:@"enableAnimations"] boolValue];
            } else {
                enableAnimations = YES;
            }
            if ([preferences valueForKey:@"longSwipesEnabled"] != nil) {
                longSwipesEnabled = [[preferences valueForKey:@"longSwipesEnabled"] boolValue];
            } else {
                longSwipesEnabled = YES;
            }
            if ([preferences valueForKey:@"hideBackButton"] != nil) {
                hideBackButton = [[preferences valueForKey:@"hideBackButton"] boolValue];
            } else {
                hideBackButton = NO;
            }
            if ([preferences valueForKey:@"updateFrequently"] != nil) {
                updateFrequently = [[preferences valueForKey:@"updateFrequently"] boolValue];
            } else {
                updateFrequently = YES;
            }
            if ([preferences valueForKey:@"longSwipeDistance"] != nil) {
                longSwipeDistance = [[preferences valueForKey:@"longSwipeDistance"] intValue];
            } else {
                longSwipeDistance = 200;
            }
            if ([preferences valueForKey:@"shortSwipeDistance"] != nil) {
                shortSwipeDistance = [[preferences valueForKey:@"shortSwipeDistance"] intValue];
            } else {
                shortSwipeDistance = 50;
            }
        } else {
            //defaults
            switchShortSwipeDirections = NO;
            wrapAroundEnabled = NO;
            enableAnimations = YES;
            longSwipesEnabled = YES;
            hideBackButton = NO;
            updateFrequently = YES;
            longSwipeDistance = 200;
            shortSwipeDistance = 50;
        }
    }
    [preferences release];

    if (globalEnable) {
        %init;
        %init(WhatsAppStuff);
    }


    // [tempglobalEnable release];
    // [tempcustomSwipeSettings release];

    // if(something) %init(HelloWorld); //This makes the hello world group functional based on an if statement, just for code management.
    //make a group for WhatsApp and only init if WhatsApp is running or something
    //after making this,
    //also possibly make group for iOS5 to stop crashes
    //determine if the app is WhatsApp
    //NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
}
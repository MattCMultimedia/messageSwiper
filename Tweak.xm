
#import <ChatKit/CKTranscriptController.h>
#import <ChatKit/CKConversationList.h>
#import <MobileSMS/CKMessagesController.h>
#import <UIKit/UIGestureRecognizer.h>
#import <UIKit/UIKit.h>



//static NSString *test;
static NSMutableArray *convos = [[NSMutableArray alloc] init];
static CKMessagesController *ckMessagesController;
static unsigned int currentConvoIndex = 0;
static UIView *backPlacard;
static BOOL isFirstLaunch = YES;
static BOOL customSwipeSettings = NO;


static BOOL switchShortSwipeDirections = NO;
static BOOL longSwipesEnabled = YES;
static BOOL wrapAroundEnabled = YES;
static BOOL enableAnimations = YES;

//values
static int longSwipeDistance = 200;
static int shortSwipeDistance = 50;



static UILabel *leftContactNameLabel;
static UILabel *rightContactNameLabel;
static UILabel *leftMostRecentMessageLabel;
static UILabel *rightMostRecentMessageLabel;
static UIImage *previewImage;
static UIImage *flippedPreviewImage;

static CGPoint originalLocation;




static NSString *getsuffix() {

    if ([[UIScreen mainScreen] scale] < 2.0f)
        return @"";

    return @"@2x";

}



//animation UIView interfaces and stuff
@interface MSNextMessagePreviewView : UIImageView

@property (assign) UIImage *contactImage;
@property (assign) NSString *contactName;
@property (assign) NSString *mostRecentMessage;

- (void) setConversation:(CKConversation *)convo;

@end
@implementation MSNextMessagePreviewView
@synthesize contactImage = _contactImage;
@synthesize contactName = _contactName;
@synthesize mostRecentMessage = _mostRecentMessage;

- (void) setConversation:(CKConversation *)convo
{
    self.contactName = [convo name];
    //would set mostRecentMessage here
}

- (void)baseInit {
    _contactName = NULL;
    _contactName = @"Unknown";
    _mostRecentMessage = @"This is my most recent message, yay! It's got a lot of text cause I don't know how to not talk lollololo";
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
static MSNextMessagePreviewView *rightPreviewView = [[MSNextMessagePreviewView alloc] initWithFrame:CGRectMake(320,10,120,160)];




@interface MSSwipeDelegate : NSObject <UIGestureRecognizerDelegate>

-(void)messageSwiper_handlePan:(UIPanGestureRecognizer *)recognizer;
-(void)createPreviewImages;
@end
@implementation MSSwipeDelegate

-(void)createPreviewImages {
    NSString *previewImagePathBundle = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/MessageSwiper/"];
    NSString *finalPreviewImagePath = [NSString stringWithFormat:@"%@/previewImage%@.png", previewImagePathBundle, getsuffix()];//, previewImagePathBundle ]]; //getsuffix()]];
    previewImage = [UIImage imageWithContentsOfFile:finalPreviewImagePath];
    UIImageOrientation flippedOrientation = UIImageOrientationUpMirrored;
    flippedPreviewImage = [UIImage imageWithCGImage:previewImage.CGImage scale:previewImage.scale orientation:flippedOrientation];
    // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Test"
    //     message:[NSString stringWithFormat:@"%@", flippedPreviewImage]
    //     delegate:nil
    //     cancelButtonTitle:@"K"
    //     otherButtonTitles:nil];
    // [alert show];
    // [alert release];
    leftPreviewView.image = previewImage;
    rightPreviewView.image = flippedPreviewImage;

    // [previewImagePathBundle release];
    // [finalPreviewImagePath release];
}

-(void)messageSwiper_handlePan:(UIPanGestureRecognizer *)recognizer
{

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        //if new touch
        originalLocation = [recognizer locationInView:backPlacard];

    }
    //if convos are empty and stuff, just don't do anything
    if ((convos == NULL) || ([convos count] == 0)) {
        return;
    }
    CGPoint tempLoc = [recognizer locationInView:backPlacard];
    CGPoint translation;//[recognizer translationInView:backPlacard];
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
        //rightPreviewView.center = CGPointMake(320, leftPreviewView.center.y);
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

            if (![leftPreviewView isDescendantOfView:backPlacard]) {
                //if not added to view, go ahead and grab the image and add it to the view
                if (previewImage == NULL) {
                    [self createPreviewImages];
                }
                [backPlacard addSubview:leftPreviewView];

                leftContactNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 15, 75, 50)];
                [leftContactNameLabel setTextColor:[UIColor blackColor]];
                [leftContactNameLabel setBackgroundColor:[UIColor clearColor]];
                [leftContactNameLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
                [leftContactNameLabel setNumberOfLines:4];
                [leftPreviewView addSubview:leftContactNameLabel];

                //add message label here
                leftMostRecentMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(8,69,75, 80)];
                [leftMostRecentMessageLabel setTextColor:[UIColor blackColor]];
                [leftMostRecentMessageLabel setBackgroundColor:[UIColor clearColor]];
                [leftMostRecentMessageLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
                [leftMostRecentMessageLabel setNumberOfLines:10];
                [leftPreviewView addSubview:leftMostRecentMessageLabel];
            }
            [leftPreviewView setConversation:[convos objectAtIndex:nextConvoIndex]];
            leftContactNameLabel.text = leftPreviewView.contactName;
            leftMostRecentMessageLabel.text = leftPreviewView.mostRecentMessage;
            //update message label here
            [backPlacard bringSubviewToFront:leftPreviewView];
            leftPreviewView.hidden = NO;

            //actual animations
            // CGPoint velocity = [recognizer velocityInView:backPlacard];
            // CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
            // CGFloat slideMult = magnitude / 200;

            //float slideFactor = 0.1 * slideMult; // Increase for more of a slide
            CGPoint finalPoint = CGPointMake(leftPreviewView.center.x + translation.x,
                                             leftPreviewView.center.y);
            finalPoint.x = MIN(finalPoint.x, shortSwipeDistance + 8);
            //finalPoint.y = MIN(MAX(finalPoint.y, 0), backPlacard.bounds.size.height);

            [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                leftPreviewView.center = finalPoint;
            } completion:nil];
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
            if (![rightPreviewView isDescendantOfView:backPlacard]) {
                if (flippedPreviewImage == NULL) {
                    [self createPreviewImages];
                }

                [backPlacard addSubview:rightPreviewView];

                rightContactNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(38, 15, 75, 50)];
                [rightContactNameLabel setTextColor:[UIColor blackColor]];
                [rightContactNameLabel setBackgroundColor:[UIColor clearColor]];
                [rightContactNameLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
                [rightContactNameLabel setNumberOfLines:4];
                [rightPreviewView addSubview:rightContactNameLabel];

                rightMostRecentMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(38,69,75, 80)];
                [rightMostRecentMessageLabel setTextColor:[UIColor blackColor]];
                [rightMostRecentMessageLabel setBackgroundColor:[UIColor clearColor]];
                [rightMostRecentMessageLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
                [rightMostRecentMessageLabel setNumberOfLines:10];
                [rightPreviewView addSubview:rightMostRecentMessageLabel];
            }
            [rightPreviewView setConversation:[convos objectAtIndex:nextConvoIndex]];
            rightContactNameLabel.text = rightPreviewView.contactName;
            rightMostRecentMessageLabel.text = rightPreviewView.mostRecentMessage;
            [backPlacard bringSubviewToFront:rightPreviewView];
            rightPreviewView.hidden = NO;

            //actually animate ImageView here

        }

    }
    //LIFTS FINGER

    //once user lifts finger, do whatever should happen within swipe range
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        //remove the UIView when this gets called
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"translation"
            message:[NSString stringWithFormat:@"%@", NSStringFromCGPoint(translation)]
            delegate:nil
            cancelButtonTitle:@"K"
            otherButtonTitles:nil];
        [alert show];
        [alert release];

        leftPreviewView.hidden = YES;
        rightPreviewView.hidden = YES;
        leftPreviewView.center = CGPointMake(-120-(leftPreviewView.center.x/2), leftPreviewView.center.y);
        // rightPreviewView.center = CGPointMake(320, leftPreviewView.center.y);




        if (translation.x > 0) {

            //ended swipe on right side
            if (!customSwipeSettings) {
                //whatever the value from that thing is
                longSwipeDistance = 200;
                shortSwipeDistance = 50;
            }
            if ((translation.x >= 200) && longSwipesEnabled) {
                //if long swipe right, show list
                if (switchShortSwipeDirections) {
                    convos = [[%c(CKConversationList) sharedConversationList] activeConversations];
                    [ckMessagesController showConversation:[convos objectAtIndex:0] animate:YES];
                } else {
                    [ckMessagesController showConversationList:YES];
                }
                return;
            }

            if (translation.x >= 50) {
                //this is short swipe: show next convo
                [ckMessagesController showConversation:[convos objectAtIndex:nextConvoIndex] animate:YES];
                return;
            }

        } else {

            //ended swipe on left side
            //long swipe stuff left
            translation.x = -1 * translation.x;
            if (!customSwipeSettings) {
                //whatever the value from that thing is
                longSwipeDistance = 200;
                shortSwipeDistance = 50;
            }

            if ((translation.x >= 200) && longSwipesEnabled) {
                if (switchShortSwipeDirections) {
                    [ckMessagesController showConversationList:YES];
                } else {
                    convos = [[%c(CKConversationList) sharedConversationList] activeConversations];
                    [ckMessagesController showConversation:[convos objectAtIndex:0] animate:YES];
                }
                return;
            }
            //short swipe stuff left
            if (translation.x >= 50) {
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
            swipeDelegate = [[MSSwipeDelegate alloc] init];
            //just in case it isn't default
            backPlacard.userInteractionEnabled = YES;

            //testing pan gesture recognizer - works pretty well
            UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:swipeDelegate action:@selector(messageSwiper_handlePan:)];
            panRecognizer.maximumNumberOfTouches = 1;
            [backPlacard addGestureRecognizer:panRecognizer];

            //possibly add another panRecognizer to allow for two finger longSwipes
        }
    }

    %orig;

}
%end

//
%hook CKMessagesController
-(void)_conversationLeft:(id)left
{
    convos = [[%c(CKConversationList) sharedConversationList] activeConversations];
    %orig;
}

//
-(void)showConversation:(id)conversation animate:(BOOL)animate
{
    //resets currentConvoIndex
    // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"flippedPreviewImage"
    //     message:[NSString stringWithFormat:@"%@", flippedPreviewImage]
    //     delegate:nil
    //     cancelButtonTitle:@"K"
    //     otherButtonTitles:nil];
    // [alert show];
    // [alert release];

    currentConvoIndex = [convos indexOfObject:conversation];
    %orig;
}
-(void)showConversation:(id)conversation animate:(BOOL)animate forceToTranscript:(BOOL)transcript
{
    //resets currentConvoIndex
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
    convos = [[%c(CKConversationList) sharedConversationList] activeConversations];
    ckMessagesController = self;
    return %orig;
}

%end


%ctor {
    //check pref to see if tweak should init if true, %init, else do nothing?
    //pref file path
    NSString *prefPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.mattcmultimedia.messageswiper.plist"];
    NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:prefPath];
    BOOL globalEnable = [[preferences objectForKey:@"globalEnable"] boolValue];
    if (globalEnable) {
        %init;
        //passed globalInit; now record rest of preferences
        customSwipeSettings = [[preferences objectForKey:@"customSwipeSettings"] boolValue];
        if (customSwipeSettings) {
            //now grab the rest of the values
            switchShortSwipeDirections = [[preferences objectForKey:@"switchShortSwipeDirections"] boolValue];
            wrapAroundEnabled = [[preferences objectForKey:@"wrapAroundEnabled"] boolValue];
            longSwipesEnabled = [[preferences objectForKey:@"longSwipesEnabled"] boolValue];
            enableAnimations = [[preferences objectForKey:@"enableAnimations"] boolValue];
            longSwipeDistance = [[preferences objectForKey:@"longSwipeDistance"] intValue];
            shortSwipeDistance = [[preferences objectForKey:@"shortSwipeDistance"] intValue];
        }
    }

    [prefPath release];
    [preferences release];
    // if(something) %init(HelloWorld); //This makes the hello world group functional based on an if statement, just for code management.
    //make a group for WhatsApp and only init if WhatsApp is running or something
    //also possibly make group for iOS5 to stop crashes
    //determine if the app is WhatsApp
    //NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
}
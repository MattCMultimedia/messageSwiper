
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


static UILabel *rightContactNameLabel;
static UILabel *leftContactNameLabel;


//animation UIView interfaces and stuff
@interface MSNextMessagePreviewView : UIView

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
}

- (void)baseInit {
    _contactName = NULL;
    _contactName = @"Unknown";
    _mostRecentMessage = @"This is my most recent message, yay!";
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

static MSNextMessagePreviewView *leftPreviewView = [[MSNextMessagePreviewView alloc] initWithFrame:CGRectMake(0,50,200,75)];
static MSNextMessagePreviewView *rightPreviewView = [[MSNextMessagePreviewView alloc] initWithFrame:CGRectMake(100,50,200,75)];




@interface MSSwipeDelegate : NSObject <UIGestureRecognizerDelegate>

-(void)messageSwiper_handlePan:(UIPanGestureRecognizer *)recognizer;
@end
@implementation MSSwipeDelegate

-(void)messageSwiper_handlePan:(UIPanGestureRecognizer *)recognizer
{
    //if convos are empty and stuff, just don't do anything
    if (convos == NULL) {
        return;
    }
    CGPoint translation = [recognizer translationInView:backPlacard];
    unsigned int nextConvoIndex;

    //positive == right
    //negative == left
    if (switchShortSwipeDirections) {
        translation.x = -1 * translation.x;
    }
    if (translation.x > 0) {
        //is an ongoing swipe to the right

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

                [leftPreviewView setBackgroundColor:[UIColor redColor]];
                [backPlacard addSubview:leftPreviewView];

                leftContactNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 75)];

                [leftContactNameLabel setTextColor:[UIColor blackColor]];
                [leftContactNameLabel setBackgroundColor:[UIColor clearColor]];
                [leftContactNameLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
                [leftPreviewView addSubview:leftContactNameLabel];
            }
            [leftPreviewView setConversation:[convos objectAtIndex:nextConvoIndex]];
            leftContactNameLabel.text = leftPreviewView.contactName;
            [backPlacard bringSubviewToFront:leftPreviewView];
            leftPreviewView.hidden = NO;
        }

    } else {
        //is an ongoing swipe left
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


            if (![rightPreviewView isDescendantOfView:backPlacard]) {

                [rightPreviewView setBackgroundColor:[UIColor redColor]];
                [backPlacard addSubview:rightPreviewView];

                rightContactNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 75)];

                [rightContactNameLabel setTextColor:[UIColor blackColor]];
                [rightContactNameLabel setBackgroundColor:[UIColor clearColor]];
                [rightContactNameLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 14.0f]];
                [rightPreviewView addSubview:rightContactNameLabel];
            }
            [rightPreviewView setConversation:[convos objectAtIndex:nextConvoIndex]];
            rightContactNameLabel.text = rightPreviewView.contactName;
            [backPlacard bringSubviewToFront:rightPreviewView];
            rightPreviewView.hidden = NO;

        }

    }

    //once user lifts finger, do whatever should happen within swipe range
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        //remove the UIView when this gets called
        leftPreviewView.hidden = YES;
        rightPreviewView.hidden = YES;




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

            //add gesture recognizer here
            // UISwipeGestureRecognizer *swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:swipeDelegate action:@selector(messageSwiper_handleSwipeLeft:)];
            // swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
            // swipeLeftRecognizer.delegate = swipeDelegate;
            // swipeLeftRecognizer.numberOfTouchesRequired = 1;
            // [backPlacard addGestureRecognizer:swipeLeftRecognizer];

            // UISwipeGestureRecognizer *swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:swipeDelegate action:@selector(messageSwiper_handleSwipeRight:)];
            // swipeRightRecognizer.direction = (UISwipeGestureRecognizerDirectionRight);
            // swipeRightRecognizer.delegate = swipeDelegate;
            // swipeRightRecognizer.numberOfTouchesRequired = 1;
            // [backPlacard addGestureRecognizer:swipeRightRecognizer];

            //testing pan gesture recognizer - works pretty well
            UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:swipeDelegate action:@selector(messageSwiper_handlePan:)];
            panRecognizer.maximumNumberOfTouches = 1;
            [backPlacard addGestureRecognizer:panRecognizer];

            //possible add another panRecognizer to allow for two finger longSwipes
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
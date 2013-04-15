
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
// static BOOL globalEnable = YES;
// static BOOL enableLongSwipes = YES;
static BOOL switchShortSwipeDirections = NO;
static BOOL longSwipesEnabled = YES;

//values
static int longSwipeDistance = 200;
static int shortSwipeDistance = 50;

@interface MSSwipeDelegate : NSObject <UIGestureRecognizerDelegate>

-(void)messageSwiper_handlePan:(UIPanGestureRecognizer *)recognizer;
@end
@implementation MSSwipeDelegate

-(void)messageSwiper_handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:backPlacard];

    //positive == right
    //negative == left
    if (switchShortSwipeDirections) {
        translation.x = -1 * translation.x;
    }
    if (translation.x > 0) {
        //is an ongoing swipe to the right
        //show animations here
    } else {
        //is an ongoing swipe left
        //show animations here
    }

    //once user lifts finger, do whatever should happen within swipe range
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (translation.x > 0) {

            //ended swipe on right side
            if (customSwipeSettings) {
                //whatever the value from that thing is
                longSwipeDistance = 200;
                shortSwipeDistance = 100;
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
                unsigned int nextConvoIndex = 0;
                if (currentConvoIndex == 0) {
                    nextConvoIndex = [convos count] - 1 ;
                } else {
                    nextConvoIndex = currentConvoIndex - 1;
                }

                [ckMessagesController showConversation:[convos objectAtIndex:nextConvoIndex] animate:YES];
            }

        } else {
            //ended swipe on left side
            //ong swipe stuff left
            translation.x = -1 * translation.x;
            if (customSwipeSettings) {
                //whatever the value from that thing is
                longSwipeDistance = 200;
                shortSwipeDistance = 100;
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
                unsigned int nextConvoIndex = currentConvoIndex + 1;
                if (nextConvoIndex >= [convos count]) {
                    nextConvoIndex = 0;
                }

                [ckMessagesController showConversation:[convos objectAtIndex:nextConvoIndex] animate:YES];

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

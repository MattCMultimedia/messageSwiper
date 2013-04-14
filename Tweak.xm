/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
*/

#import <ChatKit/CKConversation.h>
#import <ChatKit/CKTranscriptController.h>
#import <ChatKit/CKConversationList.h>
#import <MobileSMS/CKMessagesController.h>
#import <UIKit/UIGestureRecognizer.h>
#import <UIKit/UIKit.h>
#import <MobileSMS/SMSApplication.h>
// #import <UIKit/UIGestureRecognizerDelegate.h>

//static NSString *test;
static NSMutableArray *convos = [[NSMutableArray alloc] init];
static CKMessagesController *ckMessagesController;
static unsigned int currentConvoIndex = 0;
static UIView *backPlacard;
static BOOL isFirstLaunch = YES;

@interface MSSwipeDelegate : NSObject <UIGestureRecognizerDelegate>
-(void)messageSwiper_handleSwipeLeft:(UISwipeGestureRecognizer *)recognizer;
-(void)messageSwiper_handleSwipeRight:(UISwipeGestureRecognizer *)recognizer;
-(void)messageSwiper_handlePan:(UIPanGestureRecognizer *)recognizer;
@end
@implementation MSSwipeDelegate
-(void)messageSwiper_handleSwipeLeft:(UISwipeGestureRecognizer *)recognizer
    {
        //increment
        // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Left"
        //     message:[NSString stringWithFormat:@"%@", recognizer]
        //     delegate:nil
        //     cancelButtonTitle:@"K"
        //     otherButtonTitles:nil];
        // [alert show];
        // [alert release];

        unsigned int nextConvoIndex = currentConvoIndex + 1;
        if (nextConvoIndex >= [convos count]) {
            nextConvoIndex = 0;
        }


        [ckMessagesController showConversation:[convos objectAtIndex:nextConvoIndex] animate:YES];

    }

-(void)messageSwiper_handleSwipeRight:(UISwipeGestureRecognizer *)recognizer
    {
        //decrement
        //CGPoint translation = [recognizer translationInView:recognizer.view];
        // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"right"
        //     message:[NSString stringWithFormat:@"%@", recognizer]
        //     delegate:nil
        //     cancelButtonTitle:@"K"
        //     otherButtonTitles:nil];
        // [alert show];
        // [alert release];

        unsigned int nextConvoIndex = 0;
        if (currentConvoIndex == 0) {
            nextConvoIndex = [convos count] - 1 ;
        } else {
            nextConvoIndex = currentConvoIndex - 1;
        }

        [ckMessagesController showConversation:[convos objectAtIndex:nextConvoIndex] animate:YES];


    }
-(void)messageSwiper_handlePan:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint translation = [recognizer translationInView:backPlacard];
        if (translation.x >= 200) {
            [ckMessagesController showConversationList:YES];
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
    if (isFirstLaunch) {
        backPlacard = self.view;
        if (backPlacard) {
            isFirstLaunch = NO;
            swipeDelegate = [[MSSwipeDelegate alloc] init];
            backPlacard.userInteractionEnabled = YES;
            // UIView *overlay = [[UIView alloc] initWithFrame:[backPlacard frame]];
            // [overlay setBackgroundColor:[UIColor redColor]];
            // [backPlacard addSubview:overlay];

            //add gesture recognizer here
            UISwipeGestureRecognizer *swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:swipeDelegate action:@selector(messageSwiper_handleSwipeLeft:)];
            swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
            swipeLeftRecognizer.delegate = swipeDelegate;
            swipeLeftRecognizer.numberOfTouchesRequired = 1;
            [backPlacard addGestureRecognizer:swipeLeftRecognizer];

            UISwipeGestureRecognizer *swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:swipeDelegate action:@selector(messageSwiper_handleSwipeRight:)];
            swipeRightRecognizer.direction = (UISwipeGestureRecognizerDirectionRight);
            swipeRightRecognizer.delegate = swipeDelegate;
            swipeRightRecognizer.numberOfTouchesRequired = 1;
            [backPlacard addGestureRecognizer:swipeRightRecognizer];

            //testing pan gesture recognizer
            UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:swipeDelegate action:@selector(messageSwiper_handlePan:)];
            panRecognizer.maximumNumberOfTouches = 1;
            [backPlacard addGestureRecognizer:panRecognizer];
        }
    }

    %orig;

}
%end


%hook SMSApplication

-(BOOL)application:(id)application didFinishLaunchingWithOptions:(id)options
{
    convos = [[%c(CKConversationList) sharedConversationList] activeConversations];
    return %orig;
}
// -(void)dealloc
// {
//     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"dealloc"
//         message:[NSString stringWithFormat:@"%@", @"Test"]
//         delegate:nil
//         cancelButtonTitle:@"K"
//         otherButtonTitles:nil];
//     [alert show];
//     [alert release];
//     %orig;
// }

%end

%hook CKConversation

- (id)init
{
    //log all new conversations - works on init - TODO: test on the fly
    //[convos addObject:self];

    return %orig;
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
    // UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"index"
    //     message:[NSString stringWithFormat:@"%@ \n\n\n %@", [[%c(CKConversationList) sharedConversationList] activeConversations], convos]
    //     delegate:nil
    //     cancelButtonTitle:@"K"
    //     otherButtonTitles:nil];
    // [alert show];
    // [alert release];


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
//grabs the ckMessagesController object - could probably be replaces with %c(CKMessagesController)
-(id)init
{
    ckMessagesController = self;
    return %orig;
}

%end

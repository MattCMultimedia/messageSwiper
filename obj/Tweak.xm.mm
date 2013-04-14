#line 1 "Tweak.xm"



































#import <ChatKit/CKConversation.h>
#import <ChatKit/CKTranscriptController.h>
#import <ChatKit/CKConversationList.h>
#import <MobileSMS/CKMessagesController.h>
#import <UIKit/UIGestureRecognizer.h>
#import <UIKit/UIKit.h>
#import <MobileSMS/SMSApplication.h>



static NSMutableArray *convos = [[NSMutableArray alloc] init];
static CKMessagesController *ckMessagesController;
static unsigned int currentConvoIndex = 0;
static UIView *backPlacard;
static BOOL isFirstLaunch = YES;

@interface MSSwipeDelegate : NSObject <UIGestureRecognizerDelegate>
-(void)messageSwiper_handleSwipeLeft:(UISwipeGestureRecognizer *)recognizer;
-(void)messageSwiper_handleSwipeRight:(UISwipeGestureRecognizer *)recognizer;
@end
@implementation MSSwipeDelegate

-(void)messageSwiper_handleSwipeLeft:(UISwipeGestureRecognizer *)recognizer {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Left"
            message:[NSString stringWithFormat:@"%@", recognizer]
            delegate:nil
            cancelButtonTitle:@"K"
            otherButtonTitles:nil];
        [alert show];
        [alert release];

        unsigned int nextConvoIndex = currentConvoIndex + 1;
        if (nextConvoIndex >= [convos count]) {
            nextConvoIndex = 0;
        }


        [ckMessagesController showConversation:[convos objectAtIndex:nextConvoIndex] animate:YES];

    }


-(void)messageSwiper_handleSwipeRight:(UISwipeGestureRecognizer *)recognizer {
        
        CGPoint translation = [recognizer translationInView:recognizer.view];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"right"
            message:[NSString stringWithFormat:@"%@", translation]
            delegate:nil
            cancelButtonTitle:@"K"
            otherButtonTitles:nil];
        [alert show];
        [alert release];

        unsigned int nextConvoIndex = 0;
        if (currentConvoIndex == 0) {
            nextConvoIndex = [convos count] - 1 ;
        } else {
            nextConvoIndex = currentConvoIndex - 1;
        }

        [ckMessagesController showConversation:[convos objectAtIndex:nextConvoIndex] animate:YES];


    }




- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}
@end

static MSSwipeDelegate *swipeDelegate;

#include <logos/logos.h>
#include <substrate.h>
@class CKConversationList; @class CKConversation; @class CKMessagesController; @class CKTranscriptController; @class SMSApplication; 
static void (*_logos_orig$_ungrouped$CKTranscriptController$viewDidAppear$)(CKTranscriptController*, SEL, BOOL); static void _logos_method$_ungrouped$CKTranscriptController$viewDidAppear$(CKTranscriptController*, SEL, BOOL); static BOOL (*_logos_orig$_ungrouped$SMSApplication$application$didFinishLaunchingWithOptions$)(SMSApplication*, SEL, id, id); static BOOL _logos_method$_ungrouped$SMSApplication$application$didFinishLaunchingWithOptions$(SMSApplication*, SEL, id, id); static id (*_logos_orig$_ungrouped$CKConversation$init)(CKConversation*, SEL); static id _logos_method$_ungrouped$CKConversation$init(CKConversation*, SEL); static void (*_logos_orig$_ungrouped$CKMessagesController$_conversationLeft$)(CKMessagesController*, SEL, id); static void _logos_method$_ungrouped$CKMessagesController$_conversationLeft$(CKMessagesController*, SEL, id); static void (*_logos_orig$_ungrouped$CKMessagesController$showConversation$animate$)(CKMessagesController*, SEL, id, BOOL); static void _logos_method$_ungrouped$CKMessagesController$showConversation$animate$(CKMessagesController*, SEL, id, BOOL); static void (*_logos_orig$_ungrouped$CKMessagesController$showConversation$animate$forceToTranscript$)(CKMessagesController*, SEL, id, BOOL, BOOL); static void _logos_method$_ungrouped$CKMessagesController$showConversation$animate$forceToTranscript$(CKMessagesController*, SEL, id, BOOL, BOOL); static BOOL (*_logos_orig$_ungrouped$CKMessagesController$resumeToConversation$)(CKMessagesController*, SEL, id); static BOOL _logos_method$_ungrouped$CKMessagesController$resumeToConversation$(CKMessagesController*, SEL, id); static id (*_logos_orig$_ungrouped$CKMessagesController$init)(CKMessagesController*, SEL); static id _logos_method$_ungrouped$CKMessagesController$init(CKMessagesController*, SEL); 
static __inline__ __attribute__((always_inline)) Class _logos_static_class_lookup$CKConversationList(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("CKConversationList"); } return _klass; }
#line 120 "Tweak.xm"



static void _logos_method$_ungrouped$CKTranscriptController$viewDidAppear$(CKTranscriptController* self, SEL _cmd, BOOL arg1) {
    if (isFirstLaunch) {
        backPlacard = self.view;
        if (backPlacard) {
            isFirstLaunch = NO;
            swipeDelegate = [[MSSwipeDelegate alloc] init];
            backPlacard.userInteractionEnabled = YES;
            
            
            

            
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
        }
    }

    _logos_orig$_ungrouped$CKTranscriptController$viewDidAppear$(self, _cmd, arg1);

}






static BOOL _logos_method$_ungrouped$SMSApplication$application$didFinishLaunchingWithOptions$(SMSApplication* self, SEL _cmd, id application, id options) {
    convos = [[_logos_static_class_lookup$CKConversationList() sharedConversationList] activeConversations];
    return _logos_orig$_ungrouped$SMSApplication$application$didFinishLaunchingWithOptions$(self, _cmd, application, options);
}

















static id _logos_method$_ungrouped$CKConversation$init(CKConversation* self, SEL _cmd) {
    
    

    return _logos_orig$_ungrouped$CKConversation$init(self, _cmd);
}







static void _logos_method$_ungrouped$CKMessagesController$_conversationLeft$(CKMessagesController* self, SEL _cmd, id left) {
    convos = [[_logos_static_class_lookup$CKConversationList() sharedConversationList] activeConversations];
    _logos_orig$_ungrouped$CKMessagesController$_conversationLeft$(self, _cmd, left);
}



static void _logos_method$_ungrouped$CKMessagesController$showConversation$animate$(CKMessagesController* self, SEL _cmd, id conversation, BOOL animate) {
    
    currentConvoIndex = [convos indexOfObject:conversation];
    
    
    
    
    
    
    


    _logos_orig$_ungrouped$CKMessagesController$showConversation$animate$(self, _cmd, conversation, animate);
}

static void _logos_method$_ungrouped$CKMessagesController$showConversation$animate$forceToTranscript$(CKMessagesController* self, SEL _cmd, id conversation, BOOL animate, BOOL transcript) {
    
    currentConvoIndex = [convos indexOfObject:conversation];
    _logos_orig$_ungrouped$CKMessagesController$showConversation$animate$forceToTranscript$(self, _cmd, conversation, animate, transcript);
}


static BOOL _logos_method$_ungrouped$CKMessagesController$resumeToConversation$(CKMessagesController* self, SEL _cmd, id conversation) {
    currentConvoIndex = [convos indexOfObject:conversation];
    return _logos_orig$_ungrouped$CKMessagesController$resumeToConversation$(self, _cmd, conversation);
}


static id _logos_method$_ungrouped$CKMessagesController$init(CKMessagesController* self, SEL _cmd) {
    ckMessagesController = self;
    return _logos_orig$_ungrouped$CKMessagesController$init(self, _cmd);
}


static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$CKTranscriptController = objc_getClass("CKTranscriptController"); MSHookMessageEx(_logos_class$_ungrouped$CKTranscriptController, @selector(viewDidAppear:), (IMP)&_logos_method$_ungrouped$CKTranscriptController$viewDidAppear$, (IMP*)&_logos_orig$_ungrouped$CKTranscriptController$viewDidAppear$);Class _logos_class$_ungrouped$SMSApplication = objc_getClass("SMSApplication"); MSHookMessageEx(_logos_class$_ungrouped$SMSApplication, @selector(application:didFinishLaunchingWithOptions:), (IMP)&_logos_method$_ungrouped$SMSApplication$application$didFinishLaunchingWithOptions$, (IMP*)&_logos_orig$_ungrouped$SMSApplication$application$didFinishLaunchingWithOptions$);Class _logos_class$_ungrouped$CKConversation = objc_getClass("CKConversation"); MSHookMessageEx(_logos_class$_ungrouped$CKConversation, @selector(init), (IMP)&_logos_method$_ungrouped$CKConversation$init, (IMP*)&_logos_orig$_ungrouped$CKConversation$init);Class _logos_class$_ungrouped$CKMessagesController = objc_getClass("CKMessagesController"); MSHookMessageEx(_logos_class$_ungrouped$CKMessagesController, @selector(_conversationLeft:), (IMP)&_logos_method$_ungrouped$CKMessagesController$_conversationLeft$, (IMP*)&_logos_orig$_ungrouped$CKMessagesController$_conversationLeft$);MSHookMessageEx(_logos_class$_ungrouped$CKMessagesController, @selector(showConversation:animate:), (IMP)&_logos_method$_ungrouped$CKMessagesController$showConversation$animate$, (IMP*)&_logos_orig$_ungrouped$CKMessagesController$showConversation$animate$);MSHookMessageEx(_logos_class$_ungrouped$CKMessagesController, @selector(showConversation:animate:forceToTranscript:), (IMP)&_logos_method$_ungrouped$CKMessagesController$showConversation$animate$forceToTranscript$, (IMP*)&_logos_orig$_ungrouped$CKMessagesController$showConversation$animate$forceToTranscript$);MSHookMessageEx(_logos_class$_ungrouped$CKMessagesController, @selector(resumeToConversation:), (IMP)&_logos_method$_ungrouped$CKMessagesController$resumeToConversation$, (IMP*)&_logos_orig$_ungrouped$CKMessagesController$resumeToConversation$);MSHookMessageEx(_logos_class$_ungrouped$CKMessagesController, @selector(init), (IMP)&_logos_method$_ungrouped$CKMessagesController$init, (IMP*)&_logos_orig$_ungrouped$CKMessagesController$init);} }
#line 233 "Tweak.xm"

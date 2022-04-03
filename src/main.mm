#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/CAMetalLayer.h>

#include <assert.h>

struct OSXApp
{
    id helper;
    id delegate;
    __CGEventSource* eventSource;
};

struct OSXWindow
{
    id object; // id is obj-c void* pointer type, but always points to obj-c obj
    id delegate;
    id view;
    id layer;

    bool maximized;
    bool occluded;
    bool retina;

    bool should_terminate;

    // Cached window properties to filter out duplicate events
    int width, height;
    int fbWidth, fbHeight;
    float xscale, yscale;

    // The total sum of the distances the cursor has been warped
    // since the last cursor motion event was processed
    // This is kept to counteract Cocoa doing the same internally
    double cursorWarpDeltaX, cursorWarpDeltaY;
};

@interface WindowDelegate : NSObject 
{
    OSXWindow* window;
}

- (instancetype)init:(OSXWindow*)window;

- (OSXWindow*)editorWindow;

@end // interface WindowDelegate

@implementation WindowDelegate

- (OSXWindow*)editorWindow
{
    return window;
}

- (instancetype)init:(OSXWindow*)window
{
    self = [super init];
    if (self != nil)
    {
        self->window = window;
    }

    return self;
}

- (BOOL)windowShouldClose:(NSWindow*)sender
{
    // _glfwInputWindowCloseRequest(window);
    self->window->should_terminate = true;
    return YES;
}

@end // implementation WindowDelegate

@interface ContentView : NSView <NSTextInputClient>
{
    OSXWindow* window;
    NSTrackingArea* trackingArea;
    NSMutableAttributedString* markedText;
}

- (instancetype)init:(OSXWindow*)window;

@end // interface ContentView

@implementation ContentView

- (instancetype)init:(OSXWindow *)window
{
    self = [super init];
    if (self != nil)
    {
        self->window = window;
        self->trackingArea = nil;
        self->markedText = [[NSMutableAttributedString alloc] init];

        [self updateTrackingAreas];
        [self registerForDraggedTypes:@[NSPasteboardTypeURL]];
    }

    return self;
}

// - (void)dealloc
// {
//     [trackingArea release];
//     [markedText release];
//     [super dealloc];
// }

- (BOOL)hasMarkedText
{
    return NO;
}

- (NSRange)markedRange
{
    return { NSNotFound, 0 };
}

- (NSRange)selectedRange
{
    return { NSNotFound, 0 };
}

- (void)setMarkedText:(id)string
        selectedRange:(NSRange)selectedRange
     replacementRange:(NSRange)replacementRange
{
}

- (void)unmarkText
{
}

- (NSArray*)validAttributesForMarkedText
{
    return [NSArray array];
}

@end // implementation ContentView

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end // interface AppDelegate

@implementation AppDelegate

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // for (_GLFWwindow* window = _glfw.windowListHead;  window;  window = window->next)
        // _glfwInputWindowCloseRequest(window);

    // NSWindow* window = [[sender] mainWindow];
    NSWindow* window = [[NSApplication sharedApplication] mainWindow];
    if (window != nil)
    {
        WindowDelegate* window_delegate = (__bridge WindowDelegate*)window.delegate;
        OSXWindow* osx_window = [window_delegate editorWindow];
        osx_window->should_terminate = true;
    }
    
    return NSTerminateCancel;
}

- (void)applicationDidChangeScreenParameters:(NSNotification *) notification
{
    // for (_GLFWwindow* window = _glfw.windowListHead;  window;  window = window->next)
    // {
    //     if (window->context.client != GLFW_NO_API)
    //         [window->context.nsgl.object update];
    // }

    // _glfwPollMonitorsCocoa();
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    // if (_glfw.hints.init.ns.menubar)
    // {
    //     // Menu bar setup must go between sharedApplication and finishLaunching
    //     // in order to properly emulate the behavior of NSApplicationMain

    //     if ([[NSBundle mainBundle] pathForResource:@"MainMenu" ofType:@"nib"])
    //     {
    //         [[NSBundle mainBundle] loadNibNamed:@"MainMenu"
    //                                       owner:NSApp
    //                             topLevelObjects:&_glfw.ns.nibObjects];
    //     }
    //     else
    //         createMenuBar();
    // }
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // _glfwPostEmptyEventCocoa();
    [NSApp stop:nil];
}

- (void)applicationDidHide:(NSNotification *)notification
{
    // for (int i = 0;  i < _glfw.monitorCount;  i++)
        // _glfwRestoreVideoModeCocoa(_glfw.monitors[i]);
}

@end // implementation AppDelegate

@interface AppHelper : NSObject
@end // interface AppHelper

@implementation AppHelper

- (void)selectedKeyboardInputSourceChanged:(NSObject* )object
{
    // updateUnicodeData();
}

- (void)doNothing:(id)object
{
}

@end // AppHelper

int main(int argc, const char * argv[]) 
{
    OSXApp app = {};
    OSXWindow window = {};

    @autoreleasepool 
    {
        app.helper = [[AppHelper alloc] init];
        assert(app.helper != nil);

        [NSThread detachNewThreadSelector:@selector(doNothing:)
                        toTarget:app.helper
                        withObject:nil];

        [NSApplication sharedApplication]; // Creates the application instance if it doesnt yet exist.

        app.delegate = [[AppDelegate alloc] init];
        assert(app.delegate != nil);

        [NSApp setDelegate:app.delegate];

        // NSEvent* (^block)(NSEvent*) = ^ NSEvent* (NSEvent* event)
        // {
        //     if ([event modifierFlags] & NSEventModifierFlagCommand)
        //         [[NSApp keyWindow] sendEvent:event];

        //     return event;
        // };

        // _glfw.ns.keyUpMonitor =
        //     [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyUp
        //                                         handler:block];

        // Press and Hold prevents some keys from emitting repeated characters
        // NSDictionary* defaults = @{@"ApplePressAndHoldEnabled":@NO};
        // [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

        [[NSNotificationCenter defaultCenter] addObserver:app.helper
                                              selector:@selector(selectedKeyboardInputSourceChanged:)
                                              name:NSTextInputContextKeyboardSelectionDidChangeNotification
                                              object:nil];

        // createKeyTables();

        app.eventSource = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
        CGEventSourceSetLocalEventsSuppressionInterval(app.eventSource, 0.0);

        // _glfwPollMonitorsCocoa();

        if (![[NSRunningApplication currentApplication] isFinishedLaunching])
        {
            [NSApp run];
        }

        window.delegate = [[WindowDelegate alloc] init:&window];
        assert(window.delegate != nil);

        NSRect windowRect = NSMakeRect(0, 0, 500, 500);

        NSUInteger windowStyle = NSWindowStyleMaskMiniaturizable |
                               NSWindowStyleMaskTitled |
                               NSWindowStyleMaskClosable |
                               NSWindowStyleMaskResizable;
    
        window.object = [[NSWindow alloc]
            initWithContentRect:windowRect
            styleMask:windowStyle
            backing:NSBackingStoreBuffered
            defer:NO
        ];
        assert(window.object != nil);

        const NSWindowCollectionBehavior behavior = NSWindowCollectionBehaviorFullScreenPrimary |
                                                    NSWindowCollectionBehaviorManaged;
        [window.object setCollectionBehavior:behavior];

        [window.object setFrameAutosaveName:@"EditorWindow"];

        window.view = [[ContentView alloc] init:&window];

        NSView* ns_view = (__bridge NSView*)window.view;
        if (![ns_view.layer isKindOfClass:[CAMetalLayer class]])
        {
            [ns_view setLayer:[CAMetalLayer layer]];
            [ns_view setWantsLayer:YES];
        }

        window.retina = true;

        [window.object setContentView:window.view];
        [window.object makeFirstResponder:window.view];
        [window.object setTitle:@"Editor"];
        [window.object setDelegate:window.delegate];
        [window.object setAcceptsMouseMovedEvents:YES];
        [window.object setRestorable:NO];

        // _glfwGetWindowSizeCocoa(window, &window->ns.width, &window->ns.height);
        // _glfwGetFramebufferSizeCocoa(window, &window->ns.fbWidth, &window->ns.fbHeight);

        // Show window
        [window.object orderFront:nil];

        // Focus window
        [NSApp activateIgnoringOtherApps:YES];
        [window.object makeKeyAndOrderFront:nil];
    }
    
    @autoreleasepool {
        for (;;)
        {
            if (window.should_terminate)
            {
                break;
            }

            NSEvent* event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                    untilDate:[NSDate distantPast]
                                    inMode:NSDefaultRunLoopMode
                                    dequeue:YES];
            // if (event == nil)
                // break;

            if (event != nil)
            {
                [NSApp sendEvent:event];
            }
        }
    } // autoreleasepool

    return 0;
}

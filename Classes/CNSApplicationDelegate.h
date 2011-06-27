@class CNSDragStatusView;
@class CNSPreferencesViewController;

@interface CNSApplicationDelegate : NSObject <NSMenuDelegate> {
@private
	IBOutlet CNSPreferencesViewController *preferencesViewController;

  CNSDragStatusView *dragStatusView;
  NSStatusItem *statusItem;
}

- (IBAction)showPreferencesView:(id)sender;

@end

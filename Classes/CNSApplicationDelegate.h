@class CNSPreferencesViewController;

@interface CNSApplicationDelegate : NSObject {
@private
	IBOutlet CNSPreferencesViewController *preferencesViewController;
}

- (IBAction)showPreferencesView:(id)sender;

@end

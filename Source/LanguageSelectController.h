#import "LangAssociationsController.h"
#import "Tweak.h"

@interface LanguageSelectController : UITableViewController
-(instancetype)initWithStyle:(UITableViewStyle)style delegate:(id)sender;
-(instancetype)initWithStyle:(UITableViewStyle)style forExtension:(NSString *)ext delegate:(id)sender;
@end
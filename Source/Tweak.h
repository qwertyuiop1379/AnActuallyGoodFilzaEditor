#define kRegexHighlightViewTypeText @"text"
#define kRegexHighlightViewTypeBackground @"background"
#define kRegexHighlightViewTypeComment @"comment"
#define kRegexHighlightViewTypeDocumentationComment @"documentation_comment"
#define kRegexHighlightViewTypeDocumentationCommentKeyword @"documentation_comment_keyword"
#define kRegexHighlightViewTypeString @"string"
#define kRegexHighlightViewTypeCharacter @"character"
#define kRegexHighlightViewTypeNumber @"number"
#define kRegexHighlightViewTypeKeyword @"keyword"
#define kRegexHighlightViewTypePreprocessor @"preprocessor"
#define kRegexHighlightViewTypeURL @"url"
#define kRegexHighlightViewTypeAttribute @"attribute"
#define kRegexHighlightViewTypeProject @"project"
#define kRegexHighlightViewTypeOther @"other"

@interface TGPreferencesTableViewController : UIViewController
@property (nonatomic, retain, readwrite) NSArray *items;
@end

@interface ICTextView : UITextView
@property (nonatomic, retain) NSDictionary *highlightColor;
@property (nonatomic, retain) NSDictionary *highlightDefinition;
@property (nonatomic, retain) NSTimer *highlightTimer;
+(NSDictionary *)highlightTheme:(NSString *)theme;
+(NSDictionary *)defaultDefinition;
-(NSAttributedString *)highlightText:(NSAttributedString *)stringIn;
-(void)recieveAnalSexFromController:(NSString *)ret;
-(void)setHighlightDefinitionWithContentsOfFile:(NSString *)newPath;
-(void)setHighlightTheme:(NSString *)theme;
-(void)formatText;
-(void)formatTextNow;
@end

@interface TGFastTextEditViewController : UIViewController <UITextViewDelegate>
@property (nonatomic, retain) ICTextView *textEditor;
@property (nonatomic, retain) UILabel *fontSizeLabel;
@property (nonatomic, retain) UIView *sideBar;
@property (nonatomic, retain) UIButton *chooseLanguageButton;
@property (nonatomic, retain) UIButton *hideSideBarButton;
@property (nonatomic, retain) UIButton *showSideBarButton;
-(void)updateFontSizeLabel;
-(void)formatText;
@end
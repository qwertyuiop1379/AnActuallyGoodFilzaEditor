#import "EditorThemeController.h"
#import "LangAssociationsController.h"
#import "LanguageSelectController.h"
#import "ThemeManager.h"
#import "Tweak.h"

TGFastTextEditViewController *ViewController;
NSMutableDictionary *highlightThemes, *preferences, *fileExtensions;
UIFont *standardFont, *customFont;
CGSize screen;

#pragma mark Functions

UIImage *getImage(NSString *name, float size = 0)
{
    UIImage *loadedImage = [UIImage imageWithContentsOfFile:[@"/var/mobile/Library/Application Support/AnActuallyGoodFilzaEditor/" stringByAppendingString:name]];

    if (size == 0)
    {
        return loadedImage;
    }

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, UIScreen.mainScreen.scale);
    [loadedImage drawInRect:CGRectMake(0, 0, size, size)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return scaledImage;
}

#pragma mark Constructors

%ctor
{
    standardFont = [UIFont fontWithName:@"CourierNewPSMT" size:14];
}

%dtor
{
    if (preferences)
    {
        @try
        {
            preferences[@"customFont"] = @{ @"n" : customFont.fontName, @"s" : @(customFont.pointSize) };
            [preferences writeToURL:[NSURL fileURLWithPath:@"/var/mobile/Library/Preferences/com.qiop1379.anactuallygoodfilzaeditor.plist"] error:nil];
        }
        @catch(NSException *e)
        {
            NSLog(@"AnActuallyGoodFilzaEditor: failed to write preferences. %@", e);
        }
    }
}

%dtor
{
    if (fileExtensions)
    {
        @try
        {
            [fileExtensions writeToURL:[NSURL fileURLWithPath:@"/var/mobile/Library/Application Support/AnActuallyGoodFilzaEditor/fileExtensions.plist"] error:nil];
        }
        @catch(NSException *e)
        {
            NSLog(@"AnActuallyGoodFilzaEditor: failed to write file extensions. %@", e);
        }
    }
}

#pragma mark Hooks

%hook TGPreferencesTableViewController
-(void)viewDidLoad
{
    %orig;
    NSMutableArray *itemsProp = [self.items mutableCopy];
    NSDictionary *preferenceCellDiction = @
    {
        @"title" : @"AnActuallyGoodFilzaEditor",
        @"item"  : @[@"editor-theme", @"language-associations"]
    };
    [itemsProp insertObject:preferenceCellDiction atIndex:0];
    self.items = [itemsProp copy];
}

%new
-(void)showEditorThemeController
{
    [self.navigationController pushViewController:[[%c(EditorThemeController) alloc] initWithStyle:UITableViewStyleGrouped] animated:YES];
}

%new
-(void)showLangAssociationsController
{
    [self.navigationController pushViewController:[[%c(LangAssociationsController) alloc] initWithStyle:UITableViewStyleGrouped] animated:YES];
}
%end

%hook TGPreferences
-(NSDictionary *)preferencesModel
{
    NSDictionary *orig = %orig;
    if (orig[@"editor-theme"] && orig[@"language-associations"]) return orig;
    NSMutableDictionary *model = orig.mutableCopy;

    NSDictionary *editorThemePreferenceKey =
    @{
        @"display-value"  : @(YES),
        @"name"           : @"Editor theme",
        @"selected-value" : @"Default",
        @"selector"       : @"showEditorThemeController"
    };

    NSDictionary *fileAssociationsPreferenceKey =
    @{
        @"display-value"  : @(YES),
        @"name"           : @"Language associations",
        @"selected-value" : @"Default",
        @"selector"       : @"showLangAssociationsController"
    };

    model[@"editor-theme"] = editorThemePreferenceKey;
    model[@"language-associations"] = fileAssociationsPreferenceKey;

    return model.copy;
}
%end

%hook TGFastTextEditViewController
%property (nonatomic, retain) UILabel *fontSizeLabel;
%property (nonatomic, retain) UIView *sideBar;
%property (nonatomic, retain) UIButton *chooseLanguageButton;
%property (nonatomic, retain) UIButton *hideSideBarButton;
%property (nonatomic, retain) UIButton *showSideBarButton;
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSDictionary *brackets = @{ @"{" : @"}", @"[" : @"]", @"(" : @")"};
    NSRange selectedRange = self.textEditor.selectedRange;
    self.textEditor.scrollEnabled = NO;

    for (NSString *key in brackets)
    {
        if ([text isEqual:key])
        {
            NSDictionary *attributes = @{ NSFontAttributeName : standardFont, NSForegroundColorAttributeName : self.textEditor.highlightColor[kRegexHighlightViewTypeText] };
            NSMutableAttributedString *m = [self.textEditor.attributedText mutableCopy];
            [m insertAttributedString:[[NSAttributedString alloc] initWithString:brackets[key] attributes:attributes] atIndex:range.location];
            self.textEditor.attributedText = m;
            [self formatText];
        }
    }

    self.textEditor.selectedRange = selectedRange;
    self.textEditor.scrollEnabled = YES;
    return %orig;
}

-(void)viewWillTransitionToSize:(CGSize)arg1 withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)arg2
{
    screen = arg1;

    [arg2 animateAlongsideTransitionInView:self.view animation:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context)
    {
        self.sideBar.frame = CGRectMake(screen.width - 49, screen.height / 8, 50, screen.height * 3 / 4);
        self.chooseLanguageButton.frame = CGRectMake(5, 130, 40, (screen.height * 3 / 4) - 180);
        self.hideSideBarButton.frame = CGRectMake(5, (screen.height * 3 / 4) - 45, 40, 40);
        self.showSideBarButton.frame = CGRectMake(screen.width, screen.height / 2 - 20, 30, 40);
    } completion:nil];
}

-(void)viewDidLoad
{
    %orig;

    ViewController = self;

    screen = self.view.frame.size;

    ThemeManager *manager = [%c(ThemeManager) sharedInstance];
    UIColor *inverse = [manager inverseColor:manager.secondaryColor];

    fileExtensions = fileExtensions ?: [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Application Support/AnActuallyGoodFilzaEditor/fileExtensions.plist"].mutableCopy;
    NSString *lang = fileExtensions[self.navigationItem.title.pathExtension];

    preferences = preferences ?: [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.qiop1379.anactuallygoodfilzaeditor.plist"];
    [self.textEditor setHighlightDefinitionWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Application Support/AnActuallyGoodFilzaEditor/Languages/%@.plist", lang]];

    NSString *selected = preferences[@"selectedTheme"] ?: @"Default";
    customFont = preferences[@"customFont"] ? [UIFont fontWithName:[preferences[@"customFont"] objectForKey:@"n"] size:[[preferences[@"customFont"] objectForKey:@"s"] intValue]] : standardFont;

    self.textEditor.delegate = self;
    self.textEditor.font = customFont;
    self.textEditor.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textEditor.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.textEditor setHighlightTheme:selected];
    [self.textEditor formatTextNow];

    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, screen.width, 50)];
    toolbar.barStyle = UIBarStyleBlackTranslucent;

    toolbar.items = @
    [
        [[UIBarButtonItem alloc] initWithImage:getImage(@"tab.png", 24) style:UIBarButtonItemStylePlain target:self.textEditor action:@selector(indentButtonPressed)],
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
        [[UIBarButtonItem alloc] initWithImage:getImage(@"hidekeyboard.png", 24) style:UIBarButtonItemStylePlain target:self.textEditor action:@selector(hideKeyboardButtonPressed)]
    ];

    [toolbar sizeToFit];
    self.textEditor.inputAccessoryView = toolbar;

    self.sideBar = [[UIView alloc] initWithFrame:CGRectMake(screen.width - 49, screen.height / 8, 50, screen.height * 3 / 4)];
    self.sideBar.backgroundColor = manager.secondaryColor;
    self.sideBar.clipsToBounds = YES;
    self.sideBar.layer.borderColor = inverse.CGColor;
    self.sideBar.layer.borderWidth = 0.5f;
    self.sideBar.layer.cornerRadius = 8;
    self.sideBar.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner;
    [self.view addSubview:self.sideBar];

    UIButton *increaseFont = [UIButton buttonWithType:UIButtonTypeCustom];
    [increaseFont addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [increaseFont setTitle:@"+" forState:UIControlStateNormal];
    [increaseFont setTitleColor:inverse forState:UIControlStateNormal];
    increaseFont.titleLabel.font = standardFont;
    increaseFont.tag = 2;
    increaseFont.frame = CGRectMake(5, 5, 40, 40);
    increaseFont.clipsToBounds = YES;
    increaseFont.layer.borderWidth = 1;
    increaseFont.layer.borderColor = manager.gray.CGColor;
    increaseFont.layer.cornerRadius = 5;
    increaseFont.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.sideBar addSubview:increaseFont];

    self.fontSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 45, 40, 40)];
    self.fontSizeLabel.font = standardFont;
    self.fontSizeLabel.textAlignment = NSTextAlignmentCenter;
    self.fontSizeLabel.textColor = inverse;
    self.fontSizeLabel.layer.borderWidth = 1;
    self.fontSizeLabel.layer.borderColor = manager.gray.CGColor;
    [self.sideBar addSubview:self.fontSizeLabel];
    [self updateFontSizeLabel];

    UIButton *decreaseFont = [UIButton buttonWithType:UIButtonTypeCustom];
    [decreaseFont addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [decreaseFont setTitle:@"-" forState:UIControlStateNormal];
    [decreaseFont setTitleColor:inverse forState:UIControlStateNormal];
    decreaseFont.titleLabel.font = standardFont;
    decreaseFont.tag = 1;
    decreaseFont.frame = CGRectMake(5, 85, 40, 40);
    decreaseFont.clipsToBounds = YES;
    decreaseFont.layer.borderWidth = 1;
    decreaseFont.layer.borderColor = manager.gray.CGColor;
    decreaseFont.layer.cornerRadius = 5;
    decreaseFont.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    [self.sideBar addSubview:decreaseFont];

    self.chooseLanguageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.chooseLanguageButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.chooseLanguageButton setTitle:lang ?: @"Language" forState:UIControlStateNormal];
    [self.chooseLanguageButton setTitleColor:inverse forState:UIControlStateNormal];
    self.chooseLanguageButton.titleLabel.font = standardFont;
    self.chooseLanguageButton.tag = 3;
    self.chooseLanguageButton.transform = CGAffineTransformMakeRotation(M_PI_2);
    self.chooseLanguageButton.frame = CGRectMake(5, 130, 40, (screen.height * 3 / 4) - 180);
    self.chooseLanguageButton.layer.borderWidth = 1;
    self.chooseLanguageButton.layer.borderColor = manager.gray.CGColor;
    self.chooseLanguageButton.layer.cornerRadius = 5;
    [self.sideBar addSubview:self.chooseLanguageButton];

    self.hideSideBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.hideSideBarButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.hideSideBarButton setTitle:@">" forState:UIControlStateNormal];
    [self.hideSideBarButton setTitleColor:inverse forState:UIControlStateNormal];
    self.hideSideBarButton.titleLabel.font = standardFont;
    self.hideSideBarButton.tag = 4;
    self.hideSideBarButton.frame = CGRectMake(5, (screen.height * 3 / 4) - 45, 40, 40);
    self.hideSideBarButton.layer.borderWidth = 1;
    self.hideSideBarButton.layer.borderColor = manager.gray.CGColor;
    self.hideSideBarButton.layer.cornerRadius = 5;
    [self.sideBar addSubview:self.hideSideBarButton];

    self.showSideBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.showSideBarButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.showSideBarButton setTitle:@"<" forState:UIControlStateNormal];
    [self.showSideBarButton setTitleColor:inverse forState:UIControlStateNormal];
    self.showSideBarButton.titleLabel.font = standardFont;
    self.showSideBarButton.tag = 5;
    self.showSideBarButton.backgroundColor = manager.secondaryColor;
    self.showSideBarButton.frame = CGRectMake(screen.width, screen.height / 2 - 20, 30, 40);
    self.showSideBarButton.layer.borderWidth = 1;
    self.showSideBarButton.layer.borderColor = manager.gray.CGColor;
    self.showSideBarButton.layer.cornerRadius = 5;
    self.showSideBarButton.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner;
    [self.view addSubview:self.showSideBarButton];
}

%new
-(void)buttonPressed:(UIButton *)sender
{
    switch (sender.tag)
    {
        case 1:
            customFont = [UIFont fontWithName:customFont.fontName size:customFont.pointSize - 1];
            self.textEditor.font = customFont;
            break;

        case 2:
            customFont = [UIFont fontWithName:customFont.fontName size:customFont.pointSize + 1];
            self.textEditor.font = customFont;
            break;

        case 3:
            [self.navigationController pushViewController:[[%c(LanguageSelectController) alloc] initWithStyle:UITableViewStyleGrouped delegate:self.textEditor] animated:YES];
            break;

        case 4:
            [UIView animateWithDuration:0.25f animations:^
            {
                CGRect f = self.sideBar.frame;
                self.sideBar.frame = CGRectMake(screen.width, f.origin.y, f.size.width, f.size.height);
            }
            completion:^(BOOL arg1)
            {
                [UIView animateWithDuration:0.25f animations:^
                {
                    CGRect ff = self.showSideBarButton.frame;
                    self.showSideBarButton.frame = CGRectMake(screen.width - 29, ff.origin.y, ff.size.width, ff.size.height);
                }];
            }];
            break;

        case 5:
            [UIView animateWithDuration:0.25f animations:^
            {
                CGRect ff = self.showSideBarButton.frame;
                self.showSideBarButton.frame = CGRectMake(screen.width, ff.origin.y, ff.size.width, ff.size.height);
            }
            completion:^(BOOL arg1)
            {
                [UIView animateWithDuration:0.25f animations:^
                {
                    CGRect f = self.sideBar.frame;
                    self.sideBar.frame = CGRectMake(screen.width - 49, f.origin.y, f.size.width, f.size.height);
                }];
            }];
            break;
    }

    [self updateFontSizeLabel];
}

%new
-(void)updateFontSizeLabel
{
    self.fontSizeLabel.text = [NSNumber numberWithDouble:self.textEditor.font.pointSize].stringValue;
}

%new
-(void)formatText
{
    [self.textEditor formatText];
}

%new
-(void)textViewDidChange:(UITextView *)textView
{
    [self formatText];
}
%end

%hook ICTextView
%property (nonatomic, retain) NSDictionary *highlightColor;
%property (nonatomic, retain) NSDictionary *highlightDefinition;
%property (nonatomic, retain) NSTimer *highlightTimer;
%new
-(void)indentButtonPressed
{
    [self replaceRange:self.selectedTextRange withText:@"	"];
}

%new
-(void)hideKeyboardButtonPressed
{
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

%new
-(void)setHighlightDefinitionWithContentsOfFile:(NSString *)newPath
{
    self.highlightDefinition = [NSDictionary dictionaryWithContentsOfFile:newPath] ?: [%c(ICTextView) defaultDefinition];
}

-(void)setFont:(UIFont *)font
{
    float size = font.pointSize;

    if (size < 5)
    {
        size = 5;
    }
    else if (size > 20)
    {
        size = 20;
    }

    %orig([UIFont fontWithName:@"CourierNewPSMT" size:size]);
}

%new
-(void)setHighlightTheme:(NSString *)theme
{
    self.highlightColor = [%c(ICTextView) highlightTheme:theme];
    [self setNeedsLayout];

    self.backgroundColor = self.highlightColor[kRegexHighlightViewTypeBackground] ?: UIColor.whiteColor;
}

%new
-(void)formatTextNow
{
    NSRange selectedRange = self.selectedRange;
    self.scrollEnabled = NO;

    NSDictionary *attributes = @{ NSFontAttributeName : customFont };
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.text attributes:attributes];
    self.attributedText = [self highlightText:attributedString];
    self.selectedRange = selectedRange;
    self.scrollEnabled = YES;
}

%new
-(void)formatText
{
    [self.highlightTimer invalidate];
    self.highlightTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(formatTextNow) userInfo:nil repeats:NO];
}

%new
-(NSAttributedString *)highlightText:(NSAttributedString *)attributedString
{
    if (!self.highlightDefinition) return attributedString;

    NSString *string = attributedString.string;
    NSRange range = NSMakeRange(0, string.length);
    NSMutableAttributedString *coloredString = attributedString.mutableCopy;
    [coloredString addAttribute:NSForegroundColorAttributeName value:self.highlightColor[kRegexHighlightViewTypeText] range:range];

    NSMutableArray *keys = self.highlightDefinition.allKeys.mutableCopy;
    if ([keys containsObject:kRegexHighlightViewTypeString])
    {
        [keys removeObject:kRegexHighlightViewTypeString];
        [keys addObject:kRegexHighlightViewTypeString];
    }
    if ([keys containsObject:kRegexHighlightViewTypeComment])
    {
        [keys removeObject:kRegexHighlightViewTypeComment];
        [keys addObject:kRegexHighlightViewTypeComment];
    }

    for (NSString *key in keys)
    {
        NSString *expression = self.highlightDefinition[key];
        if (!expression || expression.length <= 0) continue;
        NSArray *matches = [[NSRegularExpression regularExpressionWithPattern:expression options:NSRegularExpressionDotMatchesLineSeparators error:nil] matchesInString:string options:0 range:range];
        for (NSTextCheckingResult *match in matches)
        {
            UIColor *textColor;
            if (!self.highlightColor || !(textColor = (self.highlightColor[key])))
            {
                textColor = [[%c(ThemeManager) sharedInstance] inverseColor:self.highlightColor[kRegexHighlightViewTypeBackground]];
            }

            [coloredString addAttribute:NSForegroundColorAttributeName value:textColor range:[match rangeAtIndex:0]];
        }
    }

    return coloredString.copy;
}

%new
+(NSDictionary *)highlightTheme:(NSString *)theme
{
    if (highlightThemes[theme])
    {
        return highlightThemes[theme];
    }

    NSMutableDictionary *themeColor = [NSMutableDictionary dictionary];
    highlightThemes = highlightThemes ?: [NSMutableDictionary dictionary];
    
    NSDictionary *_themeColor = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"/var/mobile/Library/Application Support/AnActuallyGoodFilzaEditor/Themes/%@.plist", theme]] error:nil];
    
    for (NSString *key in _themeColor)
    {
        NSString *_ = _themeColor[key];
        unsigned int red, green, blue;
        NSScanner *scanner;

        scanner = [NSScanner scannerWithString:[_ substringWithRange:NSMakeRange(1, 2)]];
        [scanner scanHexInt:&red];

        scanner = [NSScanner scannerWithString:[_ substringWithRange:NSMakeRange(3, 2)]];
        [scanner scanHexInt:&green];

        scanner = [NSScanner scannerWithString:[_ substringWithRange:NSMakeRange(5, 2)]];
        [scanner scanHexInt:&blue];

        themeColor[key] = [UIColor colorWithRed:red / 255.0f green:green / 255.0f blue:blue / 255.0f alpha:1];
    }

    if (themeColor.count != 0)
    {
        highlightThemes[theme] = themeColor.copy;
        return themeColor.copy;
    }
    
    return nil;
}

%new
-(void)delegate:(id)delegate pickedLanguage:(NSString *)language
{
    [[self.delegate performSelector:@selector(chooseLanguageButton)] setTitle:language forState:UIControlStateNormal];
    [self setHighlightDefinitionWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Application Support/AnActuallyGoodFilzaEditor/Languages/%@.plist", language]];
    [self formatText];
}

%new
+(NSDictionary *)defaultDefinition
{
    return [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Application Support/AnActuallyGoodFilzaEditor/Languages/none.plist"];
}
%end
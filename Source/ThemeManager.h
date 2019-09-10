@interface ThemeManager
+(id)sharedInstance;
-(BOOL)isBlackTheme;
-(UIColor *)inverseColor:(UIColor *)color;
-(UIColor *)background;
-(UIColor *)darkGray;
-(UIColor *)lightGray;
-(UIColor *)secondaryColor;
-(UIColor *)selected;
-(UIColor *)gray;
-(UIColor *)text;
@end
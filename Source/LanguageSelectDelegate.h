@protocol LanguageSelectDelegate
@optional
-(void)delegate:(id)delegate pickedLanguage:(NSString *)language forExtension:(NSString *)extension;
-(void)delegate:(id)delegate pickedLanguage:(NSString *)language;
@end
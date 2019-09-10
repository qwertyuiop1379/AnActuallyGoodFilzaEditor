#include "EditorThemeController.h"
#include "ThemeManager.h"

extern NSMutableDictionary *preferences;

@implementation EditorThemeController
{
	ThemeManager *manager;
	UIImage *checkMark;
	NSIndexPath *selected;
	NSMutableArray *themes;
}

-(void)viewDidLoad
{
	[super viewDidLoad];

	manager = [%c(ThemeManager) sharedInstance];
	self.tableView.backgroundColor = manager.secondaryColor;
	self.navigationItem.title = @"Editor theme";
	checkMark = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/AnActuallyGoodFilzaEditor/checkmark.png"];
	themes = [NSFileManager.defaultManager contentsOfDirectoryAtPath:@"/var/mobile/Library/Application Support/AnActuallyGoodFilzaEditor/Themes" error:nil].mutableCopy;
	preferences = preferences ?: [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.qiop1379.anactuallygoodfilzaeditor.plist"];

	NSString *_selected = preferences[@"selectedTheme"] ?: @"Default";
	for (int i = 0; i < themes.count; i++)
	{
		themes[i] = [themes[i] stringByDeletingPathExtension];

		if ([_selected isEqual:themes[i]])
		{
			selected = [NSIndexPath indexPathForRow:i inSection:0];
		}
	}

	[self.tableView reloadData];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return themes.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Editor theme";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];

	if (selected == indexPath)
	{
		cell.accessoryView = [[UIImageView alloc] initWithImage:[checkMark imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
		cell.accessoryView.bounds = CGRectMake(0, 0, 14, 11);
		[cell.accessoryView setTintColor:[UIColor colorWithRed:0 green:0.478f blue:1 alpha:1]];
		[cell.accessoryView setContentMode:UIViewContentModeScaleAspectFit];
	}
	else
	{
		cell.accessoryView = nil;
	}

	[cell.accessoryView setNeedsDisplay];

	cell.textLabel.text = themes[indexPath.row];
	cell.textLabel.textColor = manager.isBlackTheme ? UIColor.whiteColor : UIColor.blackColor;
	cell.selectedBackgroundView = [[UIView alloc] init];
	cell.selectedBackgroundView.backgroundColor = manager.selected;
	cell.backgroundColor = manager.background;
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)index
{
	selected = index;
	preferences[@"selectedTheme"] = themes[index.row];
	NSLog(@"thing: %@", preferences[@"selectedTheme"]);

	[self.tableView reloadData];
}
@end
#import "LanguageSelectController.h"
#import "LangAssociationsController.h"
#import "ThemeManager.h"

@implementation LanguageSelectController
{
	ThemeManager *manager;
	NSMutableArray *objects;
	NSIndexPath *selected;
	NSString *extension;
	UIImage *checkMark;
	id sender;
}

-(instancetype)initWithStyle:(UITableViewStyle)style delegate:(id)delegate
{
	self = [super initWithStyle:style];
	sender = delegate;
	return self;
}

-(instancetype)initWithStyle:(UITableViewStyle)style forExtension:(NSString *)ext delegate:(id)delegate
{
	self = [super initWithStyle:style];
	extension = ext;
	sender = delegate;
	return self;
}

-(void)viewDidLoad
{
	[super viewDidLoad];

	manager = [%c(ThemeManager) sharedInstance];
	self.tableView.backgroundColor = manager.secondaryColor;
	self.navigationItem.title = @"Languages";
	checkMark = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/AnActuallyGoodFilzaEditor/checkmark.png"];

	objects = [[NSMutableArray alloc] init];
	
	for (NSString *line in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Library/Application Support/AnActuallyGoodFilzaEditor/Languages" error:nil])
	{
		[objects addObject:[[line lastPathComponent] stringByDeletingPathExtension]];
		[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
	}

	objects = [objects sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)].mutableCopy;
	[self.tableView reloadData];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return objects.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Languages";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)index
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];

	if (selected == index)
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

	cell.textLabel.text = [objects objectAtIndex:index.row];

	cell.textLabel.textColor = manager.isBlackTheme ? UIColor.whiteColor : UIColor.blackColor;
	cell.selectedBackgroundView = [[UIView alloc] init];
	cell.selectedBackgroundView.backgroundColor = manager.selected;
	cell.backgroundColor = manager.background;
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)index
{
	selected = index;
	[self.tableView reloadData];

	if (extension)
	{
		[sender delegate:sender pickedLanguage:objects[index.row] forExtension:extension];
		return;
	}

	[sender delegate:sender pickedLanguage:objects[index.row]];
}
@end
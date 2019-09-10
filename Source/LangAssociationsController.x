#import "LangAssociationsController.h"
#import "LanguageSelectController.h"
#import "ThemeManager.h"

extern NSMutableDictionary *fileExtensions;

@implementation LangAssociationsController
{
	ThemeManager *manager;
	NSMutableArray *objects;
	id oldLeftButton;
}

-(void)viewDidLoad
{
	[super viewDidLoad];

	manager = [%c(ThemeManager) sharedInstance];
	self.tableView.backgroundColor = manager.secondaryColor;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed)];
	self.navigationItem.title = @"Associations";
	oldLeftButton = self.navigationItem.leftBarButtonItem;

	fileExtensions = fileExtensions ?: [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Application Support/AnActuallyGoodFilzaEditor/fileExtensions.plist"].mutableCopy;
	objects = [NSMutableArray array];
	
	for (NSString *key in fileExtensions)
	{
		NSDictionary *cell = @
		{
			@"extension" : key,
			@"language" : fileExtensions[key]
		};

		[objects addObject:cell];
	}

	objects = [objects sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"extension" ascending:YES]]].mutableCopy;
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
	return @"Language associations";
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)index
{
	[fileExtensions removeObjectForKey:objects[index.row][@"extension"]];
	[objects removeObjectAtIndex:index.row];
	[self.tableView reloadData];
}

-(void)addButtonPressed
{
	UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"New rule" message:@"Enter file extension:" preferredStyle:UIAlertControllerStyleAlert];
	[controller addTextFieldWithConfigurationHandler:^(UITextField *textField)
    {
        textField.placeholder = @"xm";
        textField.textColor = UIColor.blackColor;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.backgroundColor = UIColor.clearColor;
        textField.borderStyle = UITextBorderStyleNone;
    }];
	[controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
	[controller addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
	{
		NSString *text = [controller.textFields[0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ([text hasPrefix:@"."] && text.length > 1)
		{
		    text = [text substringFromIndex:1];
		}

		[self.navigationController pushViewController:[[%c(LanguageSelectController) alloc] initWithStyle:UITableViewStyleGrouped forExtension:text delegate:self] animated:YES];
		[self editButtonPressed];		
	}]];

	[self presentViewController:controller animated:YES completion:nil];
}

-(void)editButtonPressed
{
	[self.tableView setEditing:!self.tableView.editing animated:YES];

	if (self.tableView.editing)
	{
		[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)] animated:YES];
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editButtonPressed)] animated:YES];
	}
	else
	{
		[self.navigationItem setLeftBarButtonItem:oldLeftButton animated:YES];
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed)] animated:YES];;
	}
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)index
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];

	NSDictionary *cellInfo = objects[index.row];

	cell.textLabel.text = [@"." stringByAppendingString:cellInfo[@"extension"]];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.detailTextLabel.text = cellInfo[@"language"];
	cell.detailTextLabel.textColor = [UIColor colorWithRed:0 green:0.5f blue:1 alpha:1];

	cell.textLabel.textColor = manager.isBlackTheme ? UIColor.whiteColor : UIColor.blackColor;
	cell.selectedBackgroundView = [[UIView alloc] init];
	cell.selectedBackgroundView.backgroundColor = manager.selected;
	cell.backgroundColor = manager.background;
	return cell;
}

-(void)delegate:(id)delegate pickedLanguage:(NSString *)language forExtension:(NSString *)extension
{
	if ([delegate isEqual:self])
	{
		BOOL found = NO;
		for (int i = 0; i < objects.count; i++)
		{
			NSDictionary *object = objects[i];
			if ([object[@"extension"] isEqual:extension])
			{
				found = YES;

				objects[i] = @
				{
					@"extension" : extension,
					@"language"  : language
				};

				fileExtensions[@"extension"] = language;
			}
		}

		if (!found)
		{
			fileExtensions[extension] = language;
			[objects addObject:@{ @"extension" : extension, @"language" : language }];
			objects = [objects sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"extension" ascending:YES]]].mutableCopy;
		}
	}

	[self.tableView reloadData];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)index
{
	NSString *extension = objects[index.row][@"extension"];
	[self.navigationController pushViewController:[[%c(LanguageSelectController) alloc] initWithStyle:UITableViewStyleGrouped forExtension:extension delegate:self] animated:YES];
}
@end
/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
*/

@interface SBControlCenterContentView

@property(retain, nonatomic) id airplaySection;
@property(retain, nonatomic) id brightnessSection;
@property(retain, nonatomic) id mediaControlsSection;
@property(retain, nonatomic) id quickLaunchSection;
@property(retain, nonatomic) id settingsSection;
@end

@interface SBControlCenterSectionViewController
@property(assign, nonatomic) id delegate;	// G=0xe6559; S=0xe6569; 
@end

static NSArray *controlCenterClasses;

%hook SBControlCenterViewController

- (void)viewDidLoad{
	%orig;

	if ([controlCenterClasses count] < 5)
	{
		return;
	}
	NSMutableArray *__sectionList = [self valueForKey:@"_sectionList"];
	SBControlCenterContentView *__contentView = [self valueForKey:@"_contentView"];

	[__sectionList removeAllObjects];

	SBControlCenterSectionViewController *firstViewController = [[[[controlCenterClasses objectAtIndex:0] alloc] init] autorelease];
	[firstViewController setDelegate:self];
	[__sectionList addObject:firstViewController];
	[__contentView setSettingsSection:firstViewController];

	SBControlCenterSectionViewController *secondViewController = [[[[controlCenterClasses objectAtIndex:1] alloc] init] autorelease];
	[secondViewController setDelegate:self];
	[__sectionList addObject:secondViewController];
	[__contentView setBrightnessSection:secondViewController];

	SBControlCenterSectionViewController *thirdViewController = [[[[controlCenterClasses objectAtIndex:2] alloc] init] autorelease];
	[thirdViewController setDelegate:self];
	[__sectionList addObject:thirdViewController];
	[__contentView setMediaControlsSection:thirdViewController];

	SBControlCenterSectionViewController *forthViewController = [[[[controlCenterClasses objectAtIndex:3] alloc] init] autorelease];
	[forthViewController setDelegate:self];
	[__sectionList addObject:forthViewController];
	[__contentView setAirplaySection:forthViewController];

	SBControlCenterSectionViewController *fifthViewController = [[[[controlCenterClasses objectAtIndex:4] alloc] init] autorelease];
	[fifthViewController setDelegate:self];
	[__sectionList addObject:fifthViewController];
	[__contentView setQuickLaunchSection:fifthViewController];
}

%end

%ctor{
	%init();
	NSDictionary *settingPlist = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preference/com.plipala.controlcenterloader.plist"];
	NSMutableArray *mutableClasses = [NSMutableArray array];
	NSMutableArray *defaultSetting = [NSMutableArray arrayWithObjects:objc_getClass("SBCCSettingSectionController"),
																	  objc_getClass("SBCCBrightnessSectionController"),
																	  objc_getClass("SBCCMediaControlsSectionController"),
																	  objc_getClass("SBCCAirStuffSectionController"),
																	  objc_getClass("SBCCQuickLaunchSectionController"),nil];
	NSArray *setting = [settingPlist objectForKey:@"Settings"];
	for (NSDictionary *sectionDict in setting) {
		if ([[sectionDict objectForKey:@"Identifier"] isEqualToString:@"com.apple.controlcenter.settings"])
		{
			[mutableClasses addObject:objc_getClass("SBCCSettingSectionController")];
			[defaultSetting removeObject:objc_getClass("SBCCSettingSectionController")];
		}
		else if ([[sectionDict objectForKey:@"Identifier"] isEqualToString:@"com.apple.controlcenter.brightness"])
		{
			[mutableClasses addObject:objc_getClass("SBCCBrightnessSectionController")];
			[defaultSetting removeObject:objc_getClass("SBCCBrightnessSectionController")];

		}
		else if ([[sectionDict objectForKey:@"Identifier"] isEqualToString:@"com.apple.controlcenter.media-controls"])
		{
			[mutableClasses addObject:objc_getClass("SBCCMediaControlsSectionController")];
			[defaultSetting removeObject:objc_getClass("SBCCMediaControlsSectionController")];
		}
		else if ([[sectionDict objectForKey:@"Identifier"] isEqualToString:@"com.apple.controlcenter.air-stuff"])
		{
			[mutableClasses addObject:objc_getClass("SBCCAirStuffSectionController")];
			[defaultSetting removeObject:objc_getClass("SBCCAirStuffSectionController")];
		}
		else if ([[sectionDict objectForKey:@"Identifier"] isEqualToString:@"com.apple.controlcenter.quick-launch"])
		{
			[mutableClasses addObject:objc_getClass("SBCCQuickLaunchSectionController")];
			[defaultSetting removeObject:objc_getClass("SBCCQuickLaunchSectionController")];
		}
		else 
		{
			NSBundle *cCBundle = [NSBundle bundleWithPath:[sectionDict objectForKey:@"Path"]];
			if ([cCBundle load])
			{
				if ([cCBundle principalClass])
				{
					[mutableClasses addObject:[cCBundle principalClass]];
				}
			}
		}
	}

	if ([mutableClasses count] < 5)
	{
		[mutableClasses addObjectsFromArray:defaultSetting];
	}

	controlCenterClasses = [NSArray arrayWithArray:mutableClasses];
}
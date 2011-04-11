/*
    DataURLMaker
    Copyright (C) 2006-2008 Sveinbjorn Thordarson <sveinbjornt@simnet.is>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

*/

#import "STUtil.h"


@implementation STUtil



+ (void)alert: (NSString *)message subText: (NSString *)subtext
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText: message];
	[alert setInformativeText: subtext];
	[alert setAlertStyle:NSWarningAlertStyle];
	
	if ([alert runModal] == NSAlertFirstButtonReturn) 
	{
		[alert release];
	} 
}

+ (void)fatalAlert: (NSString *)message subText: (NSString *)subtext
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText: message];
	[alert setInformativeText: subtext];
	[alert setAlertStyle: NSCriticalAlertStyle];
	
	if ([alert runModal] == NSAlertFirstButtonReturn) 
	{
		[alert release];
		ExitToShell();
	} 
}

+ (void)sheetAlert: (NSString *)message subText: (NSString *)subtext forWindow: (NSWindow *)window
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText: message];
	[alert setInformativeText: subtext];
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector: nil contextInfo:nil];
	[alert release];
}

+ (BOOL) proceedWarning: (NSString *)message subText: (NSString *)subtext
{

	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Proceed"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText: message];
	[alert setInformativeText: subtext];
	[alert setAlertStyle: NSWarningAlertStyle];
	
	if ([alert runModal] == NSAlertFirstButtonReturn) 
	{
		[alert release];
		return YES;
	}
	
	[alert release];
	return NO;
}

+ (UInt64) fileOrFolderSize: (NSString *)path
{
	UInt64			size = 0;
	NSFileManager	*manager = [NSFileManager defaultManager];
	BOOL			isDir;
	
	if (![manager fileExistsAtPath: path isDirectory: &isDir])
		return 0;
	
	if (isDir)
	{
		NSDirectoryEnumerator	*dirEnumerator = [manager enumeratorAtPath: path];
		while ([dirEnumerator nextObject])
		{
			if ([NSFileTypeRegular isEqualToString:[[dirEnumerator fileAttributes] fileType]])
				size += [[dirEnumerator fileAttributes] fileSize];
		}
	}
	else
	{
		size = [[manager fileAttributesAtPath: path traverseLink:YES] fileSize];
	}
	return (UInt64)size;
}

+ (NSString *) fileOrFolderSizeAsHumanReadable: (NSString *)path
{
	return [self sizeAsHumanReadable: [self fileOrFolderSize: path]];
}

+ (NSString *) sizeAsHumanReadable: (UInt64)size
{
	NSString	*str;
	
	if( size < 1024ULL ) 
	{
		/* bytes */
		str = [NSString stringWithFormat:@"%u B", (unsigned int)size];
	} 
	else if( size < 1048576ULL) {
		/* kbytes */
		str = [NSString stringWithFormat:@"%d KB", (long)size/1024];
	} else if( size < 1073741824ULL ) {
		/* megabytes */
		str = [NSString stringWithFormat:@"%.1f MB", size / 1048576.0];
	} else {
		/* gigabytes */
		str = [NSString stringWithFormat:@"%.1f GB", size / 1073741824.0];
	}
	return str;
}

+ (NSString *) cutSuffix: (NSString *)filename
{
	NSMutableArray	*components = (NSMutableArray *)[filename componentsSeparatedByString:@"."];

	//no suffix
	if ([components count] == 1)
		return filename;
	
	//*suffix* is too long
	if ((unsigned int)[(NSString *)[components objectAtIndex: [components count]-1] length] > 10)
		return filename;
	
	//remove suffix
	[components removeObjectAtIndex: [components count]-1];
	
	return ([components componentsJoinedByString: @"."]);
}

@end

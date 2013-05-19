//
//  DataURLMakerController.m
//  DataURLMaker2
//
//  Created by Sveinbjorn Thordarson on 19/06/2009.
//  Copyright 2009. All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

#import "DataURLMakerController.h"
#import "STUtil.h"
#import "NSDataAdditions.h"

@implementation DataURLMakerController
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [window center];
    [window makeKeyAndOrderFront: self];
    [dataURLTextField setFont:[NSFont userFixedPitchFontOfSize: 10.0]];
    [window registerForDraggedTypes: [NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    BOOL    isDir = NO;
    
    if([[NSFileManager defaultManager] fileExistsAtPath: filename isDirectory: &isDir] && !isDir)
    {
        [self loadFile: filename];
        return(YES);
    }
    return(NO);
}

- (IBAction)selectFile:(id)sender
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setPrompt:@"Select"];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories: NO];
    
    //run open panel
    [oPanel beginSheetForDirectory: nil file:nil types:nil modalForWindow: window 
                     modalDelegate: self didEndSelector: @selector(selectImageDidEnd:returnCode:contextInfo:) contextInfo: nil];
}


- (void)loadFile: (NSString *)path
{
    [progressIndicator setUsesThreadedAnimation: YES];
    [progressIndicator startAnimation: self];
    
    NSData *fileData = [[NSData alloc] initWithContentsOfFile: path];
    NSString *mimeType = [self mimeTypeForExtension: [path pathExtension]];
    /*NSImage *theImage = [[[NSImage alloc] initByReferencingFile: path] autorelease];
    NSSize imgSize = [theImage size];
    int width=imgSize.width;
    int height=imgSize.height;
    
    NSString *dimensionsString = [NSString stringWithFormat: @"%d x %d", width, height];
    
    NSData *imgData = [NSData dataWithContentsOfFile: path];
    if (imgData == NULL)
    {
        [STUtil sheetAlert: @"Error loading image" subText: @"An error occurred when loading data from the image file you selected" forWindow: window];
        return;
    }
    */
    //create img tag
    NSString *data64string = [fileData base64EncodingWithLineLength: 0];
    NSString *dataURLstring = [NSString stringWithFormat: @"data:%@;base64,%@\">", mimeType, data64string];
        
    // set text in fields
    [dataURLTextField setString: dataURLstring];
    /*[mimeTypeTextField setString: mimeType];
    [encSizeTextField setStringValue: [NSString stringWithFormat: @"Data URL Size: %@ (%d bytes)", [STUtil sizeAsHumanReadable: [data64string length]], [data64string length]]]; 
    //[dimensionsField setStringValue: dimensionsString];
    [sizeTextField setStringValue: [NSString stringWithFormat: @"%@ (%d bytes)", [STUtil fileOrFolderSizeAsHumanReadable: path], [STUtil fileOrFolderSize: path]]];
     */
    [progressIndicator stopAnimation: self];
}


- (IBAction)save:(id)sender
{
    /*NSString *name = [NSString stringWithFormat: @"%@.html", [[pathField stringValue] lastPathComponent]];
    
    NSSavePanel *sPanel = [NSSavePanel savePanel];file://localhost/Users/sveinbjorn/Desktop/%20Drasl/nerdonian.jpg
    [sPanel setPrompt:@"Save"];
    [sPanel beginSheetForDirectory: nil file: name modalForWindow: window modalDelegate: self didEndSelector: @selector(exportConfirmed:returnCode:contextInfo:) contextInfo: nil];
    [[dataURLTextField string] writeToFile: [sPanel filename] atomically: YES];
     */
}

- (IBAction)copyToClipboard:(id)sender
{
    [[NSPasteboard generalPasteboard] declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: self];
    [[NSPasteboard generalPasteboard] setString: [dataURLTextField string] forType: NSStringPboardType];
}

/*****************************************
 - Dragging and dropping for window
 *****************************************/

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard    *pboard = [sender draggingPasteboard];
    NSString        *filename;
    BOOL            isDir = FALSE;
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) 
    {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        filename = [files objectAtIndex: 0];//we only load the first dragged item
        if ([[NSFileManager defaultManager] fileExistsAtPath: filename isDirectory: &isDir] && !isDir)
        {
            [imageView setImage: [NSImage imageNamed: @"UnknownFSObjectIcon"]];
            [imageViewLabel setHidden: NO];
            [self loadFile: filename];
            
            return YES;
        }
    }
    return NO;
}


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender 
{
    NSPasteboard    *pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType])
    {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSString *filename = [files objectAtIndex: 0];
        NSImage *img = [[NSWorkspace sharedWorkspace] iconForFile: filename];
        [img setSize: NSMakeSize(128,128)];
        [imageView setImage: img];
        [imageViewLabel setHidden: YES];
        return NSDragOperationLink;
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    [imageView setImage: [NSImage imageNamed: @"UnknownFSObjectIcon"]];
    [imageViewLabel setHidden: NO];
    [window setBackgroundColor: [NSColor windowBackgroundColor]];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) 
        == NSDragOperationGeneric)
    {
        //this means that the sender is offering the type of operation we want
        //return that we want the NSDragOperationGeneric operation that they 
        //are offering
        return NSDragOperationGeneric;
    }
    else
    {
        //since they aren't offering the type of operation we want, we have 
        //to tell them we aren't interested
        return NSDragOperationNone;
    }
}


- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}


-(NSString*)mimeTypeForExtension:(NSString*)ext
{
    NSAssert( ext, @"Extension cannot be nil" );
    NSString* mimeType = nil;
    
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                            (CFStringRef)ext, NULL);
    if( !UTI ) return nil;
    
    CFStringRef registeredType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    if( !registeredType ) // check for edge case
    {
        if( [ext isEqualToString:@"m4v"] )
            mimeType = @"video/x-m4v";
        else if( [ext isEqualToString:@"m4p"] )
            mimeType = @"audio/x-m4p";
        // handle anything else here that you know is not registered
    } else {
        mimeType = NSMakeCollectable(registeredType);
    }
    
    CFRelease(UTI);
    return mimeType;
}

@end

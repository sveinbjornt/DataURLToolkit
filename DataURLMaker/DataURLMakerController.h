//
//  DataURLMakerController.h
//  DataURLMaker2
//
//  Created by Sveinbjorn Thordarson on 19/06/2009.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DataURLMakerController : NSObject 
{
	IBOutlet id window;
	IBOutlet id	dataURLTextField;
	IBOutlet id	imgTagCheckbox;
	IBOutlet id	sizeTextField;
	IBOutlet id mimeTypeTextField;
	IBOutlet id encSizeTextField;
	IBOutlet id imageView;
	IBOutlet id imageViewLabel;
	IBOutlet id windowShader;
	IBOutlet id progressIndicator;
}
-(IBAction)copyToClipboard: (id)sender;
-(IBAction)selectFile: (id)sender;
-(IBAction)save: (id)sender;
@end

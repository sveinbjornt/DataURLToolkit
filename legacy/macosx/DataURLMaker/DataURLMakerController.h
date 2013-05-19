//
//  DataURLMakerController.h
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


#import <Cocoa/Cocoa.h>


@interface DataURLMakerController : NSObject 
{
    IBOutlet id window;
    IBOutlet id    dataURLTextField;
    IBOutlet id    imgTagCheckbox;
    IBOutlet id    sizeTextField;
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

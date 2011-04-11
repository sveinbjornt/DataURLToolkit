//
//  DragImageView.h
//  DataURLMaker2
//
//  Created by Sveinbjorn Thordarson on 19/06/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DragImageView : NSImageView 
{
	IBOutlet id delegate;
}
-(void)setDelegate: (id)dg;
@end

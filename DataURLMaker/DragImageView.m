//
//  DragImageView.m
//  DataURLMaker2
//
//  Created by Sveinbjorn Thordarson on 19/06/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DragImageView.h"


@implementation DragImageView

-(void)setDelegate: (id)dg
{
		delegate = dg;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	return [delegate performDragOperation: sender];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender 
{
	return [delegate draggingEntered: sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[delegate draggingExited: sender];
}

@end

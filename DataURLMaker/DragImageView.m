//
//  DragImageView.m
//  DataURLMaker2
//
//  Created by Sveinbjorn Thordarson on 19/06/2009.
//  Copyright 2009 Sveinbjorn Thordarson. All rights reserved.
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

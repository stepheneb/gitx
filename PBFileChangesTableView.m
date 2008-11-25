//
//  PBFileChangesTableView.m
//  GitX
//
//  Created by Pieter de Bie on 09-10-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBFileChangesTableView.h"

@implementation PBFileChangesTableView

#pragma mark NSTableView overrides
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	if ([self delegate])
		return [[self delegate] menuForTable: self];

	return nil;
}

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL) local
{
	return NSDragOperationEvery;
}

@end

//
//  PBCommitList.m
//  GitX
//
//  Created by Pieter de Bie on 9/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBCommitList.h"
#import "PBGitRevisionCell.h"

@implementation PBCommitList

@synthesize mouseDownPoint;
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL) local
{
	NSLog(@"a");
	return NSDragOperationCopy;
}

- (void) keyDown: (id) event
{
	NSString* character = [event charactersIgnoringModifiers];

	if ([character isEqualToString:@" "])
	{
		if ([event modifierFlags] & NSShiftKeyMask)
			[webView scrollPageUp: self];
		else
			[webView scrollPageDown: self];
	}
	else if ([character rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"jkcv"]].location == 0)
		[webController sendKey: character];
	else
		[super keyDown: event];
}

- (void) copy:(id)sender
{
	[controller copyCommitInfo];
};	

- (void)mouseDown:(NSEvent *)theEvent
{
	mouseDownPoint = [[self window] mouseLocationOutsideOfEventStream];
	[super mouseDown:theEvent];
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows
							tableColumns:(NSArray *)tableColumns
								   event:(NSEvent *)dragEvent
								  offset:(NSPointPointer)dragImageOffset
{
	NSPoint location = [self convertPointFromBase:mouseDownPoint];
	int row = [self rowAtPoint:location];
	int column = [self columnAtPoint:location];
	PBGitRevisionCell *cell = (PBGitRevisionCell *)[self preparedCellAtColumn:column row:row];

	int index = [cell indexAtX:location.x];
	if (index == -1)
		return [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];

	NSRect rect = [cell rectAtIndex:index];

	NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(rect.size.width + 3, rect.size.height + 3)];
	rect.origin = NSMakePoint(0.5, 0.5);

	[newImage lockFocus];
	[cell drawLabelAtIndex:index inRect:rect];
	[newImage unlockFocus];

	*dragImageOffset = NSMakePoint(rect.size.width / 2 + 10, 0);
	return newImage;

}
@end

//
//  PBGitIndexController.h
//  GitX
//
//  Created by Pieter de Bie on 18-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitCommitController.h"
#import "PBChangedFile.h"

@interface PBGitIndexController : NSObject {
	IBOutlet NSArrayController *stagedFilesController, *unstagedFilesController;
	IBOutlet PBGitCommitController *commitController;

	IBOutlet PBIconAndTextCell* unstagedButtonCell;
	IBOutlet PBIconAndTextCell* stagedButtonCell;
	
	IBOutlet NSTableView *unstagedTable;
	IBOutlet NSTableView *stagedTable;	
}

- (void) stageFiles:(NSArray *)files;
- (void) unstageFiles:(NSArray *)files;

- (IBAction) rowClicked:(NSCell *) sender;
- (IBAction) tableClicked:(NSTableView *)tableView;

- (NSString *) stagedChangesForFile:(PBChangedFile *)file;
- (NSString *) unstagedChangesForFile:(PBChangedFile *)file;
@end

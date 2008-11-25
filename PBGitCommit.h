//
//  PBGitCommit.h
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRepository.h"
#import "PBGitTree.h"

@interface PBGitCommit : NSObject {
	NSString* sha;
	NSString* subject;
	NSString* author;
	NSString* details;
	NSString *_patch;
	NSArray* parents;
	NSMutableArray* refs;
	NSDate* date;
	char sign;
	id lineInfo;
	PBGitRepository* repository;
}

- initWithRepository:(PBGitRepository*) repo andSha:(NSString*) sha;

- (void)addRef:(id)ref;

@property (copy) NSString* sha;
@property (copy) NSString* subject;
@property (copy) NSString* author;
@property (retain) NSArray* parents;
@property (retain) NSMutableArray* refs;
@property (copy) NSDate* date;
@property (readonly) NSString* dateString;
@property (readonly) NSString* patch;
@property (assign) char sign;

@property (readonly) NSString* details;
@property (readonly) PBGitTree* tree;
@property (readonly) NSArray* treeContents;
@property (retain) PBGitRepository* repository;
@property (retain) id lineInfo;
@end

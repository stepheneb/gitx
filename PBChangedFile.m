//
//  PBChangedFile.m
//  GitX
//
//  Created by Pieter de Bie on 22-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBChangedFile.h"
#import "PBEasyPipe.h"

@implementation PBChangedFile

@synthesize path, status, hasCachedChanges, hasUnstagedChanges, commitBlobSHA, commitBlobMode;

- (id) initWithPath:(NSString *)p
{
	if (![super init])
		return nil;

	path = p;
	return self;
}

- (NSString *)indexInfo
{
	if (!self.commitBlobSHA)
		return [NSString stringWithFormat:@"0 0000000000000000000000000000000000000000\t%@\0", self.path];
	else
		return [NSString stringWithFormat:@"%@ %@\t%@\0", self.commitBlobMode, self.commitBlobSHA, self.path];
}

- (NSImage *) icon
{
	NSString *filename;
	switch (status) {
		case NEW:
			filename = @"new_file";
			break;
		case DELETED:
			filename = @"deleted_file";
			break;
		default:
			filename = @"empty_file";
			break;
	}
	NSString *p = [[NSBundle mainBundle] pathForResource:filename ofType:@"png"];
	return [[NSImage alloc] initByReferencingFile: p];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
	return NO;
}

@end

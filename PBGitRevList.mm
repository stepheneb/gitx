//
//  PBGitRevList.m
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

extern "C"
{
#include "git/oid.h"
}

#import "PBGitRevList.h"
#import "PBGitRepository.h"
#import "PBGitCommit.h"
#import "PBGitGrapher.h"
#import "PBGitRevSpecifier.h"

#include <ext/stdio_filebuf.h>
#include <iostream>
#include <string>

using namespace std;

@implementation PBGitRevList

@synthesize commits;
- initWithRepository: (id) repo
{
	repository = repo;
	[repository addObserver:self forKeyPath:@"currentBranch" options:0 context:nil];

	return self;
}

- (void) reload
{
	[self readCommitsForce: YES];
}

- (void) readCommitsForce: (BOOL) force
{
	// We use refparse to get the commit sha that we will parse. That way,
	// we can check if the current branch is the same as the previous one
	// and in that case we don't have to reload the revision list.

	// If no branch is selected, don't do anything
	if (![repository currentBranch])
		return;

	PBGitRevSpecifier* newRev = [repository currentBranch];
	NSString* newSha = nil;

	if (!force && newRev && [newRev isSimpleRef]) {
		newSha = [repository parseReference:[newRev simpleRef]];
		if ([newSha isEqualToString:lastSha])
			return;
	}
	lastSha = newSha;

	NSThread * commitThread = [[NSThread alloc] initWithTarget: self selector: @selector(walkRevisionListWithSpecifier:) object:newRev];
	[commitThread start];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
	change:(NSDictionary *)change context:(void *)context
{
	if (object == repository)
		[self readCommitsForce: NO];
}

- (void) walkRevisionListWithSpecifier: (PBGitRevSpecifier*) rev
{
	NSDate *start = [NSDate date];
	NSMutableArray* revisions = [NSMutableArray array];
	PBGitGrapher* g = [[PBGitGrapher alloc] initWithRepository: repository];
	NSDictionary* refs = [repository refs];

	NSMutableArray* arguments;
	BOOL showSign = [rev hasLeftRight];

	if (showSign)
		arguments = [NSMutableArray arrayWithObjects:@"log", @"-z", @"--early-output", @"--topo-order", @"--pretty=format:%H%x00%an%x00%s%x00%P%x00%at%x00%m", nil];
	else
		arguments = [NSMutableArray arrayWithObjects:@"log", @"-z", @"--early-output", @"--topo-order", @"--pretty=format:%H%x00%an%x00%s%x00%P%x00%at", nil];

	if (!rev)
		[arguments addObject:@"HEAD"];
	else
		[arguments addObjectsFromArray:[rev parameters]];

	if ([rev hasPathLimiter])
		[arguments insertObject:@"--children" atIndex:1];

	NSTask *task = [PBEasyPipe taskForCommand:[PBGitBinary path] withArgs:arguments inDir:[repository fileURL].path];
	[task launch];
	NSFileHandle* handle = [task.standardOutput fileHandleForReading];
	
	int fd = [handle fileDescriptor];
	__gnu_cxx::stdio_filebuf<char> buf(fd, std::ios::in);
	std::istream stream(&buf);

	int num = 0;
	while (true) {
		string sha;
		if (!getline(stream, sha, '\0'))
			break;

		// We reached the end of some temporary output. Show what we have
		// until now, and then start again. The sha of the next thing is still
		// in this buffer. So, we use a substring of current input.
		if (sha[1] == 'i') // Matches 'Final output'
		{
			num = 0;
			[self performSelectorOnMainThread:@selector(setCommits:) withObject:revisions waitUntilDone:NO];
			g = [[PBGitGrapher alloc] initWithRepository: repository];
			revisions = [NSMutableArray array];
			
			sha = sha.substr(sha.length() - 40, 40);
		}

		// From now on, 1.2 seconds
		git_oid oid;
		git_oid_mkstr(&oid, sha.c_str());
		PBGitCommit* newCommit = [[PBGitCommit alloc] initWithRepository:repository andSha:oid];

		string author;
		getline(stream, author, '\0');

		string subject;
		getline(stream, subject, '\0');

		string parentString;
		getline(stream, parentString, '\0');
		if (parentString.size() != 0)
		{
			if (((parentString.size() + 1) % 41) != 0) {
				NSLog(@"invalid parents: %i", parentString.size());
				continue;
			}
			int nParents = (parentString.size() + 1) / 41;
			git_oid *parents = (git_oid *)malloc(sizeof(git_oid) * nParents);
			int parentIndex;
			for (parentIndex = 0; parentIndex < nParents; ++parentIndex)
				git_oid_mkstr(parents + parentIndex, parentString.substr(parentIndex * 41, 40).c_str());
			
			newCommit.parentShas = parents;
			newCommit.nParents = nParents;
		}

		int time;
		stream >> time;
		char c;
		stream >> c;

		if (c != '\0')
			cout << "Error" << endl;
		
		[newCommit setSubject:[NSString stringWithUTF8String:subject.c_str()]];
		[newCommit setAuthor:[NSString stringWithUTF8String:author.c_str()]];
		NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
		[newCommit setDate:date];
		
		if (showSign)
		{
			stream >> c;
			if (c != '>' && c != '<' && c != '^' && c != '-')
				NSLog(@"Error loading commits: sign not correct");
			[newCommit setSign: c];
			stream >> c;
			if (c != '\0' && !stream.eof())
				NSLog(@"Error: unexpected char (expected '0', was: %c)", c);
		}

		[revisions addObject: newCommit];
		[g decorateCommit: newCommit];
		
		// 0.1 second on linux-2.6
		if (refs && [refs objectForKey:[newCommit realSha]])
			newCommit.refs = [refs objectForKey:[newCommit realSha]];
		
		if (++num % 1000 == 0)
			[self performSelectorOnMainThread:@selector(setCommits:) withObject:revisions waitUntilDone:NO];
	}
	
	NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
	NSLog(@"Loaded %i commits in %f seconds", num, duration);
	// Make sure the commits are stored before exiting.
	[self performSelectorOnMainThread:@selector(setCommits:) withObject:revisions waitUntilDone:YES];
	[task waitUntilExit];
}

@end

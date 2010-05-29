//
//  MIDIDocument.m
//  MIDIVis
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "MIDIDocument.h"

@implementation MIDIDocument

@synthesize docWindow, view;

- (NSString *)windowNibName {
	return @"MIDIDocument";
}

- (void)close {
	[file removeObserver:self forKeyPath:@"isPlaying"];
	[file stop];
	
	[super close];
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type {
	[self performSelector:@selector(loadFile:) withObject:fileName afterDelay:0.0f];
	
	return YES;
}

- (void)loadFile:(NSString *)fileName {
	file = [MIDIFile fileWithPath:fileName];
	[file addObserver:self forKeyPath:@"isPlaying" 
			  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
	
	[view loadFile:file];
	
	[[docWindow toolbar] validateVisibleItems];
}

- (IBAction)play:(id)sender {
	[file play];
	[view startScrolling];
}

- (IBAction)stop:(id)sender {
	[view stopScrolling];
	[file stop];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	if ([theItem action] == @selector(play:)) {
		return !file.isPlaying;
	}
	else if ([theItem action] == @selector(stop:)) {
		return file.isPlaying;
	}
	
	return NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
					   context:(void *)context {
	
	[[docWindow toolbar] validateVisibleItems];
	
	if (!file.isPlaying) {
		[self stop:nil];
	}
}

@end

//
//  MIDIDocument.m
//  MIDIVis
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "MIDIDocument.h"

@implementation MIDIDocument

@synthesize docWindow = _docWindow;
@synthesize view = _view;

#pragma mark -
#pragma mark Document

- (NSString *)windowNibName {
    return @"MIDIDocument";
}

- (void)close {
	[_file removeObserver:self forKeyPath:@"isPlaying"];
	[_file stop];
	
	[super close];
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type {
	[self performSelector:@selector(loadFile:) withObject:fileName afterDelay:0.0f];
	
	return YES;
}

- (void)loadFile:(NSString *)fileName {
	_file = [MIDIFile fileWithPath:fileName];
	[_file addObserver:self forKeyPath:@"isPlaying" 
			   options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
	
	[_view loadFile:_file];
	
	[[_docWindow toolbar] validateVisibleItems];
}

#pragma mark -
#pragma mark Actions

- (IBAction)play:(id)sender {
	[_file play];
	[_view startScrolling];
}

- (IBAction)stop:(id)sender {
	[_view stopScrolling];
	[_file stop];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	if ([theItem action] == @selector(play:)) {
		return !_file.isPlaying;
	}
	else if ([theItem action] == @selector(stop:)) {
		return _file.isPlaying;
	}
	
	return NO;
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
					   context:(void *)context {
	
	[[_docWindow toolbar] validateVisibleItems];
	
	if (!_file.isPlaying) {
		[self stop:nil];
	}
}

#pragma mark -

@end

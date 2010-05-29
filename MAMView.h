//
//  MAMView.h
//  MIDIVis
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "MIDIFile.h"

@interface MAMView : NSView {
  @private
	MIDIFile *file;
}

- (void)loadFile:(MIDIFile *)aFile;

- (void)startScrolling;
- (void)stopScrolling;

@end

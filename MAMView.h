//
//  MAMView.h
//  MIDIVis
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "MIDIFile.h"

@interface MAMView : NSView {
  @private
	MIDIFile *_file;
}

- (void)loadFile:(MIDIFile *)file;

- (void)startScrolling;
- (void)stopScrolling;

@end

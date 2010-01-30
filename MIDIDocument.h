//
//  MIDIDocument.h
//  MIDIVis
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "MAMView.h"

@interface MIDIDocument : NSDocument {
  @private
	NSWindow *_docWindow;;
	MAMView *_view;
	MIDIFile *_file;
}

@property (nonatomic, assign) IBOutlet NSWindow *docWindow;
@property (nonatomic, assign) IBOutlet MAMView *view;

- (IBAction)play:(id)sender;
- (IBAction)stop:(id)sender;

@end

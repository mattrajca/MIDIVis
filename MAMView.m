//
//  MAMView.m
//  MIDIVis
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "MAMView.h"

@interface MAMView ()

- (CGColorRef)colorForTrackAtIndex:(UInt32)index;

@end


@implementation MAMView

#define kLeftMargin 150.0f

#define kNoteHeight 10.0f
#define kNoteWidthPerSecond 40.0f

#pragma mark -
#pragma mark UI

- (void)awakeFromNib {
	self.layer.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(0.0f, 1.0f));
	
	CALayer *head = [CALayer layer];
	head.frame = CGRectMake(kLeftMargin, 0.0f, 1.0f, [self bounds].size.height);
	head.backgroundColor = (CGColorRef) CFMakeCollectable(CGColorCreateGenericGray(0.2f, 1.0f));
	
	[self.superview.layer addSublayer:head];
}

#pragma mark -
#pragma mark MIDI

- (void)loadFile:(MIDIFile *)file {
	if (_file)
		return;
	
	_file = file;
	
	for (NSDictionary *note in [_file notes]) {
		float timestamp = [[note valueForKey:MIDINoteTimestampKey] floatValue];
		int pitch = [[note valueForKey:MIDINotePitchKey] intValue] - 36; // cover only 4 octaves
		float duration = [[note valueForKey:MIDINoteDurationKey] floatValue];
		int trackIndex = [[note valueForKey:MIDINoteTrackIndexKey] intValue];
		
		CALayer *layer = [CALayer layer];
		layer.opacity = 0.8f;
		layer.backgroundColor = [self colorForTrackAtIndex:trackIndex];
		layer.cornerRadius = 2.0f;
		layer.frame = CGRectMake(kLeftMargin + timestamp * kNoteWidthPerSecond, pitch * kNoteHeight, duration * kNoteWidthPerSecond, kNoteHeight);
		
		[self.layer addSublayer:layer];
	}
}

#define kScrollerKey @"scroller"

- (void)startScrolling {
	CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"sublayerTransform.translation.x"];
	anim.byValue = [NSNumber numberWithFloat:-[_file beatsForSeconds:1.0f] * kNoteWidthPerSecond];
	anim.duration = 1.0f;
	anim.repeatCount = NSIntegerMax;
	anim.cumulative = YES;
	anim.additive = YES;
	anim.fillMode = kCAFillModeForwards;
	anim.removedOnCompletion = NO;
	
	[self.layer addAnimation:anim forKey:kScrollerKey];
}

- (void)stopScrolling {
	[self.layer removeAnimationForKey:kScrollerKey];
}

#pragma mark -

- (CGColorRef)colorForTrackAtIndex:(UInt32)index {
	int rem = index % 3;
	float gVal = index / 3.0f;
	float bVal = 2.0f;
	
	if (gVal >= 4.0f) {
		float diff = gVal - 3.0f;
		
		gVal = 3.0f;
		bVal = diff;
	}
	
	return (CGColorRef) CFMakeCollectable(CGColorCreateGenericRGB(0.1f + rem * 0.4f, 1.0f / gVal, 1.0f / bVal, 1.0f));
}

#pragma mark -

@end

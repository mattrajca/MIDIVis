//
//  MIDIFile.h
//  MIDIVis
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

extern NSString *const MIDINoteTimestampKey;
extern NSString *const MIDINoteDurationKey;
extern NSString *const MIDINotePitchKey;
extern NSString *const MIDINoteTrackIndexKey;

@interface MIDIFile : NSObject {
  @private
	MusicPlayer _player;
	MusicSequence _sequence;
	MusicTimeStamp _sequenceLength;
	NSTimer *_checkTimer;
}

@property (nonatomic, readonly) BOOL isPlaying;

+ (id)fileWithPath:(NSString *)path;
- (id)initWithPath:(NSString *)path;

- (MusicTimeStamp)beatsForSeconds:(Float64)seconds;
- (NSArray *)notes;

- (BOOL)play;
- (BOOL)stop;

@end

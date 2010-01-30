//
//  MIDIFile.m
//  MIDIVis
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "MIDIFile.h"

@interface MIDIFile ()

- (BOOL)hasNextEvent:(MusicEventIterator)iterator;
- (MusicTimeStamp)getSequenceLength:(MusicSequence)sequence;

@end


NSString *const MIDINoteTimestampKey = @"ts";
NSString *const MIDINoteDurationKey = @"dr";
NSString *const MIDINotePitchKey = @"pt";
NSString *const MIDINoteTrackIndexKey = @"tk";

@implementation MIDIFile

@dynamic isPlaying;

#pragma mark -
#pragma mark Initialization

+ (id)fileWithPath:(NSString *)path {
	return [[self alloc] initWithPath:path];
}

- (id)initWithPath:(NSString *)path {
	self = [super init];
	if (self) {
		NSURL *url = [NSURL fileURLWithPath:path];
		
		NewMusicSequence(&_sequence);
		
		if (MusicSequenceFileLoad(_sequence, (CFURLRef) url, 0, 0) != noErr) {
			return nil;
		}
	}
	return self;
}

#pragma mark -
#pragma mark MIDI

- (MusicTimeStamp)beatsForSeconds:(Float64)seconds {
	MusicTimeStamp beats = 0;
	MusicSequenceGetBeatsForSeconds(_sequence, 1.0f, &beats);
	
	return beats;
}

- (NSArray *)notes {
	NSMutableArray *notes = [[NSMutableArray alloc] init];
	
	UInt32 tracksCount = 0;
	
	if (MusicSequenceGetTrackCount(_sequence, &tracksCount) != noErr)
		return nil;
	
	for (UInt32 i = 0; i < tracksCount; i++) {
		MusicTrack track = NULL;
		MusicSequenceGetIndTrack(_sequence, i, &track);
		
		MusicEventIterator iterator = NULL;
		NewMusicEventIterator(track, &iterator);
		
		while ([self hasNextEvent:iterator]) {
			MusicEventIteratorNextEvent(iterator);
			
			MusicTimeStamp timestamp = 0;
			MusicEventType eventType = 0;
			const void *eventData = NULL;
			UInt32 eventDataSize = 0;
			
			MusicEventIteratorGetEventInfo(iterator, &timestamp, &eventType, &eventData, &eventDataSize);
			
			if (eventType == kMusicEventType_MIDINoteMessage) {
				const MIDINoteMessage *noteMessage = (const MIDINoteMessage *)eventData;
				
				NSDictionary *note = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithFloat:timestamp], MIDINoteTimestampKey, 
									  [NSNumber numberWithFloat:noteMessage->duration], MIDINoteDurationKey,
									  [NSNumber numberWithShort:noteMessage->note], MIDINotePitchKey,
									  [NSNumber numberWithInt:i], MIDINoteTrackIndexKey, nil];
									  
				[notes addObject:note];
			}
		}
		
		DisposeMusicEventIterator(iterator);
	}
	
	return notes;
}

#pragma mark -

- (BOOL)play {
	if (!_player) {
		NewMusicPlayer(&_player);
		
		MusicPlayerSetSequence(_player, _sequence);
		MusicPlayerPreroll(_player);
	}
	else {
		if (self.isPlaying) {
			[self stop];
			
			return NO;
		}
	}
	
	_sequenceLength = [self getSequenceLength:_sequence];
	
	MusicPlayerSetTime(_player, 0.0f);
	
	if (MusicPlayerStart(_player) != noErr)
		return NO;
	
	_checkTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(checkForEnd:)
												 userInfo:nil repeats:YES];
	 
	return YES;
}

- (BOOL)stop {
	if (!self.isPlaying)
		return NO;
	
	[_checkTimer invalidate];
	
	[self willChangeValueForKey:@"isPlaying"];
	MusicPlayerStop(_player);
	[self didChangeValueForKey:@"isPlaying"];
	
	return YES;
}

- (BOOL)isPlaying {
	Boolean playing = false;
	MusicPlayerIsPlaying(_player, &playing);
	
	return (BOOL) playing;
}

#pragma mark -
#pragma mark Helpers

- (void)checkForEnd:(NSTimer *)timer {
	MusicTimeStamp time = 0.0f;
	MusicPlayerGetTime(_player, &time);
	
	if (time > _sequenceLength) {
		[self stop];
	}
}

- (BOOL)hasNextEvent:(MusicEventIterator)iterator {
	Boolean hasNext = false;
	MusicEventIteratorHasNextEvent(iterator, &hasNext);
	
	return (BOOL) hasNext;
}

- (MusicTimeStamp)getSequenceLength:(MusicSequence)sequence {
    UInt32 tracks;
    MusicTimeStamp sequenceLength = 0.0f;
	
    if (MusicSequenceGetTrackCount(_sequence, &tracks) != noErr)
		return sequenceLength;
	
    for (UInt32 i = 0; i < tracks; i++) {
        MusicTrack track = NULL;
        MusicTimeStamp trackLen = 0;
		
        UInt32 trackLenLen = sizeof(trackLen);
		
        MusicSequenceGetIndTrack(_sequence, i, &track);
        MusicTrackGetProperty(track, kSequenceTrackProperty_TrackLength, &trackLen, &trackLenLen);
		
        if (sequenceLength < trackLen)
            sequenceLength = trackLen;
    }
	
    return sequenceLength;
}

#pragma mark -

- (void)finalize {
	DisposeMusicPlayer(_player);
	DisposeMusicSequence(_sequence);
	
	[super finalize];
}

@end

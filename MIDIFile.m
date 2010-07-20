//
//  MIDIFile.m
//  MIDIVis
//
//  Copyright Matt Rajca 2010. All rights reserved.
//

#import "MIDIFile.h"

@interface MIDIFile ()

- (void)checkForEnd:(NSTimer *)timer;
- (BOOL)hasNextEvent:(MusicEventIterator)iterator;
- (MusicTimeStamp)getSequenceLength:(MusicSequence)aSequence;

@end


NSString *const MIDINoteTimestampKey = @"ts";
NSString *const MIDINoteDurationKey = @"dr";
NSString *const MIDINotePitchKey = @"pt";
NSString *const MIDINoteTrackIndexKey = @"tk";

@implementation MIDIFile

@dynamic isPlaying;

+ (id)fileWithPath:(NSString *)path {
	return [[self alloc] initWithPath:path];
}

- (id)initWithPath:(NSString *)path {
	self = [super init];
	if (self) {
		NSURL *url = [NSURL fileURLWithPath:path];
		
		NewMusicSequence(&sequence);
		
		if (MusicSequenceFileLoad(sequence, (CFURLRef) url, 0, 0) != noErr) {
			return nil;
		}
	}
	return self;
}

- (MusicTimeStamp)beatsForSeconds:(Float64)seconds {
	MusicTimeStamp beats = 0;
	MusicSequenceGetBeatsForSeconds(sequence, 1.0f, &beats);
	
	return beats;
}

- (NSArray *)notes {
	UInt32 tracksCount = 0;
	
	if (MusicSequenceGetTrackCount(sequence, &tracksCount) != noErr)
		return nil;
	
	NSMutableArray *notes = [[NSMutableArray alloc] init];
	
	for (UInt32 i = 0; i < tracksCount; i++) {
		MusicTrack track = NULL;
		MusicSequenceGetIndTrack(sequence, i, &track);
		
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

- (BOOL)play {
	if (!player) {
		NewMusicPlayer(&player);
		
		MusicPlayerSetSequence(player, sequence);
		MusicPlayerPreroll(player);
	}
	else {
		if (self.isPlaying) {
			[self stop];
			
			return NO;
		}
	}
	
	sequenceLength = [self getSequenceLength:sequence];
	
	MusicPlayerSetTime(player, 0.0f);
	
	if (MusicPlayerStart(player) != noErr)
		return NO;
	
	checkTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(checkForEnd:)
												userInfo:nil repeats:YES];
	 
	return YES;
}

- (BOOL)stop {
	if (!self.isPlaying)
		return NO;
	
	[checkTimer invalidate];
	
	[self willChangeValueForKey:@"isPlaying"];
	MusicPlayerStop(player);
	[self didChangeValueForKey:@"isPlaying"];
	
	return YES;
}

- (BOOL)isPlaying {
	Boolean playing = false;
	MusicPlayerIsPlaying(player, &playing);
	
	return (BOOL) playing;
}

- (void)checkForEnd:(NSTimer *)timer {
	MusicTimeStamp time = 0.0f;
	MusicPlayerGetTime(player, &time);
	
	if (time > sequenceLength) {
		[self stop];
	}
}

- (BOOL)hasNextEvent:(MusicEventIterator)iterator {
	Boolean hasNext = false;
	MusicEventIteratorHasNextEvent(iterator, &hasNext);
	
	return (BOOL) hasNext;
}

- (MusicTimeStamp)getSequenceLength:(MusicSequence)aSequence {
	UInt32 tracks;
	MusicTimeStamp len = 0.0f;
	
	if (MusicSequenceGetTrackCount(sequence, &tracks) != noErr)
		return len;
	
	for (UInt32 i = 0; i < tracks; i++) {
		MusicTrack track = NULL;
		MusicTimeStamp trackLen = 0;
		
		UInt32 trackLenLen = sizeof(trackLen);
		
		MusicSequenceGetIndTrack(sequence, i, &track);
		MusicTrackGetProperty(track, kSequenceTrackProperty_TrackLength, &trackLen, &trackLenLen);
		
		if (len < trackLen)
			len = trackLen;
	}
	
	return len;
}

- (void)finalize {
	DisposeMusicPlayer(player);
	DisposeMusicSequence(sequence);
	
	[super finalize];
}

@end

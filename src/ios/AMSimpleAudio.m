/*
 The MIT License (MIT)
 
 Copyright (c) 2014
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */
#import "AMSimpleAudio.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation AMSimpleAudio

@synthesize synthesizer;
@synthesize sounds;

- (void) play:(CDVInvokedUrlCommand *)command
{
    if (sounds == nil){
        sounds = [[NSMutableDictionary alloc]init];
    }
    
    NSString* file = [command.arguments objectAtIndex:1];
    
    NSMutableArray *soundFiles = [sounds objectForKey:file];
    
    if (soundFiles == nil) {
        soundFiles = [[NSMutableArray alloc] init];
        [sounds setObject:soundFiles forKey:file];
    }
    
    AVAudioPlayer *player = nil;
    
    for (AVAudioPlayer *audioPlayer in soundFiles) {
        if (!audioPlayer.isPlaying) {
            player = audioPlayer;
            break;
        }
    }
    
    if (player == nil) {
        NSString* path = [file stringByDeletingPathExtension];
        NSString* extension = [file pathExtension];
        
        NSURL* soundUrl = [[NSBundle mainBundle] URLForResource:path withExtension:extension];
        player =[[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
        [soundFiles addObject:player];
    }
    
    [player prepareToPlay];
    [player play];
}

- (void) setVolume:(CDVInvokedUrlCommand *)command
{
    float newVal = [[command.arguments objectAtIndex:1] floatValue];
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:newVal];
}

- (void) getVolume:(CDVInvokedUrlCommand *)command
{
    float volume = [[AVAudioSession sharedInstance] outputVolume];
    [[self commandDelegate] evalJs:[NSString stringWithFormat:@"window.dispatchEvent(new CustomEvent('volume', {'detail':{'data':%f}}));", volume]];
}

- (void) say:(CDVInvokedUrlCommand *)command
{
    if (!self.synthesizer) {
        self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    }
    
    NSArray* arguments = command.arguments;
    NSString* text = [arguments objectAtIndex:1];
    
    AVSpeechUtterance *speechUtterance = [[AVSpeechUtterance alloc] initWithString:text];
    speechUtterance.rate = 0.2; // default = 0.5 ; min = 0.0 ; max = 1.0
    speechUtterance.pitchMultiplier = 1.0; // default = 1.0 ; range of 0.5 - 2.0
    
    [self.synthesizer speakUtterance:speechUtterance];
}
@end


@implementation MainViewController (VolumeNotifications)

- (void) applicationEnteredForeground:(NSNotification *)notification {
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
    
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    // Modifying Playback Mixing Behavior, allow playing music in other apps
    OSStatus propertySetError = 0;
    UInt32 allowMixing = true;
    
    propertySetError = AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers,
                                                sizeof (allowMixing),
                                                &allowMixing);
    
    [audioSession setActive:YES error:nil];
    
    [audioSession addObserver:self  forKeyPath:@"outputVolume"  options:0  context:nil];
}

- (void) applicationEnteredBackground: (NSNotification *) notification
{
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    [audioSession removeObserver:self forKeyPath:@"outputVolume"];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnteredForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnteredBackground:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [self applicationEnteredForeground:nil];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqual:@"outputVolume"]) {
        float volume = [[AVAudioSession sharedInstance] outputVolume];
        
        [[self commandDelegate] evalJs:[NSString stringWithFormat:@"window.dispatchEvent(new CustomEvent('volume', {'detail':{'data':%f}}));", volume]];
        
    }
}

@end
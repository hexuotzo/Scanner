//
//  ViewController.m
//  Scanner
//
//  Created by liluo on 3/26/14.
//  Copyright (c) 2014 liluo. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic) BOOL isScanning;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

- (BOOL)startScanning;
- (BOOL)stopScanning;
- (void)loadBeepSound;

@end

@implementation ViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
	_isScanning = NO;
  _captureSession = nil;
  
  [self loadBeepSound];
}


- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


- (BOOL)startScanning {
  NSError *error;
  
  AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice
                                                                      error:&error];
  if (!input) {
    NSLog(@"%@", [error localizedDescription]);
    return NO;
  }
  
  _captureSession = [[AVCaptureSession alloc] init];
  [_captureSession addInput:input];

  AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
  [_captureSession addOutput:captureMetadataOutput];
  
  dispatch_queue_t dispatchQueue;
  dispatchQueue = dispatch_queue_create("myQueue", NULL);
  [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
  [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
  
  _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
  [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
  [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
  [_viewPreview.layer addSublayer:_videoPreviewLayer];
  
  [_captureSession startRunning];

  return YES;
}


- (BOOL)stopScanning {
  [_captureSession stopRunning];
  _captureSession = nil;
  [_videoPreviewLayer removeFromSuperlayer];
  return YES;
}


- (IBAction)startStopScanning:(id)sender {
  if (!_isScanning) {
    if ([self startScanning]) {
      _bbitemStart.title = @"Stop";
      _lblStatus.text = @"Scanning for QR Code...";
    }
    
  } else {
    [self stopScanning];
    _bbitemStart.title = @"Start!";
    _lblStatus.text = @"QR Code scanner is not yet running...";
  }
  
  _isScanning = !_isScanning;
}


-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
  if (metadataObjects != nil && [metadataObjects count] > 0) {
    AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
    if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
      [_lblStatus performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
      
      [self performSelectorOnMainThread:@selector(stopScanning) withObject:nil waitUntilDone:NO];
      [_bbitemStart performSelectorOnMainThread:@selector(setTitle:) withObject:@"Start!" waitUntilDone:NO];
      _isScanning = NO;
      
      if (_audioPlayer) {
        [_audioPlayer play];
      }
    }
  }
}


- (void)loadBeepSound {
  NSString *beepFilePath = [[NSBundle mainBundle] pathForResource:@"beep"
                                                           ofType:@"mp3"];

  NSURL *beepURL = [NSURL URLWithString:beepFilePath];
  NSError *error;
  
  _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:&error];
  
  if (error) {
    NSLog(@"Could not play bee file.");
    NSLog(@"%@", [error localizedDescription]);
  } else {
    [_audioPlayer prepareToPlay];
  }
}
@end

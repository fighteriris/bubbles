//
//  ViewController.m
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-5.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
@synthesize bubble;
@synthesize textMessage, imageMessage;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.bubble = [[WDBubble alloc] init];
    self.bubble.delegate = self;
    [self.bubble initSocket];
    [self.bubble publishService];
    [self.bubble browseServices];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - IBOultets

- (IBAction)sendText:(id)sender {
    [self.bubble broadcastMessage:[WDMessage messageWithText:textMessage.text]];
    [textMessage resignFirstResponder];
}

- (IBAction)selectImage:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *t = [[UIImagePickerController alloc] init];
        t.delegate = self;
        [self presentModalViewController:t animated:YES];
        [t release];
    }
}

- (IBAction)sendImage:(id)sender {
    [self.bubble broadcastMessage:[WDMessage messageWithText:textMessage.text]];
    [textMessage resignFirstResponder];
}

#pragma mark - Events

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [textMessage resignFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	[textMessage resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textMessage resignFirstResponder];
    return YES;
}

#pragma mark - WDBubbleDelegate

- (void)didReceiveText:(NSString *)text {
    DLog(@"VC didReceiveText %@", text);
    textMessage.text = text;
}

- (void)didReceiveImage:(NSString *)image {
    DLog(@"VC didReceiveImage %@", image);
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    DLog(@"VC didFinishPickingMediaWithInfo %@", image);
    imageMessage.image = image;
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissModalViewControllerAnimated:YES];
}

@end

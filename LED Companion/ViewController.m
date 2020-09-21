//
//  ViewController.m
//  LED Companion
//
//  Created by Jonatan Yde on 20/09/2020.
//

#import "ViewController.h"

#define HOST @"ledpi"
#define PORT 8888

@interface ViewController ()
{
    Communicator *com;
}

@end

@implementation ViewController
@synthesize imageSource, scrollView ;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollView.delegate = self;
    self.scrollView.zoomScale = 1.0;
    scrollView.maximumZoomScale = 5.0;
    scrollView.minimumZoomScale = 1.0;
    self.scrollView.clipsToBounds = YES;
    
    com = [[Communicator alloc] init];
    com.delegate = self;
    
    // Do any additional setup after loading the view.
}
- (IBAction)didTapLoad:(id)sender {
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary; // | UIImagePickerControllerSourceTypeCamera;
    ipc.allowsEditing = NO;
    ipc.delegate = self;
    [self presentViewController:ipc animated:YES completion:nil];
}
- (IBAction)didTapSend:(id)sender {
    if(![com isConnected])
        [com connectToServer:HOST onPort:PORT];


    UIImage *img = [self imageFromView: self.scrollView];
    NSData *imageData = UIImagePNGRepresentation(img);

    
    [com sendMessage:@"FILE=/screen.png"];
    [com sendData:imageData];
    
    
}



- (IBAction)didTapClear:(id)sender {
    if(![com isConnected])
        [com connectToServer:HOST onPort:PORT];
    
    [com sendMessage:@"STOP"];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if([com isConnected])
        [com close];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    
    imageSource.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    imageSource.contentMode = UIViewContentModeCenter;
    [self.imageSource sizeToFit];
    scrollView.contentSize = imageSource.frame.size;
    
    
    
    float min_factor = scrollView.frame.size.width / imageSource.image.size.width;
    self.scrollView.minimumZoomScale = min_factor;
    
    scrollView.zoomScale = min_factor;
    
    /*
    NSLog(@"Zoom scale: %f", self.scrollView.zoomScale);
    NSLog(@"ImageSource size: %fx%f", imageSource.frame.size.width, imageSource.frame.size.height);
    NSLog(@"Image size: %fx%f", imageSource.image.size.width, imageSource.image.size.height);
    NSLog(@"ScrollView contentSize: %fx%f", scrollView.contentSize.width, scrollView.contentSize.height);
     */
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(UIImage *)imageFromView:(UIScrollView *)view
{
    UIGraphicsBeginImageContext(view.frame.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextRotateCTM(context, 2*M_PI); //otherwise it will be upside down due to diffrent coordinate systems
    
    float destRatio = 128.0/96.0;
    float srcRatio = view.frame.size.width / view.frame.size.height;
    CGRect crop;
    if(destRatio < srcRatio)
        crop = CGRectMake((view.frame.size.width - view.frame.size.height*destRatio)/2,0, view.frame.size.height*destRatio, view.frame.size.height  );
    else
        crop = CGRectMake(0,0, view.frame.size.width, view.frame.size.width/destRatio  );
    
    CGPoint offset = view.contentOffset;
    
    CGContextTranslateCTM(context, -offset.x, -offset.y);

    
    [view.layer renderInContext:context];
    
    UIImage *outputImage = [UIImage imageWithCGImage: CGImageCreateWithImageInRect(UIGraphicsGetImageFromCurrentImageContext().CGImage, crop)];
    
    UIGraphicsEndImageContext();

    return outputImage;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return imageSource;
}
- (void)didRecieveMessage:(NSString *)message {
    
    if([message isEqual:@"DONE"])
    {
        [com close];
    }
}

@end

//
//  ViewController.m
//  LED Companion
//
//  Created by Jonatan Yde on 20/09/2020.
//

#import "ViewController.h"

//#define HOST @"ledpi"
//#define PORT 8888

@interface ViewController ()
{
    Communicator *com;
    NSString *host;
    int port;
    CGSize displaySize;
}

@end

@implementation ViewController
@synthesize imageSource, scrollView ;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSettings) name:NSUserDefaultsDidChangeNotification object:nil];

    self.scrollView.delegate = self;
    self.scrollView.zoomScale = 1.0;
    scrollView.maximumZoomScale = 5.0;
    scrollView.minimumZoomScale = 1.0;
    scrollView.clipsToBounds = YES;
    
    
    
    com = [[Communicator alloc] init];
    com.delegate = self;
    
    /*
    imageSource.image = [UIImage imageNamed:@"images"];
    imageSource.contentMode = UIViewContentModeCenter;
    [self.imageSource sizeToFit];
    scrollView.contentSize = imageSource.frame.size;
        
    float min_factor = scrollView.frame.size.width / imageSource.image.size.width;
    self.scrollView.minimumZoomScale = min_factor;
    scrollView.zoomScale = min_factor;
    */
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadSettings];
}

- (IBAction)didTapLoad:(id)sender {
    UIAlertController *imagePickerAlert = [UIAlertController alertControllerWithTitle:@"Source" message:@"Select photo source." preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *selectCamera = [UIAlertAction actionWithTitle:@"Photo Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
        ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        ipc.allowsEditing = NO;
        ipc.delegate = self;
        [self presentViewController:ipc animated:YES completion:nil];

        
    }];
    UIAlertAction *selectPhoto = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
        ipc.sourceType = UIImagePickerControllerSourceTypeCamera; 
        ipc.allowsEditing = NO;
        ipc.delegate = self;
        [self presentViewController:ipc animated:YES completion:nil];

        
    }];
    
    [imagePickerAlert addAction:selectPhoto];
    [imagePickerAlert addAction: selectCamera];
    
    [self presentViewController:imagePickerAlert animated:YES completion:^{
        
    }];
    
}

- (IBAction)didTapSend:(id)sender {
    
    
    if(![com isConnected])
        [com connectToServer:host onPort:port];

    UIImage *img = [self imageFromView: self.scrollView];
    img = [self resizeImage:img toSize:displaySize];
    
    NSData *imageData = UIImagePNGRepresentation(img);

    [com sendMessage:@"FILE=/screen.png"];
    [com sendData:imageData];
}



- (IBAction)didTapClear:(id)sender {
    if(![com isConnected])
        [com connectToServer:host onPort:port];
    
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
    
    float destRatio = displaySize.width/displaySize.height;
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

- (UIImage *)resizeImage:(UIImage*) image toSize:(CGSize)newSize
{
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:newSize];
    UIImage *output = [renderer imageWithActions:^(UIGraphicsImageRendererContext*_Nonnull myContext) {
        [image drawInRect:(CGRect) {.origin = CGPointZero, .size = newSize}];
    }];
    return [output imageWithRenderingMode:image.renderingMode];
}

-(void)reloadSettings
{
    host = [[NSUserDefaults standardUserDefaults] objectForKey:@"pref_host"];
    port = [[[NSUserDefaults standardUserDefaults] objectForKey:@"pref_port"] intValue];
    displaySize = CGSizeMake([[[NSUserDefaults standardUserDefaults] objectForKey:@"pref_width"] intValue], [[[NSUserDefaults standardUserDefaults] objectForKey:@"pref_height"] intValue]);
    
    //Adapt to LED-display aspect ratio
    for (NSLayoutConstraint *constraint in scrollView.constraints) {
        if([constraint.identifier isEqual:@"aspect"])
        {
            //NSLog(@"Before: %@", constraint);
            [scrollView removeConstraint: constraint];
            NSLayoutConstraint *aspect = [NSLayoutConstraint
                                                  constraintWithItem:scrollView
                                                  attribute:NSLayoutAttributeHeight
                                                  relatedBy:NSLayoutRelationEqual
                                                  toItem:scrollView
                                                  attribute:NSLayoutAttributeWidth
                                                  multiplier:displaySize.height/displaySize.width
                                                  constant:0];
            aspect.identifier = @"aspect";
            [scrollView addConstraint:aspect];
            //NSLog(@"After: %@", aspect);
        }
    }
}

@end

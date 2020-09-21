//
//  ViewController.h
//  LED Companion
//
//  Created by Jonatan Yde on 20/09/2020.
//

#import <UIKit/UIKit.h>
#import "Communicator.h"

@interface ViewController : UIViewController<UIScrollViewDelegate, UINavigationControllerDelegate,UIImagePickerControllerDelegate,MessageDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageSource;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end


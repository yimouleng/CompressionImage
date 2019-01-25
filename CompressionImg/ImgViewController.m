//
//  ImgViewController.m
//  CompressionImg
//
//  Created by Eli on 2019/1/24.
//  Copyright © 2019 Ely. All rights reserved.
//

#import "ImgViewController.h"
#import "UIImage+Compression.h"
#import "UIAlertCategory.h"

@interface ImgViewController ()<UIAlertViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *imgBtn;
@property (weak, nonatomic) IBOutlet UIImageView *originalImg;
@property (weak, nonatomic) IBOutlet UILabel *originalSize;
@property (weak, nonatomic) IBOutlet UIImageView *compressionImg;
@property (weak, nonatomic) IBOutlet UILabel *compressionSize;
@property (nonatomic,strong) UIImagePickerController *imagePicker;
@property (nonatomic ,strong) UIImage * image;
@end

@implementation ImgViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.imgBtn addTarget:self action:@selector(clickImg) forControlEvents:UIControlEventTouchUpInside];
}

- (void)clickImg {
    
    UIAlertCategory * a = [[UIAlertCategory alloc] initWithTitle:@"选择图片" WithMessage:nil];
    
    [a addButton:ALERT_BUTTON_OK WithTitle:@"拍照" WithAction:^(void *action) {
        UIImagePickerController *PickerImage = [[UIImagePickerController alloc]init];
        //获取方式:通过相机
        PickerImage.sourceType = UIImagePickerControllerSourceTypeCamera;
        PickerImage.delegate = self;
        [self presentViewController:PickerImage animated:YES completion:nil];
    }];
    [a addButton:ALERT_BUTTON_OK WithTitle:@"相册选择" WithAction:^(void *action) {
        
        UIImagePickerController *PickerImage = [[UIImagePickerController alloc]init];
        
        PickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        //自代理
        PickerImage.delegate = self;
        //页面跳转
        [self presentViewController:PickerImage animated:YES completion:nil];
        
    }];
    [a show];
    
    
}

- (void)upData{
    [self.originalImg setImage:self.image];
    
    self.originalSize.text = [NSString stringWithFormat:@"大小%@宽%.1f高%.1f", [self bytesToAvaiUnit:UIImageJPEGRepresentation(self.image, 1.0).length],self.image.size.width,self.image.size.height];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage * comImg = [self.image compressToImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.compressionImg setImage:comImg];
             self.compressionSize.text = [NSString stringWithFormat:@"大小%@宽%.1f高%.1f",[self bytesToAvaiUnit:UIImageJPEGRepresentation(comImg, 1.0).length],comImg.size.width,comImg.size.height];
        });
    });
  
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^{}];
    self.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self upData];
}


- (NSString *)bytesToAvaiUnit:(int64_t)bytes{
    if(bytes < 1024)
    {
        return [NSString stringWithFormat:@"%lldB", bytes];
        
    }else if(bytes >= 1024 && bytes < 1024 * 1024)
    {
        return [NSString stringWithFormat:@"%.1fKB", (double)bytes / 1024];}// KB
    else if(bytes >= 1024 * 1024 && bytes < 1024 * 1024 * 1024)
    {
        return [NSString stringWithFormat:@"%.2fMB", (double)bytes / (1024 * 1024)];} // MB
    else
    {
        return [NSString stringWithFormat:@"%.3fGB", (double)bytes / (1024 * 1024 * 1024)]; // GB
        
    }
    
}
    
@end

//
//  UIImage+Compression.m
//  CompressionImg
//
//  Created by Eli on 2019/1/24.
//  Copyright © 2019 Ely. All rights reserved.
//

#import "UIImage+Compression.h"

static CGFloat const BOUNDARY = 1334;  //图片限定长度值
static CGFloat  MAXQUALITY = 0.8;  //初始最高压缩质量系数
static CGFloat  MINQUALITY = 0.5;  //初始最低压缩质量系数
static CGFloat  SIZE = 200; //图片限定大小，单位KB

@implementation UIImage (Compression)



- (UIImage *)compressToImage {
    CGSize size = [self imageSize];
    UIImage *reImage = [self toSourceImageWithSize:size];
    NSData * data = [self cycleCompressImage:reImage];
    UIImage * compressImg = [UIImage imageWithData:data];
    return compressImg;
}

/**
 异步循环压缩图片直到限定大小
 或者 达到最低压缩系数
 返回图片JPG二进制
 */
- (NSData *)cycleCompressImage:(UIImage *)image {
   
    NSData *imgData  = UIImageJPEGRepresentation(image, MAXQUALITY);

    // 压缩图片如果超过限制大小，则循环递减
    // 返回以 JPEG 格式表示的图片的二进制数据 如没有最低系数，去掉&&后参数
    while (imgData.length > SIZE*1024 && MAXQUALITY >= MINQUALITY) {
        @autoreleasepool {
            MAXQUALITY -= 0.05;
            imgData = UIImageJPEGRepresentation(image, MAXQUALITY);
            NSLog(@"\n%ld\n%f", imgData.length,MAXQUALITY);
        }
    }

    // 返回图片的二进制数据
    return  imgData;

}

/**
 根据图片尺寸和对应策略得到图片Size
 
 @return  图片Size
 */
- (CGSize)imageSize {
    
    CGFloat width = self.size.width;
    CGFloat height = self.size.height;
    
    // 宽高均<= 设定长度，图片尺寸大小保持不变
    if (width < BOUNDARY && height < BOUNDARY) {
        return CGSizeMake(width, height);
    }
    
    //获取宽高系数
    CGFloat ratio = MAX(width, height) / MIN(width, height);
    
    // 宽或高> 设定长度 && 宽高比<= 2，取较大值等于设定长度，较小值等比例压缩
    if (ratio <= 2) {
        CGFloat MaxEdgeRatio = MAX(width, height) / BOUNDARY;
        if (width > height) {
            width = BOUNDARY;
            height = height / MaxEdgeRatio;
        } else {
            height = BOUNDARY;
            width = width / MaxEdgeRatio;
        }
    } else {
        // 宽高均> 设定长度 && 宽高比> 2，取较小值等于设定长度，较大值等比例压缩
        if (MIN(width, height) >= BOUNDARY) {
            CGFloat MinEdgeRatio = MIN(width, height) / BOUNDARY;
            if (width < height) {
                width = BOUNDARY;
                height = height / MinEdgeRatio;
            } else {
                height = BOUNDARY;
                width = width / MinEdgeRatio;
            }
        }
    }
    return CGSizeMake(width, height);
}

/**
 根据图片Size返回对应图片
 
 @return  图片
 */
- (UIImage *)toSourceImageWithSize:(CGSize)imgSize {
    
    UIGraphicsBeginImageContextWithOptions(imgSize, YES, self.scale);
    
    [self drawInRect:(CGRect){0, 0, imgSize}];
    
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
@end

//
//  UIImage+Compression.m
//  CompressionImg
//
//  Created by Eli on 2019/1/24.
//  Copyright © 2019 Ely. All rights reserved.
//

#import "UIImage+Compression.h"

static CGFloat const BOUNDARY = 1334;  //图片限定长度值
static CGFloat const MAXQUALITY = 0.8;  //初始最高压缩质量系数
static CGFloat const MINQUALITY = 0.3;  //初始最低压缩质量系数
static CGFloat const SIZE = 300; //图片限定大小，单位KB

@implementation UIImage (Compression)


//返回 压缩后图片
- (UIImage *)compressToImage {
#ifdef DEBUG
    NSData *imageData = UIImageJPEGRepresentation(self, 1);
    NSLog(@"压缩前 ==%f kb",imageData.length/1024.0);
#endif
    CGSize size = [self imageSize];
    UIImage *reImage = [self toSourceImageWithSize:MAX(size.width,size.height)];
    NSData * data = [self cycleCompressImage:reImage];
    UIImage * compressImg = [UIImage imageWithData:data];
    return compressImg;
}
//返回 压缩后大小
- (NSData *)returnCompressSize{
    CGSize size = [self imageSize];
    UIImage *reImage = [self toSourceImageWithSize:MAX(size.width,size.height)];
    NSData * data = [self cycleCompressImage:reImage];
    return data;
}

/**
 异步循环压缩图片直到限定大小
 或者 达到最低压缩系数
 返回图片JPG二进制
 */
- (NSData *)cycleCompressImage:(UIImage *)image {
   
    UIImage * thumImg = [image fixOrientation];
    
    __block NSData *imgData  = UIImageJPEGRepresentation(thumImg, 1);
    if (imgData.length / 1024 <= SIZE) return imgData;
    
    CGFloat max = MAXQUALITY;
    CGFloat min = MINQUALITY;
    
    //指数二分处理，首先计算最小值0.0625
    CGFloat qualityCompress = pow(2, -4);
    imgData = UIImageJPEGRepresentation(image, qualityCompress);
    if (imgData.length / 1024 < SIZE) {
        //二分最大4次，精度可达0.0625， 通过对比，4次基本满足条件
        for (int i = 0; i < 4; ++i) {
            qualityCompress = (max + min) / 2;
            imgData = UIImageJPEGRepresentation(image, qualityCompress);
            //容错区间范围0.9～1.0
            if (imgData.length < SIZE * 0.9) {
                min = qualityCompress;
            } else if (imgData.length > SIZE) {
                max = qualityCompress;
            } else {
                break;
            }
#ifdef DEBUG
             NSLog(@"循环压缩 ==%f kb 压缩系数为%.2f",imgData.length/1024.0,qualityCompress);
#endif
        }
    }
#ifdef DEBUG
    NSLog(@"压缩后 ==%f kb 压缩系数为%.2f",imgData.length/1024.0,qualityCompress);
#endif
    return imgData;
    
}

/**
 根据图片尺寸和对应策略得到图片Size
 
 @return  图片Size
 */
- (CGSize)imageSize {
    
    CGFloat width = self.size.width;
    CGFloat height = self.size.height;
    
    // 宽高均<= 设定长度，图片尺寸大小保持不变
    if (width <= BOUNDARY && height <= BOUNDARY) {
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
    }else {
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
 根据图片Size返回对应图片，为降低CPU消耗使用Image I/O
 
 @return  图片
 */
- (UIImage *)toSourceImageWithSize:(NSUInteger)imgSize {
    NSData * data = UIImageJPEGRepresentation(self, 1);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
    
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef) @{
                                                                                                      (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                                                                      (NSString *)kCGImageSourceThumbnailMaxPixelSize : @(imgSize),
                                                                                                      (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                                                                      });
    CFRelease(source);
    CFRelease(provider);
    
    if (!imageRef) {
        return nil;
    }
    
    UIImage *toReturn = [UIImage imageWithCGImage:imageRef];
    
    CFRelease(imageRef);
    
    return toReturn;
}

// 返回正常方向图片
- (UIImage *)fixOrientation {
    
    // 判断图片方向是否正确，正确则返回
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    // 计算适当的变换使图像垂直
    // 两步:如果是左/右/向下旋转，如果是镜像则翻转
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // 将底层的CGImage绘制到一个新的Context中，并转换为正确方向
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // 创建一个新的UIImage
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
@end

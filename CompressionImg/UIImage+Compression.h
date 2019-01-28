//
//  UIImage+Compression.h
//  CompressionImg
//
//  Created by Eli on 2019/1/24.
//  Copyright © 2019 Ely. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Compression)

- (UIImage *)compressToImage;
- (NSData *)returnCompressSize;
@end

NS_ASSUME_NONNULL_END

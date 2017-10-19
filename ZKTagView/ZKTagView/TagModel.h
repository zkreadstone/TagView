//
//  TagModel.h
//  ZKTagView
//
//  Created by LSH on 2017/10/18.
//  Copyright © 2017年 ZhangKang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


// 定义一个结构体
typedef struct {
    int xRate;
    CGFloat yRate;
    CGFloat wRate;
}XYRate;

@protocol  TagModel

@end
@interface TagModel : NSObject

/**
 *标签文本
 */
@property (nonatomic,strong) NSString *text;

///标签线的xy系数
@property (nonatomic,assign) XYRate xyRate;

///文本大小
@property (nonatomic,assign) CGSize textSize;
///文本位置
@property (nonatomic,assign) CGPoint textPosition;

@end

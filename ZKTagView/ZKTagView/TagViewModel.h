//
//  TagViewModel.h
//  ZKTagView
//
//  Created by LSH on 2017/10/18.
//  Copyright © 2017年 ZhangKang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TagModel.h"


//样式
typedef NS_ENUM(NSUInteger, TagViewStyle) {
    TagViewType_E_Right = 0,
    TagViewType_E_Left,
    TagViewType_K_Right,
    TagViewType_K_Left
};

@interface TagViewModel : NSObject

//文本数组
@property (nonatomic, strong) NSMutableArray<TagModel *> *tagModels;
//标签相对于父视图坐标系中的相对坐标，例如（0.5, 0.5）即代表位于父视图中心
@property (nonatomic, assign) CGPoint coordinate;
//样式
@property (nonatomic, assign) TagViewStyle style;
//顺序标志
@property (nonatomic, assign) NSUInteger index;

@property (nonatomic,assign) CGFloat midSepLong;///除文本外的水平宽度

- (instancetype)initWithArray:(NSMutableArray<TagModel *> *)tagModels coordinate:(CGPoint)coordinate;
- (void)styleToggle;

@end

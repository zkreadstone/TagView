//
//  TagViewModel.m
//  ZKTagView
//
//  Created by LSH on 2017/10/18.
//  Copyright © 2017年 ZhangKang. All rights reserved.
//

#import "TagViewModel.h"

#define kSepSpace 18.0f

@interface TagViewModel()


@end

@implementation TagViewModel

- (instancetype)initWithArray:(NSMutableArray<TagModel *> *)tagModels coordinate:(CGPoint)coordinate
{
    if(self=[self init]){
        if(!tagModels){
            tagModels = [NSMutableArray<TagModel *> array];
        }
        self.tagModels = tagModels.mutableCopy;
        self.coordinate = coordinate;
        self.style = TagViewType_K_Left;
    }
    return self;
}


-(void)setStyle:(TagViewStyle)style
{
    _style = style;
    [self uploadXYRateAndH];
}

#pragma mark - 切换当前style
- (void)styleToggle
{
    //切换
    _style = (_style+1)%4;
    
    [self uploadXYRateAndH];
}

- (void)uploadXYRateAndH
{
    if (self.tagModels.count == 0) {return;}
    //朝向direction
    BOOL isRight = self.style%2;
    ///设置风格的时候更新TagModel的xyRate
    NSInteger count = self.tagModels.count;
    for (int i = 0; i < self.tagModels.count; i ++) {
        TagModel *model = self.tagModels[i];
        ///xReate、yRate、wRate
        XYRate rate =  {isRight ? 1:-1,i-(count-1)*0.5,self.style < 2 ? 0 : 1};
        model.xyRate = rate;
    }
}

-(void)setTagModels:(NSMutableArray<TagModel *> *)tagModels
{
    if (_tagModels == tagModels) {
        return;
    }
    _tagModels = tagModels;
    [self uploadXYRateAndH];
}

@end

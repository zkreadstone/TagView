//
//  ZKTagView.h
//  ZKTagView
//
//  Created by LSH on 2017/10/18.
//  Copyright © 2017年 ZhangKang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TagViewModel.h"

@interface ZKTagView : UIView

///各种手势回调
@property (nonatomic,copy) void(^textDidTapBlock)(ZKTagView *);
@property (nonatomic,copy) void(^centerDidTapBlock)(ZKTagView *);
@property (nonatomic,copy) void(^longPressBlock)(ZKTagView *);

///标签Model
@property (nonatomic,strong) TagViewModel *tagViewModel;


- (instancetype)initWithTagModel:(TagViewModel *)viewModel;


@property (nonatomic, assign) BOOL viewHidden;


@end

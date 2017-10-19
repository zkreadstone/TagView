//
//  ViewController.m
//  ZKTagView
//
//  Created by LSH on 2017/10/18.
//  Copyright © 2017年 ZhangKang. All rights reserved.
//

#import "ViewController.h"
#import "ZKTagView.h"
@interface ViewController ()

@property (nonatomic,strong) UIImageView *imgView;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor cyanColor];
    [self imgView];
    TagModel *model0 = [[TagModel alloc]init];
    model0.text = @"耐克Air";
    TagModel *model1 = [[TagModel alloc]init];
    model1.text = @"1200RMB";
    TagModel *model2 = [[TagModel alloc]init];
    model2.text = @"北京市朝阳区";
    
    TagViewModel *viewModel = [[TagViewModel alloc]initWithArray:[NSMutableArray arrayWithArray:@[model0,model1,model2]] coordinate:CGPointMake(0.5,0.5)];
    
    ZKTagView *tagView = [[ZKTagView alloc]initWithTagModel:viewModel];
    tagView.longPressBlock = ^(ZKTagView *tagView) {
        [tagView removeFromSuperview];
    };
    
    tagView.textDidTapBlock = ^(ZKTagView *tagView) {
        TagViewModel *model = tagView.tagViewModel;
        NSLog(@"------%@",model.tagModels);
        model.tagModels = [NSMutableArray arrayWithArray:@[model2]];
        NSLog(@"---更改过后---%@",model.tagModels);
        [tagView setTagViewModel:model];
    };
    [self.imgView addSubview:tagView];
    
}


-(UIImageView *)imgView
{
    if (!_imgView) {
        _imgView = [[UIImageView alloc]initWithFrame:self.view.bounds];
        _imgView.backgroundColor = [UIColor redColor];
        _imgView.image = [UIImage imageNamed:@"cloud.png"];
        _imgView.userInteractionEnabled = YES;
        [self.view addSubview:_imgView];
    }
    return _imgView;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

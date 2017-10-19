//
//  ZKTagView.m
//  ZKTagView
//
//  Created by LSH on 2017/10/18.
//  Copyright © 2017年 ZhangKang. All rights reserved.
//

#import "ZKTagView.h"


CGFloat const kUnderLineLayerRadius = 25.0f;//底线从圆心伸延的长度

NSString *const kAnimationKeyShow = @"show";
NSString *const kAnimationKeyHide = @"hide";


#define kCenterWhitePointRadius  2.0f
#define kShadowPointRadius 4.0f

#define kCenterPointRadius  20.0f
#define kTextFontSize 13.0f
#define kSepSpace 18.0f
#define kLineH 35.0f
#define kTextLRSpace 10.0f //与底线的左右端的距离
#define kTextBottomSpace 0.0f ///与底线的竖直距离

@interface ZKTagView()

//拖动时的起始位置
@property (nonatomic, assign) CGPoint startPosition;

//三段文字的TextLayer
@property (nonatomic, strong) NSMutableArray<CATextLayer *> *textLayers;

//三段文字下的横线
@property (nonatomic, strong) NSMutableArray<CAShapeLayer *> *underLineLayers;

//中心点
@property (nonatomic, strong) CAShapeLayer *centerPointShapeLayer;
@property (nonatomic, strong) CAShapeLayer *shadowPointShapeLayer;

@property (nonatomic, assign) BOOL needsUpdateCenter;
@property (nonatomic, assign) BOOL animating;

@end
@implementation ZKTagView


- (instancetype)initWithTagModel:(TagViewModel *)viewModel
{
    if(self=[super initWithFrame:CGRectMake(0, 0, 100, 50)]){
        _tagViewModel = viewModel;
        _textLayers = [NSMutableArray array];
        _underLineLayers = [NSMutableArray array];
        _needsUpdateCenter = YES;
        _viewHidden = YES;
        //背景颜色
        self.layer.backgroundColor = [UIColor clearColor].CGColor;
        
        [self setupSelfFrame];
        [self setupGesture];
        [self setupLayers];
        [self showWithAnimate:YES];
    }
    
    return self;
}


///更新TagViewModel时重新绘制
-(void)setTagViewModel:(TagViewModel *)tagViewModel
{
    //    if (_tagViewModel == tagViewModel && _tagViewModel.tagModels == tagViewModel.tagModels) {
    //        return;
    //    }
    _tagViewModel = tagViewModel;
    _viewHidden = YES;
    [self setupSelfFrame];
    [self setupLayers];
    [self showWithAnimate:YES];
}


- (void)setViewHidden:(BOOL)viewHidden
{
    if(_viewHidden == viewHidden){
        return;
    }
    if(_viewHidden){
        [self showWithAnimate:YES];
    }else{
        [self hideWithAnimate:YES];
    }
    
}


#pragma mark - setup
//计算自身大小
- (void)setupSelfFrame
{
    //获取最宽的文本的Size
    CGSize maxWidthSize = [self getMaxTextSize];
    //控件的宽度 = 2*(斜线的半径+最大文本宽度+文本左边距+文本右边距+控件内边距)
    //控件的高度 = 行高*tagModelCount
    CGFloat width = ((self.tagViewModel.style < 2 ? 0 : kSepSpace) + kTextLRSpace + maxWidthSize.width)*2;
    CGFloat height = kLineH *self.tagViewModel.tagModels.count;
    self.bounds = CGRectMake(0, 0, width, height);
}


//添加手势
- (void)setupGesture
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    
    
    [self addGestureRecognizer:tapGesture];
    [self addGestureRecognizer:longPressGesture];
    [self addGestureRecognizer:panGesture];
}




//创建子图层
- (void)setupLayers
{
    //初始化
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [_textLayers removeAllObjects];
    [_underLineLayers removeAllObjects];
    _centerPointShapeLayer = nil;
    _shadowPointShapeLayer = nil;
    
    if(!_tagViewModel){
        return;
    }
    
    //生成字layers
    for (TagModel *tag in _tagViewModel.tagModels) {
        //文本
        CATextLayer *textLater = [self setupTextLayerWithTagModel:tag];
     
        [_textLayers addObject:textLater];
        
        //文本宽高
        tag.textSize = [textLater preferredFrameSize];
        textLater.bounds = CGRectMake(0, 0, tag.textSize.width, tag.textSize.height);
        
        //下划线
        CAShapeLayer *underLineLayer = [self setupUnderlineShapeLayerWithTagModel:tag];
        
        [_underLineLayers addObject:underLineLayer];
        
        //最后设置文本位置
        textLater.position = tag.textPosition;
        
        
        [self.layer addSublayer:textLater];
        [self.layer addSublayer:underLineLayer];
    }
    
    
    
    //原点阴影
    _shadowPointShapeLayer = [self setupCenterPointShapeLayerWithRadius:kShadowPointRadius];
    _shadowPointShapeLayer.backgroundColor = [UIColor clearColor].CGColor;
    [self.layer addSublayer:_shadowPointShapeLayer];
    //原点
    _centerPointShapeLayer = [self setupCenterPointShapeLayerWithRadius:kCenterWhitePointRadius];
    [self.layer addSublayer:_centerPointShapeLayer];
    
}

#pragma mark - setupLayers
//创建原点
- (CAShapeLayer *)setupCenterPointShapeLayerWithRadius:(CGFloat)pointRadious
{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, pointRadious*2, pointRadious*2)].CGPath;
    shapeLayer.fillColor = [UIColor whiteColor].CGColor;
    shapeLayer.bounds = CGRectMake(0, 0, pointRadious*2, pointRadious*2);
    shapeLayer.position = CGPointMake(self.layer.bounds.size.width/2, self.layer.bounds.size.height/2);
    shapeLayer.opacity = 0;
    
    return shapeLayer;
}


//创建文本图层
- (CATextLayer *)setupTextLayerWithTagModel:(TagModel *)model
{
    if(!model){return nil;}
    if(model.text.length == 0){return nil;}
    
    CATextLayer *textLayer = [CATextLayer layer];
    
    UIFont *font = [UIFont systemFontOfSize:kTextFontSize];
    CFStringRef fontName = (__bridge CFStringRef)(font.fontName);
    CGFontRef fontRef = CGFontCreateWithFontName(fontName);
    
    textLayer.font = fontRef;
    textLayer.fontSize = font.pointSize;
    textLayer.contentsScale = [UIScreen mainScreen].scale;
    textLayer.foregroundColor = [UIColor whiteColor].CGColor;
    textLayer.opacity = 0;

    //张康添加文本阴影
    textLayer.shadowOpacity = 1.0f;
    textLayer.shadowColor = [UIColor blackColor].CGColor;
    textLayer.shadowOffset = CGSizeMake(1, 1);
    textLayer.string = model.text;
    
    return textLayer;
}

//横线
- (CAShapeLayer *)setupUnderlineShapeLayerWithTagModel:(TagModel *)model
{
    CGPoint centerPoint = CGPointMake(self.layer.bounds.size.width/2, self.layer.bounds.size.height/2);
    CGPoint startPoint = centerPoint;
    
    CAShapeLayer *lineLayer = [CAShapeLayer layer];
    lineLayer.strokeColor = [UIColor whiteColor].CGColor;
    lineLayer.fillColor = [UIColor clearColor].CGColor;
    
    
    //计算路径
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:centerPoint];
    
    
    //画出第一段斜线
    CGPoint midPoint = CGPointMake(startPoint.x + model.xyRate.xRate*model.xyRate.wRate*kSepSpace,startPoint.y+model.xyRate.yRate*kLineH);
    [path addLineToPoint:midPoint];
    
    ///画出最后的水平线
    CGPoint endPoint = CGPointMake(midPoint.x + model.xyRate.xRate*(model.textSize.width + kTextLRSpace), midPoint.y);
    [path addLineToPoint:endPoint];
    

    lineLayer.path = path.CGPath;
    
//    lineLayer.shadowPath = path.CGPath;
    lineLayer.strokeEnd = 0;
    ///设置线的阴影，避免在纯白底色上看不清楚
    lineLayer.shadowOffset = CGSizeMake(1, 1);
    lineLayer.shadowOpacity = 1.0f;
    lineLayer.shadowColor = [UIColor blackColor].CGColor;
    
    //计算文本位置
    CGFloat textPositionX = (midPoint.x + endPoint.x)/2;
    CGFloat textPositionY = endPoint.y-kTextBottomSpace-model.textSize.height/2;
    model.textPosition = CGPointMake(textPositionX, textPositionY);
    
    //动画 CABasicAnimation strokeEnd
    
    return lineLayer;
}


- (void)showWithAnimate:(BOOL)animate
{
    if(!_viewHidden){
        return;
    }
//    _animating = YES;
    CGFloat duration = .3f;
    [self animateWithDuration:duration*3 AnimationBlock:^{
        NSTimeInterval currentTime = CACurrentMediaTime();
        //原点
        CABasicAnimation *animation = [CABasicAnimation animation];
        animation.beginTime = 0;
        animation.duration = duration;
        animation.keyPath = @"opacity";
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        animation.fromValue = @0;
        animation.toValue = @1;
        [_centerPointShapeLayer addAnimation:animation forKey:kAnimationKeyShow];
        animation.toValue = @0.3;
        [_shadowPointShapeLayer addAnimation:animation forKey:kAnimationKeyShow];
        
        
        
        //下划线
        CABasicAnimation *lineAnimation = [CABasicAnimation animation];
        lineAnimation.beginTime = currentTime+duration;
        lineAnimation.duration = duration;
        lineAnimation.keyPath = @"strokeEnd";
        lineAnimation.removedOnCompletion = NO;
        lineAnimation.fillMode = kCAFillModeForwards;
        lineAnimation.fromValue = @0;
        lineAnimation.toValue = @1;
        
        for(CAShapeLayer *shapeLayer in _underLineLayers){
            [shapeLayer addAnimation:lineAnimation forKey:kAnimationKeyShow];
        }
        
        
        //文字
        CABasicAnimation *textAnimation = [CABasicAnimation animation];
        textAnimation.beginTime = currentTime+duration*2;
        textAnimation.duration = duration;
        textAnimation.keyPath = @"opacity";
        textAnimation.removedOnCompletion = NO;
        textAnimation.fillMode = kCAFillModeForwards;
        textAnimation.fromValue = @0;
        textAnimation.toValue = @1;
        
        for(CATextLayer *textLayer in _textLayers){
            [textLayer addAnimation:textAnimation forKey:kAnimationKeyShow];
        }
    } completeBlock:^{
        _viewHidden = NO;
    }];
    
    
    
}

- (void)hideWithAnimate:(BOOL)animate
{
    if(_viewHidden){
        return;
    }
    CGFloat duration = .3f;
    [self animateWithDuration:duration*3 AnimationBlock:^{
        NSTimeInterval currentTime = CACurrentMediaTime();
        //原点
        CABasicAnimation *animation = [CABasicAnimation animation];
        animation.beginTime = currentTime+duration*2;
        animation.duration = duration;
        animation.keyPath = @"opacity";
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeBackwards;
        animation.fromValue = @1;
        animation.toValue = @0;
        [_centerPointShapeLayer addAnimation:animation forKey:kAnimationKeyShow];
        animation.fromValue = @0.3;
        [_shadowPointShapeLayer addAnimation:animation forKey:kAnimationKeyShow];
        
        
        
        //下划线
        CABasicAnimation *lineAnimation = [CABasicAnimation animation];
        lineAnimation.beginTime = currentTime+duration;
        lineAnimation.duration = duration;
        lineAnimation.keyPath = @"strokeEnd";
        lineAnimation.removedOnCompletion = NO;
        lineAnimation.fillMode = kCAFillModeBoth;
        lineAnimation.fromValue = @1;
        lineAnimation.toValue = @0;
        
        for(CAShapeLayer *shapeLayer in _underLineLayers){
            [shapeLayer addAnimation:lineAnimation forKey:kAnimationKeyShow];
        }
        
        
        //文字
        CABasicAnimation *textAnimation = [CABasicAnimation animation];
        textAnimation.beginTime = 0;
        textAnimation.duration = duration;
        textAnimation.keyPath = @"opacity";
        textAnimation.removedOnCompletion = NO;
        textAnimation.fillMode = kCAFillModeBoth;
        textAnimation.fromValue = @1;
        textAnimation.toValue = @0;
        
        for(CATextLayer *textLayer in _textLayers){
            [textLayer addAnimation:textAnimation forKey:kAnimationKeyShow];
        }
    } completeBlock:^{
        _viewHidden = YES;
    }];
    
    
}
///动画
- (void)animateWithDuration:(CGFloat)duration
             AnimationBlock:(void(^)(void))doBlock
              completeBlock:(void(^)(void))completeBlock
{
    [CATransaction begin];
    [CATransaction setDisableActions:NO];
    [CATransaction setAnimationDuration:duration];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [CATransaction setCompletionBlock:^{
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        if(completeBlock){
            completeBlock();
        }
        [CATransaction commit];
    }];
    if(doBlock){
        doBlock();
    }
    [CATransaction commit];
}


#pragma mark - 手势&点击判断
//点击手势 --- 1.点击文本编辑 2.点击中心点更换风格
- (void)didTap:(UITapGestureRecognizer *)recognizer
{
    //动画或隐藏后不响应点击事件
    if(_viewHidden){
        return;
    }
    
    CGPoint position = [recognizer locationInView:self];
    if([self textLayerContainsPoint:position inset:CGPointMake(0, 0)]){
        //点击文本
        if(_textDidTapBlock){
            _textDidTapBlock(self);
            return;
        }
    }
    
    if([self centerContainsPoint:position inset:0]){
           [self hideWithAnimate:YES];
        [_tagViewModel styleToggle];
        //        重绘自己
        [self setupLayers];
        _viewHidden = YES;
        [self showWithAnimate:YES];
//        if (!self.viewHidden) {
////            [self hideWithAnimate:YES];
//
//        }
//        if (_viewHidden) {
//            //切换样式
//            [_tagViewModel styleToggle];
//            //        重绘自己
//            [self setupLayers];
//            [self showWithAnimate:YES];
//        }


        if(_centerDidTapBlock){
            _centerDidTapBlock(self);
            return;
        }
    }
    
}



//长按手势
- (void)longPress:(UILongPressGestureRecognizer *)recognizer
{
    //动画或隐藏后不响应点击事件
    if( _viewHidden){
        return;
    }
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:{
            CGPoint position = [recognizer locationInView:self];
            if([self centerContainsPoint:position inset:0] || [self textLayerContainsPoint:position inset:CGPointMake(-5, -5)]){
                NSLog(@"long tap on text or center");
                if(_longPressBlock){
                    _longPressBlock(self);
                    return;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{
            break;
        }
        case UIGestureRecognizerStateEnded:{
            break;
        }
        default:
            break;
    }
}

///拖动手势
- (void)didPan:(UIPanGestureRecognizer *)recognizer
{
    //动画或隐藏后不响应点击事件
    if(_viewHidden){
        return;
    }
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:{
            CGPoint position = [recognizer locationInView:self];
            //滑动，需要加上10个点预判
            if(![self centerContainsPoint:position inset:10.f] && ![self textLayerContainsPoint:position inset:CGPointMake(-15, -15)]){
                _startPosition = CGPointZero;
                return;
            }
            //保存初始点击位置
            _startPosition = [recognizer locationInView:self.superview];
            break;
        }
        case UIGestureRecognizerStateChanged:{
            if(CGPointEqualToPoint(_startPosition, CGPointZero)){
                return;
            }
            //计算偏移量并更新自己的center
            CGPoint position = [recognizer locationInView:self.superview];
            
            CGFloat moveX = position.x - _startPosition.x;
            CGFloat moveY = position.y - _startPosition.y;
            
            CGFloat origX = self.superview.bounds.size.width * _tagViewModel.coordinate.x;
            CGFloat origY = self.superview.bounds.size.height * _tagViewModel.coordinate.y;
            
            CGFloat currentX = MIN(MAX(origX+moveX, 0), self.superview.bounds.size.width);
            CGFloat currentY = MIN(MAX(origY+moveY, 0), self.superview.bounds.size.height);
            
            
            
            self.center = CGPointMake(currentX, currentY);
            
            break;
        }
        case UIGestureRecognizerStateEnded:{
            if(CGPointEqualToPoint(_startPosition, CGPointZero)){
                return;
            }
            //最后保存中心点的相对坐标
            CGFloat x,y;
            x = self.center.x/self.superview.bounds.size.width;
            y = self.center.y/self.superview.bounds.size.height;
            
            
            CGPoint coordinate = CGPointMake(x, y);
            _tagViewModel.coordinate = coordinate;
            NSLog(@"%@", NSStringFromCGPoint(coordinate));
            
            break;
        }
        default:
            break;
    }
    
}



//点position是否在某一个textLayer内
- (BOOL)textLayerContainsPoint:(CGPoint)point inset:(CGPoint)insetXY
{
    BOOL longPressOnText = NO;
    for(CATextLayer *textLayer in _textLayers){
        if(textLayer.presentationLayer.opacity == 0){
            continue;
        }
        CGRect textRect = CGRectInset(textLayer.frame, insetXY.x, insetXY.y);
        if(CGRectContainsPoint(textRect, point)){
            longPressOnText = YES;
            break;
        }
    }
    return longPressOnText;
    
}

//点position是否在半径为kUnderLineLayerRadius的中心圆内
- (BOOL)centerContainsPoint:(CGPoint)position inset:(CGFloat)insetRadius
{
    CGPoint centerPosition = CGPointMake(self.layer.bounds.size.width/2, self.layer.bounds.size.height/2);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:centerPosition radius:kCenterPointRadius+insetRadius startAngle:0 endAngle:M_PI*2 clockwise:YES];
    return [path containsPoint:position];
}


//获取宽度最长的textSize
- (CGSize)getMaxTextSize
{
    CGSize maxWidthSize = CGSizeZero;
    for(TagModel *tagModel in _tagViewModel.tagModels){
        UIFont *font = [UIFont systemFontOfSize:kTextFontSize];
        CGSize textSize = [tagModel.text sizeWithAttributes:@{NSFontAttributeName:font}];
        if(textSize.width > maxWidthSize.width){
            maxWidthSize = textSize;
        }
    }
    return maxWidthSize;
}


- (void)layoutSubviews
{
    //是否需要更新center
    if(_needsUpdateCenter){
        CGFloat x = self.superview.bounds.size.width * _tagViewModel.coordinate.x;
        CGFloat y = self.superview.bounds.size.height * _tagViewModel.coordinate.y;
        self.center = CGPointMake(x, y);
        _needsUpdateCenter = NO;
    }
}

@end

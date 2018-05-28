//
//  GooView.m
//  GooDemo
//
//  Created by yejunyou on 2018/5/28.
//  Copyright © 2018年 futureversion. All rights reserved.
//

#import "GooView.h"

// 最大圆心距离
#define kMaxDistance 80
#define YYLog(format,...) NSLog((@"%s[Line%d]: " format),__FUNCTION__,__LINE__,## __VA_ARGS__,nil);

@interface GooView()
@property (nonatomic, strong) UIView  *smallCircleView;
@property (nonatomic, assign) CGFloat oriSmallRadius;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@end

@implementation GooView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setUp];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setUp];
}

#pragma mark - 初始化
- (void)setUp
{
    CGFloat w = self.bounds.size.width;
    
    // 记录小圆最初始半径
    _oriSmallRadius = w / 2;
    
    // 设置小圆位置和尺寸
    self.smallCircleView.center = self.center;
    self.smallCircleView.bounds = self.bounds;
    self.smallCircleView.layer.cornerRadius = w / 2;
    
    // 基本设置
    NSString *title = [NSString stringWithFormat:@"%zd",arc4random_uniform(99)];
    self.layer.cornerRadius = w / 2;
    [self setTitle:title forState:UIControlStateNormal];
    self.backgroundColor = [UIColor redColor];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.titleLabel.font = [UIFont systemFontOfSize:12];
    
    // 添加手势
    [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)]];
}


- (void)pan:(UIPanGestureRecognizer *)pan
{
#pragma mark - 移动控件位置
    // 获取手指偏移量
    CGPoint transP = [pan translationInView:self];
    
    // 修改center
    CGPoint center = self.center;
    center.x += transP.x;
    center.y += transP.y;
    self.center = center;
    
    // 复位
    [pan setTranslation:CGPointZero inView:self];
    
#pragma mark - 设置小圆半径
    // 显示后面圆，后面圆的半径，随着两个圆心的距离不断增加而减小。
    // 计算圆心距离
    CGFloat d = [self circleCenterDistanceWithBigCircleCenter:self.center smallCircleCenter:self.smallCircleView.center];
    
    // 计算小圆的半径
    CGFloat smallRadius = _oriSmallRadius - d / 10;
    
    // 设置小圆的尺寸
    self.smallCircleView.bounds = CGRectMake(0, 0, smallRadius * 2, smallRadius * 2);
    self.smallCircleView.layer.cornerRadius = smallRadius;
    
#pragma mark - 描述不规则矩形
    //    // 绘制不规则矩形，不能通过绘图，因为绘图只能在当前控件上画，超出部分不会显示。
    //
    //    // 两圆产生距离才需要绘制
    //    if (d) {
    //
    //
    //    }
    
    // 当圆心距离大于最大圆心距离
    if (d > kMaxDistance) { // 可以拖出来
        // 隐藏小圆
        self.smallCircleView.hidden = YES;
        
        // 移除不规则的矩形
        [self.shapeLayer removeFromSuperlayer];
        self.shapeLayer = nil;
    }
    else if(d > 0 && self.smallCircleView.hidden == NO){
        // 有圆心距离，并且圆心距离不大，才需要展示
        // 展示不规则矩形，通过不规则矩形路径生成一个图层
        self.shapeLayer.path = [self pathWithBigCirCleView:self smallCirCleView:self.smallCircleView].CGPath;
    }
    
#pragma mark - 手指抬起的时候，还原
    if (pan.state == UIGestureRecognizerStateEnded) {
        // 当圆心距离大于最大圆心距离
        if (d > kMaxDistance) {
            // 展示gif动画
            [self showGIF];
        }
        else{
            // 回到原位
            [self backToOriginalPosition];
        }
    }
}

- (void)showGIF{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    NSMutableArray *imageArr = [NSMutableArray array];
    for (int i = 1; i < 9; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d",i]];
        [imageArr addObject:image];
    }
    imageView.animationImages = imageArr;
    imageView.animationRepeatCount = 1;
    imageView.animationDuration = 0.5;
    [imageView startAnimating];
    
    [self addSubview:imageView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeFromSuperview];
    });
}

- (void)backToOriginalPosition{
    // 移除不规则矩形
    [self.shapeLayer removeFromSuperlayer];
    self.shapeLayer = nil;
    
    // 还原位置
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.2 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^{
        // 设置大圆中心点位置
        self.center = self.smallCircleView.center;
        
    } completion:^(BOOL finished) {
        // 显示小圆
        self.smallCircleView.hidden = NO;
    }];
}

// 计算两个圆心之间的距离
- (CGFloat)circleCenterDistanceWithBigCircleCenter:(CGPoint)bigCircleCenter smallCircleCenter:(CGPoint)smallCircleCenter
{
    CGFloat offsetX = bigCircleCenter.x - smallCircleCenter.x;
    CGFloat offsetY = bigCircleCenter.y - smallCircleCenter.y;
    
    return  sqrt(offsetX * offsetX + offsetY * offsetY);
}

// 描述两圆之间一条矩形路径
- (UIBezierPath *)pathWithBigCirCleView:(UIView *)bigCirCleView  smallCirCleView:(UIView *)smallCirCleView
{
    CGPoint bigCenter = bigCirCleView.center;
    CGFloat x2 = bigCenter.x;
    CGFloat y2 = bigCenter.y;
    CGFloat r2 = bigCirCleView.bounds.size.width / 2;
    
    CGPoint smallCenter = smallCirCleView.center;
    CGFloat x1 = smallCenter.x;
    CGFloat y1 = smallCenter.y;
    CGFloat r1 = smallCirCleView.bounds.size.width / 2;
    
    // 获取圆心距离
    CGFloat d = [self circleCenterDistanceWithBigCircleCenter:bigCenter smallCircleCenter:smallCenter];
    CGFloat sinθ = (x2 - x1) / d;
    CGFloat cosθ = (y2 - y1) / d;
    
    // 坐标系基于父控件
    CGPoint pointA = CGPointMake(x1 - r1 * cosθ , y1 + r1 * sinθ);
    CGPoint pointB = CGPointMake(x1 + r1 * cosθ , y1 - r1 * sinθ);
    CGPoint pointC = CGPointMake(x2 + r2 * cosθ , y2 - r2 * sinθ);
    CGPoint pointD = CGPointMake(x2 - r2 * cosθ , y2 + r2 * sinθ);
    CGPoint pointO = CGPointMake(pointA.x + d / 2 * sinθ , pointA.y + d / 2 * cosθ);
    CGPoint pointP =  CGPointMake(pointB.x + d / 2 * sinθ , pointB.y + d / 2 * cosθ);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    // A
    [path moveToPoint:pointA];
    
    // AB
    [path addLineToPoint:pointB];
    
    // 绘制BC曲线
    [path addQuadCurveToPoint:pointC controlPoint:pointP];
    
    // CD
    [path addLineToPoint:pointD];
    
    // 绘制DA曲线
    [path addQuadCurveToPoint:pointA controlPoint:pointO];
    
    return path;
}

#pragma mark - setting && getting
- (CAShapeLayer *)shapeLayer
{
    if (_shapeLayer == nil) {
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.fillColor = self.backgroundColor.CGColor;
        
        // 展示不规则矩形，通过不规则矩形路径生成一个图层
        [self.superview.layer insertSublayer:_shapeLayer below:self.layer];
    }
    return _shapeLayer;
}

- (UIView *)smallCircleView
{
    if (_smallCircleView == nil) {
        _smallCircleView = [[UIView alloc] init];
        _smallCircleView.backgroundColor = self.backgroundColor;
        
        // 小圆添加按钮的父控件上
        [self.superview insertSubview:_smallCircleView belowSubview:self];
    }
    return _smallCircleView;
}

@end


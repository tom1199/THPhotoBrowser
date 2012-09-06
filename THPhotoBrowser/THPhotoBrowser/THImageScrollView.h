//
//  THImageScrollView.h
//  PhotoScrollViewDemo
//
//  Created by Tang Han on 4/9/12.
//  Copyright (c) 2012 Tang Han. All rights reserved.
//

#import <UIKit/UIKit.h>
@class THImageScrollView;
@protocol THImageScrollViewDelegate <NSObject>
- (void)imageDidLoaded:(THImageScrollView *)scrollView;
@end

@interface THImageScrollView : UIScrollView <UIScrollViewDelegate>

@property (assign) id<THImageScrollViewDelegate>loadCompletionDelegate;
@property (assign) NSUInteger index;
@property (nonatomic,strong) UITapGestureRecognizer *doubleTapGuestureRecognizer;

- (void)displayImage:(UIImage *)image;
- (void)displayImageForURL:(NSURL *)url;
- (void)setMaxMinZoomScalesForCurrentBounds;

- (CGPoint)pointToCenterAfterRotation;
- (CGFloat)scaleToRestoreAfterRotation;
- (void)restoreCenterPoint:(CGPoint)oldCenter scale:(CGFloat)oldScale;

- (CGRect)imageViewFrame;

- (CGRect)zoomRectForNewZoomScale:(CGFloat)newScale centerOfTouch:(CGPoint)pointOnTap;
@end

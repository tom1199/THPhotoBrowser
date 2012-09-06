//
//  THImageScrollView.m
//  PhotoScrollViewDemo
//
//  Created by Tang Han on 4/9/12.
//  Copyright (c) 2012 Tang Han. All rights reserved.
//

#import "THImageScrollView.h"

@interface THImageScrollView()
@property (nonatomic,retain)UIImageView *imageView;
@end
@implementation THImageScrollView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
    }
    return self;
}
#pragma mark - 
#pragma mark Setter & Getter
- (UITapGestureRecognizer *)doubleTapGuestureRecognizer {
    if (!_doubleTapGuestureRecognizer) {
        _doubleTapGuestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleDoubleTap:)];
        _doubleTapGuestureRecognizer.numberOfTapsRequired = 2;
    }
    return _doubleTapGuestureRecognizer;
}
#pragma mark -
#pragma mark User Action
- (void)handleDoubleTap:(UITapGestureRecognizer *)rgr {
    THImageScrollView *viewIsTapped = (THImageScrollView *)rgr.view;
    CGPoint center = [rgr locationInView:viewIsTapped];
    
    CGFloat newZoomScale = viewIsTapped.minimumZoomScale;
    if (viewIsTapped.minimumZoomScale == viewIsTapped.maximumZoomScale) {   //stop zoom function if image size is less than scroll view bounds
        return;
    }else if (viewIsTapped.zoomScale < viewIsTapped.maximumZoomScale) {
        newZoomScale = viewIsTapped.maximumZoomScale;
    }
    
    CGRect rectToZoom = [viewIsTapped zoomRectForNewZoomScale:newZoomScale centerOfTouch:center];
    NSLog(@"rect to zoom = %@",NSStringFromCGRect(rectToZoom));
    [self zoomToRect:rectToZoom animated:YES];
}
#pragma mark -
#pragma mark Override layoutSubviews to center content

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // center the image as it becomes smaller than the size of the screen
    
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.imageView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.imageView.frame = frameToCenter;
}
- (CGRect)imageViewFrame {
    return [self.imageView frame];
}
#pragma mark -
#pragma mark Zoom rect calculation for given center of touch
- (CGRect)zoomRectForNewZoomScale:(CGFloat)newScale centerOfTouch:(CGPoint)center {
    //calculate rect to zoom
    NSLog(@"pointOnTap = %@",NSStringFromCGPoint(center));
    CGRect rectToZoom;
    rectToZoom.size.width = self.frame.size.width/newScale;
    rectToZoom.size.height = self.frame.size.height/newScale;
    
    //if center of touch is not respect to imageView's coordinate, we need to convert point to imageView's coordinate
    center = [self.imageView convertPoint:center fromView:self];
    
    rectToZoom.origin.x = center.x  - rectToZoom.size.width/2;
    rectToZoom.origin.y = center.y  - rectToZoom.size.height/2;
    return rectToZoom;
}
#pragma mark -
#pragma mark UIScrollView delegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

#pragma mark -
#pragma mark Configure scrollView to display new image (tiled or not)
- (void)displayImage:(UIImage *)image {
    // clear the previous imageView
    [self.imageView removeFromSuperview];
    self.imageView = nil;
    
    // reset our zoomScale to 1.0 before doing any further calculations
    self.zoomScale = 1.0;
    
    // make a new UIImageView for the new image
    self.imageView = [[UIImageView alloc]initWithImage:image];
    self.imageView.userInteractionEnabled = YES;
    [self addSubview:self.imageView];
    
    self.contentSize = [image size];
    [self setMaxMinZoomScalesForCurrentBounds];
    self.zoomScale = self.minimumZoomScale;
    
    [self addGestureRecognizer:self.doubleTapGuestureRecognizer];
    
    [self.loadCompletionDelegate imageDidLoaded:self];
}
- (void)displayImageForURL:(NSURL *)url {
    //clear current image if there is one. (DON'T REUSE IMAGE VIEW!!! WEIRD THING WILL HAPPEN WHEN AUTO LAYOUT)
    [self.imageView removeFromSuperview];
    self.imageView = nil;
    
    //set zoom scale to default zoom scale
    [self setZoomScale:1.0 animated:NO];
    
    //create image view and load image asynchronizlly
    dispatch_queue_t image_download_queue = dispatch_queue_create("image downloader", NULL);
    dispatch_async(image_download_queue, ^{
        NSData *imageData = [[NSData alloc]initWithContentsOfURL:url];
        UIImage *image = [[UIImage alloc]initWithData:imageData];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView = [[UIImageView alloc]initWithImage:image];
            self.imageView.userInteractionEnabled = YES;
            [self addSubview:self.imageView];
            
            self.contentSize = [image size];
            [self setMaxMinZoomScalesForCurrentBounds];
            self.zoomScale = self.minimumZoomScale;
            
            //add guesture recognizer only if image is succesfully loaded
            [self addGestureRecognizer:self.doubleTapGuestureRecognizer];
            
            [self.loadCompletionDelegate imageDidLoaded:self];
        });
    });
    dispatch_release(image_download_queue);
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = self.imageView.bounds.size;
    
    // calculate min/max zoomscale
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
    // maximum zoom scale to 0.5.
    CGFloat maxScale = 1.0 / [[UIScreen mainScreen] scale];
    
    // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
    if (minScale > maxScale) {
        minScale = maxScale;
    }
    
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
}

#pragma mark -
#pragma mark Methods called during rotation to preserve the zoomScale and the visible portion of the image

// returns the center point, in image coordinate space, to try to restore after rotation.
- (CGPoint)pointToCenterAfterRotation
{
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    return [self convertPoint:boundsCenter toView:self.imageView];
}

// returns the zoom scale to attempt to restore after rotation.
- (CGFloat)scaleToRestoreAfterRotation
{
    CGFloat contentScale = self.zoomScale;
    
    // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
    // allowable scale when the scale is restored.
    if (contentScale <= self.minimumZoomScale + FLT_EPSILON)
        contentScale = 0;
    
    return contentScale;
}

- (CGPoint)maximumContentOffset
{
    CGSize contentSize = self.contentSize;
    CGSize boundsSize = self.bounds.size;
    return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height);
}

- (CGPoint)minimumContentOffset
{
    return CGPointZero;
}

// Adjusts content offset and scale to try to preserve the old zoomscale and center.
- (void)restoreCenterPoint:(CGPoint)oldCenter scale:(CGFloat)oldScale
{
    // Step 1: restore zoom scale, first making sure it is within the allowable range.
    self.zoomScale = MIN(self.maximumZoomScale, MAX(self.minimumZoomScale, oldScale));
    
    
    // Step 2: restore center point, first making sure it is within the allowable range.
    
    // 2a: convert our desired center point back to our own coordinate space
    CGPoint boundsCenter = [self convertPoint:oldCenter fromView:self.imageView];
    // 2b: calculate the content offset that would yield that center point
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                                 boundsCenter.y - self.bounds.size.height / 2.0);
    // 2c: restore offset, adjusted to be within the allowable range
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = [self minimumContentOffset];
    offset.x = MAX(minOffset.x, MIN(maxOffset.x, offset.x));
    offset.y = MAX(minOffset.y, MIN(maxOffset.y, offset.y));
    self.contentOffset = offset;
}


@end

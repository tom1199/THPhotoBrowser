//
//  THImageViewController.m
//  PhotoScrollViewDemo
//
//  Created by Tang Han on 4/9/12.
//  Copyright (c) 2012 Tang Han. All rights reserved.
//

#import "THImageViewController.h"

@interface THImageViewController ()
@property (nonatomic,assign) BOOL hideBars;
@property (nonatomic,strong) NSArray *imageURLs;
@property (nonatomic,strong) NSArray *images;
@property (nonatomic,strong) UITapGestureRecognizer *singleTapGuestureRecognizer;
@end

@implementation THImageViewController
- (id)initWithImageURLs:(NSArray *)url {
    self = [super init];
    if (self) {
        self.images = nil;
        self.imageURLs = url;
        self.wantsFullScreenLayout = YES;
    }
    return self;
}
- (id)initWithImages:(NSArray *)images {
    self = [super init];
    if (self) {
        self.imageURLs = nil;
        self.images = images;
        self.wantsFullScreenLayout = YES;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupBarsAppearence];
    
    // Step 1: make the outer paging scroll view
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    pagingScrollView.pagingEnabled = YES;
    pagingScrollView.backgroundColor = [UIColor blackColor];
    pagingScrollView.showsVerticalScrollIndicator = NO;
    pagingScrollView.showsHorizontalScrollIndicator = NO;
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    pagingScrollView.delegate = self;
    pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|
                                                UIViewAutoresizingFlexibleHeight|
                                                UIViewAutoresizingFlexibleLeftMargin|
                                                UIViewAutoresizingFlexibleRightMargin|
                                                UIViewAutoresizingFlexibleTopMargin|
                                                UIViewAutoresizingFlexibleWidth;
    
    self.singleTapGuestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleSingleTap:)];
    self.singleTapGuestureRecognizer.numberOfTapsRequired = 1;
    [pagingScrollView addGestureRecognizer:self.singleTapGuestureRecognizer];
    
    [self.view addSubview: pagingScrollView];

    // Step 2: prepare to tile content
    recycledPages = [[NSMutableSet alloc] init];
    visiblePages  = [[NSMutableSet alloc] init];
    [self tilePages];
}
- (void)setupBarsAppearence {
    //config navigation and status bar appearence and hide them
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    
    
    UIBarButtonItem *btnDone = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(btnDonePressed:)];
    self.navigationItem.rightBarButtonItem = btnDone;
    
    //    NSLog(@"bar position rect = %@",NSStringFromCGRect(self.navigationController.navigationBar.frame));
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    _hideBars = YES;
}
#pragma mark -
#pragma mark Setter & Getter 
- (void)setHideBars:(BOOL)hideBars {
    if (_hideBars != hideBars) {
        _hideBars = hideBars;
        
        //config status bar
        [[UIApplication sharedApplication] setStatusBarHidden:![UIApplication sharedApplication].statusBarHidden withAnimation:UIStatusBarAnimationFade];
        
        //config navigation bar
        float alphaTo = !_hideBars;
        NSTimeInterval duration = .3f; //manually adjusted value to syn animation with status bar
        //- force navigation bar to stay under status bar (to resolve issue where navigation bar and status bar overlay)
        CGRect newNavBarFrame = self.navigationController.navigationBar.frame;
        newNavBarFrame.origin.y = 20.0f;
        self.navigationController.navigationBar.frame = newNavBarFrame;
        
        //- perform animation
        if (!_hideBars && self.navigationController.navigationBar.hidden) {     //view that is hidden is not redrawn to the screen by changing alpha value
            [self.navigationController setNavigationBarHidden:NO animated:NO];
            self.navigationController.navigationBar.alpha = 0;
        }
        [UIView animateWithDuration:duration
                         animations:^{
                             self.navigationController.navigationBar.alpha = alphaTo;
                         }];
    }
}
#pragma mark -
#pragma mark User Actions
- (void)handleSingleTap:(UITapGestureRecognizer *)rgr {
    self.hideBars = !self.hideBars;
}
- (void)btnDonePressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}
#pragma mark -
#pragma mark Tiling and page configuration

- (void)tilePages
{
    // Calculate which pages are visible
    CGRect visibleBounds = pagingScrollView.bounds;
    int firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    int lastNeededPageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex, [self.imageURLs count] - 1);
    
    // Recycle no-longer-visible pages
    for (THImageScrollView *page in visiblePages) {
        if (page.index < firstNeededPageIndex || page.index > lastNeededPageIndex) {
            [recycledPages addObject:page];
            [page removeFromSuperview];
        }
    }
    [visiblePages minusSet:recycledPages];
    
    // add missing pages
    for (int index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            THImageScrollView *page = [self dequeueRecycledPage];
            if (page == nil) {
                page = [[THImageScrollView alloc] init];
                page.loadCompletionDelegate = self;
            }
            [self configurePage:page forIndex:index];
            [pagingScrollView addSubview:page];
            [visiblePages addObject:page];
        }
    }
}

- (THImageScrollView *)dequeueRecycledPage
{
    THImageScrollView *page = [recycledPages anyObject];
    if (page) {
        [recycledPages removeObject:page];
    }
    return page;
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index
{
    BOOL foundPage = NO;
    for (THImageScrollView *page in visiblePages) {
        if (page.index == index) {
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}

- (void)configurePage:(THImageScrollView *)page forIndex:(NSUInteger)index
{
    page.index = index;
    page.frame = [self frameForPageAtIndex:index];

    // Use images
    if (self.images && self.images.count) {
        [page displayImage:[self.images objectAtIndex:index]];
    }else if (self.imageURLs && self.imageURLs.count) {
        [page displayImageForURL:[self.imageURLs objectAtIndex:index]];
    }
}


#pragma mark -
#pragma mark ScrollView delegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    NSLog(@"scrollViewDidScroll");
    //hiden bars
    if (!self.hideBars) self.hideBars = YES;
    
    [self tilePages];
}

#pragma mark -
#pragma mark View controller rotation methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // here, our pagingScrollView bounds have not yet been updated for the new interface orientation. So this is a good
    // place to calculate the content offset that we will need in the new orientation
    CGFloat offset = pagingScrollView.contentOffset.x;
    CGFloat pageWidth = pagingScrollView.bounds.size.width;
    
    if (offset >= 0) {
        firstVisiblePageIndexBeforeRotation = floorf(offset / pageWidth);
        percentScrolledIntoFirstVisiblePage = (offset - (firstVisiblePageIndexBeforeRotation * pageWidth)) / pageWidth;
    } else {
        firstVisiblePageIndexBeforeRotation = 0;
        percentScrolledIntoFirstVisiblePage = offset / pageWidth;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // recalculate contentSize based on current orientation
    pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    // adjust frames and configuration of each visible page
    NSLog(@"visible page count = %d",visiblePages.count);
    for (THImageScrollView *page in visiblePages) {
        CGPoint restorePoint = [page pointToCenterAfterRotation];
        CGFloat restoreScale = [page scaleToRestoreAfterRotation];
        page.frame = [self frameForPageAtIndex:page.index];
        [page setMaxMinZoomScalesForCurrentBounds];
        [page restoreCenterPoint:restorePoint scale:restoreScale];
    }
    
    // adjust contentOffset to preserve page location based on values collected prior to location
    CGFloat pageWidth = pagingScrollView.bounds.size.width;
    CGFloat newOffset = (firstVisiblePageIndexBeforeRotation * pageWidth) + (percentScrolledIntoFirstVisiblePage * pageWidth);
    pagingScrollView.contentOffset = CGPointMake(newOffset, 0);
}

#pragma mark -
#pragma mark  Frame calculations
#define PADDING  10

- (CGRect)frameForPagingScrollView {
    CGRect frame = [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return frame;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self.imageURLs count], bounds.size.height);
}

#pragma mark -
#pragma mark THImageScrollViewLoadingCompletionDelegate
- (void)imageDidLoaded:(THImageScrollView *)scrollView {
    [self.singleTapGuestureRecognizer requireGestureRecognizerToFail:scrollView.doubleTapGuestureRecognizer];
}
@end

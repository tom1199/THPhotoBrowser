//
//  THImageViewController.h
//  PhotoScrollViewDemo
//
//  Created by Tang Han on 4/9/12.
//  Copyright (c) 2012 Tang Han. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THImageScrollView.h"

@interface THImageViewController : UIViewController<UIScrollViewDelegate,THImageScrollViewDelegate> {
@private
    UIScrollView *pagingScrollView;
    
    NSMutableSet *recycledPages;
    NSMutableSet *visiblePages;
    
    // these values are stored off before we start rotation so we adjust our content offset appropriately during rotation
    int           firstVisiblePageIndexBeforeRotation;
    CGFloat       percentScrolledIntoFirstVisiblePage;
}
- (id)initWithImageURLs:(NSArray *)url;
- (id)initWithImages:(NSArray *)images;

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;

- (CGRect)frameForPagingScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGSize)contentSizeForPagingScrollView;

- (void)tilePages;
- (THImageScrollView *)dequeueRecycledPage;

@end

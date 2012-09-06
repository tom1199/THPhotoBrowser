//
//  THViewController.m
//  PhotoScrollViewDemo
//
//  Created by Tang Han on 4/9/12.
//  Copyright (c) 2012 Tang Han. All rights reserved.
//

#import "THViewController.h"
#import "THImageViewController.h"

@interface THViewController ()

@end

@implementation THViewController

- (IBAction)btnGoPressed:(id)sender {
    NSMutableArray *urls = [[NSMutableArray alloc]init];
    NSURL *url = nil;
    url = [NSURL URLWithString:@"http://cdn.baekdal.com/2008/hd61.jpg"];
    [urls addObject:url];
    url = [NSURL URLWithString:@"http://4.bp.blogspot.com/-SH_PHJQZHW0/TqhL06COrqI/AAAAAAAAAas/zyPBTNgbh-Q/s400/3D-Glass-Imaginations-29.jpg"];
    [urls addObject:url];
    url = [NSURL URLWithString:@"http://images02.olx.com.sg/ui/20/22/46/1337868569_105921646_3-Customised-Cupcakes-for-your-parties-For-Sale.jpg"];
    [urls addObject:url];
    
    THImageViewController *imageViewController = [[THImageViewController alloc]initWithImageURLs:urls];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:imageViewController];
    [self.navigationController presentModalViewController:navController animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end

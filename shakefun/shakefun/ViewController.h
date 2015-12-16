//
//  ViewController.h
//  shakefun
//
//  Created by zm on 15/9/9.
//  Copyright (c) 2015年 zm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIWebView *webViewBrowser;
- (IBAction)buttonNextToggle:(id)sender;
- (IBAction)buttonCollectToggle:(id)sender;

@end

@interface NSString (TMNSStringExtensionMethods)
- (NSArray *)componentsSeparatedFromString:(NSString *)fromString toString:(NSString *)toString;
@end

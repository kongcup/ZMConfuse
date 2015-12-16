//
//  CollectViewController.h
//  shakefun
//
//  Created by zm on 15/9/9.
//  Copyright (c) 2015年 zm. All rights reserved.
//

#ifndef shakefun_CollectViewController_h
#define shakefun_CollectViewController_h
#import <UIKit/UIKit.h>

@interface CollectViewController : UIViewController <UITextFieldDelegate>
{
    
}
- (IBAction)buttonStartCollectToggle:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *textViewLogInfo;
@property (weak, nonatomic) IBOutlet UITextField *textfieldPageNum;

@end
#endif

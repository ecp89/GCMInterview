//
//  MyMutualFriendCell.h
//  GCMInterview
//
//  Created by Eric Pass on 2/7/16.
//  Copyright © 2016 Eric Pass. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyMutualFriendCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *idLabel;
@property (strong, nonatomic) IBOutlet UILabel *numberOfMutualFriends;

@end

//
//  MyMutualFriendCell.m
//  GCMInterview
//
//  Created by Eric Pass on 2/7/16.
//  Copyright © 2016 Eric Pass. All rights reserved.
//

#import "MyMutualFriendCell.h"

@implementation MyMutualFriendCell
@synthesize nameLabel, idLabel, numberOfMutualFriends;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}
@end

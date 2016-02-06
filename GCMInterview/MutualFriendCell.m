//
//  MutualFriendCell.m
//  GCMInterview
//
//  Created by Eric Pass on 2/6/16.
//  Copyright © 2016 Eric Pass. All rights reserved.
//

#import "MutualFriendCell.h"

@implementation MutualFriendCell {
    UILabel * _uidValue;
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self){
        CGRect uidLabelRectangle = CGRectMake(0, 5, 70, 15);
        UILabel *uidLabel = [[UILabel alloc] initWithFrame:uidLabelRectangle];
        uidLabel.textAlignment = NSTextAlignmentRight;
        uidLabel.text = @"UID: ";
        uidLabel.font = [UIFont boldSystemFontOfSize:12];
        [self.contentView addSubview:uidLabel];
    }
    return self;
}
-(void) setUid:(NSString *)uid {
    if(![uid isEqualToString:self.uid]){
        self.uid = [uid copy];
    }
}


- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

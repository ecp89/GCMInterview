//
//  ViewController.m
//  GCMInterview
//
//  Created by Eric Pass on 2/1/16.
//  Copyright © 2016 Eric Pass. All rights reserved.
//

#import "ViewController.h"
#import "FriendTableViewController.h"
#import "MyMutualFriendCell.h"
#import "TestUserAccount.h"
#import "TestFriend.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>



@interface ViewController ()

#define APP_ID "1127706020607554"
#define ACCESS_TOKEN "1127706020607554|Oy4CN4YXBFNVTG3K4aWAYape4Ng"
#define NUMBER_OF_ACCOUNTS 50
#define LIMIT_FOR_FB_REQUEST "500"
#define NUMBER_OF_FRIENDS 20


@property (strong, nonatomic) IBOutlet UITableView *myTableView;
@property (strong, nonatomic) IBOutlet FBSDKLoginButton *loginButton;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) NSMutableArray *tableData;
@property (strong, nonatomic) NSString *currentUserToken;
@property (strong, nonatomic) NSMutableDictionary *mutualFriendsDict;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
    self.loginButton.readPermissions =
    @[@"public_profile", @"email", @"user_friends"];

}

-(void) viewWillAppear:(BOOL)animated{
    NSLog(@"viewWillAppear");
    self.currentUserToken = [FBSDKAccessToken currentAccessToken].tokenString;
    NSLog(@"currentUserToken %@", self.currentUserToken);
    
    if ([FBSDKAccessToken currentAccessToken]) {
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"/me" parameters:@{@"fields": @"id, name"} tokenString:self.currentUserToken version:nil HTTPMethod:@"GET"]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             
             self.nameLabel.text = [result objectForKey:@"name"] ;
             if (!error) {
                 NSLog(@"%@", result);
             }
         }];
    } else {
        self.nameLabel.text = @"Some placeholder text";
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * Method that deletes all the test users for this application. If there are more than
 * 500 it will only delete the first 500, so you might have to call it multiple times.
 **/
-(IBAction) deleteAllTestUsers:(id)sender  {
    
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:@"/"APP_ID"/accounts"
                                      parameters:@{@"limit":@LIMIT_FOR_FB_REQUEST}
                                      tokenString:@ACCESS_TOKEN
                                      version:nil
                                      HTTPMethod:@"GET"];
    
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            NSArray *items = [result objectForKey:@"data"];
            for(id account in items){
                //The api call to delete a test user is simply their account id with DELETE HTTPMethod
                NSString *apiCall =[NSString stringWithFormat:@"/%@", [account objectForKey:@"id"]];
                FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                              initWithGraphPath:apiCall
                                              parameters:nil
                                              tokenString:@ACCESS_TOKEN
                                              version:nil
                                              HTTPMethod:@"DELETE"];
                [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                                      id result,
                                                      NSError *error) {
                }];
            }
            
        }];


}


/**
 * This method creates NUMBER_OF_ACCOUNTS amount of test users into the application.
 **/
-(IBAction) createTestUsers:(id)sender  {
    for (int i = 0; i<NUMBER_OF_ACCOUNTS; i++) {
        NSString *name = [[NSString alloc] initWithFormat:@"Test User %@", [self getNameForNumber:i]];
        //For this app to work the test users need to initilized as installed
        //(so that they can friend one an other), have the user_friends permission
        //so that we can see their mutual friends and the access_token to make the
        //actuall request
        NSDictionary *params = @{
                                 @"installed": @"true",
                                 @"permissions":@"user_friends, public_profile",
                                 @"name":name
                                 };
        
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:@"/"APP_ID"/accounts/test-users"
                                      parameters:params
                                      tokenString:@ACCESS_TOKEN
                                      version:nil
                                      HTTPMethod:@"POST"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
        }];
    }
    
}

-(NSString *) getNameForNumber:(int) i {
    if(i<36) {
        return [[NSString alloc] initWithFormat:@"%c",  ('a' + i%36)];
    }
    return [[NSString alloc] initWithFormat:@"%c%c",  ('a' + i/36), ('a' + i%36) ];
   
}

/**
 * This method creates a random network of friends for the test users. It gathers all 
 * of the accounts and for each account attempts to friend NUMBER_OF_FRIENDS different
 * accounts.
 **/
- (IBAction)doFriendRequest:(id)sender {

    NSString *rootURL = @"/"APP_ID"/accounts";
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:rootURL
                                  parameters:@{@"fields": @"id, access_token",@"limit":@LIMIT_FOR_FB_REQUEST}
                                  tokenString:@ACCESS_TOKEN
                                  version:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        NSMutableSet *accumulator = [[NSMutableSet alloc] init];

        
        NSArray *items = [result objectForKey:@"data"];
        
        for(id account in items){
            TestUserAccount *testUserAccount = [[TestUserAccount alloc] init];
            testUserAccount.uid = [account objectForKey:@"id"];
            testUserAccount.access_token = [account objectForKey:@"access_token"];
            
            [accumulator addObject: testUserAccount];
        }
        
        NSArray *accountIds = [accumulator allObjects];
        unsigned long length = [accountIds count];
        for(int i = 0; i <length; i++){
            NSMutableSet *alreadyFriendsWith = [[NSMutableSet alloc] init];
            [alreadyFriendsWith addObject:[[NSNumber alloc] initWithInt:i]];
            //Make everyone have NUMBER_OF_FRIENDS different friends. This might not acutally be the case
            //Since when doing the request we might get an error.
            for(int j = 0; j < NUMBER_OF_FRIENDS; j++) {
                int randomIndex = [self getRandomIndex: alreadyFriendsWith :length ];
                TestUserAccount *user1 = [accountIds objectAtIndex:i];
                TestUserAccount *user2 = [accountIds objectAtIndex:randomIndex];
                [self doFriendPosting:user1 :user2];
                [self doFriendPosting:user2 :user1];
                [alreadyFriendsWith addObject:[[NSNumber alloc] initWithInt:randomIndex]];
                
            }
        }
    }];
}
- (IBAction)getFriendsPressed:(id)sender {
    NSString *rootURL = @"/"APP_ID"/accounts";
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:rootURL
                                  parameters:@{@"fields": @"id, access_token",@"limit":@LIMIT_FOR_FB_REQUEST}
                                  tokenString:@ACCESS_TOKEN
                                  version:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        NSLog(@"%@",result);
        self.tableData = [[NSMutableArray alloc]init];
        NSArray *items = [result objectForKey:@"data"];
        
        for(id account in items){
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:[account objectForKey:@"id"] forKey:@"uid"];
            [self.tableData addObject:dict];
            
        }
        [self.myTableView reloadData];
    }];
    
}
- (IBAction)testButtonPushed:(id)sender {
    [self getAllMutualFriends];
}

/**
 * Could probably change this over to use batch requesting
 **/
-(void) doFriendPosting: (TestUserAccount *) user1 : (TestUserAccount *)user2{
    NSString *requestString = [[NSString alloc] initWithFormat:@"/%@/friends/%@", user1.uid, user2.uid];
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:requestString
                                  parameters:nil
                                  tokenString:user1.access_token
                                  version:nil
                                  HTTPMethod:@"POST"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        NSLog(@"%@",result);
    }];
}
-(void) getAllMutualFriends {
    //We are going to need a new set of data for the table view
    self.tableData = [[NSMutableArray alloc] init];
    NSMutableArray *unproccessedFriends = [[NSMutableArray alloc]init];
    //Get all the friends of the current user who use the app
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"me/friends"
                                  parameters:@{@"fields": @"id, name",@"limit":@LIMIT_FOR_FB_REQUEST}
                                  tokenString:self.currentUserToken
                                  version:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        NSArray *items = [result objectForKey:@"data"];
        NSLog(@"REUSLT IN GET%@",result);
        for(id account in items){
            TestFriend *friend = [[TestFriend alloc] init];
            friend.uid = [account objectForKey:@"id"];
            friend.name = [account objectForKey:@"name"];
            [unproccessedFriends addObject:friend];
        }
        //Set of id's of friends we have already processed
        NSMutableSet *processed = [[NSMutableSet alloc]init];
        for(int i = 0; i < [unproccessedFriends count]; i++) {
            TestFriend* currentFriend = [unproccessedFriends objectAtIndex:i];
            NSDictionary *params = @{
                                     @"fields": @"context.fields(mutual_friends)",
                                     @"limit":@LIMIT_FOR_FB_REQUEST
                                     };
            FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                          initWithGraphPath:[[NSString alloc] initWithFormat:@"/%@", currentFriend.uid]
                                          parameters:params
                                          tokenString:self.currentUserToken
                                          version:nil
                                          HTTPMethod:@"GET"];
            [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                                  id result,
                                                  NSError *error) {
                if(error){
                    NSLog(@"Error fetching mutual friends: %@", error);
                } else {
                    id usefulInformation = [[result objectForKey:@"context"] objectForKey:@"mutual_friends"];
                    int countOfMutualFriends = [[[usefulInformation objectForKey:@"summary"] objectForKey:@"total_count"] intValue];
                    if(countOfMutualFriends > 0){
                        NSMutableArray *mutualFriends = [[NSMutableArray alloc] init];
                        id data = [usefulInformation objectForKey:@"data"];
                        for(id mutualFriend in data){
                            TestFriend *currentMutualFriend = [[TestFriend alloc] init];
                            currentMutualFriend.uid = [mutualFriend objectForKey:@"id"];
                            currentMutualFriend.name = [mutualFriend objectForKey:@"name"];
                            [mutualFriends addObject:mutualFriend];
                        }
                        currentFriend.mutualFriends = mutualFriends;
                        [self.tableData addObject:currentFriend];
                        [self.myTableView reloadData];
                        
                    }
                    [processed addObject:currentFriend.uid];
                    
                }
            }];


        }
    }];
    
}

/**
 * Helper method to get a random index to get another user to become friends with who
 * they have not friended before and who is not themself.
 **/
-(int)getRandomIndex: (NSMutableSet *) alreadyFriendsWith : (unsigned long) length{
    int randomIndex;
    do {
        randomIndex = arc4random_uniform(length-1);
    } while([alreadyFriendsWith containsObject:[[NSNumber alloc] initWithInt:randomIndex]] );
    return randomIndex;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tableData count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // The header for the section is the region name -- get this from the region at the section index
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifier = @"MyReuseIdentifier";
    MyMutualFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"MyMutualFriendCell" owner:self options:nil];
        cell = [nibArray objectAtIndex:0];
    }
    TestFriend *rowData = self.tableData[indexPath.row];
    cell.idLabel.text = rowData.uid;
    cell.nameLabel.text = rowData.name;
    cell.numberOfMutualFriends.text = [[NSString alloc] initWithFormat:@"%lu", [rowData.mutualFriends count] ];

    return cell;
}


@end

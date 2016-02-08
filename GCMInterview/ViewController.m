//
//  ViewController.m
//  GCMInterview
//
//  Created by Eric Pass on 2/1/16.
//  Copyright © 2016 Eric Pass. All rights reserved.
//

#import "ViewController.h"
#import "MyMutualFriendCell.h"
#import "TestUserAccount.h"
#import "TestFriend.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>


@interface ViewController ()

#define APP_ID "1127706020607554"

#define ACCESS_TOKEN "1127706020607554|Oy4CN4YXBFNVTG3K4aWAYape4Ng"

/**
 * Number of test user accounts you want to create for the app
 **/
#define NUMBER_OF_ACCOUNTS 50

/**
 * The limit of the number of records returned in a Facebook
 * API called. You want to make this a large number so you do not 
 * have to deal with pagination. 500 by trial and error works well.
 **/
#define LIMIT_FOR_FB_REQUEST "500"

/**
 * The number of friends ideally each test user will have. In practice 
 * each test user has less than this number of friends because the 
 * Graph API cannot handle the all the requests coming to it. 
 * We might see a better result by using batch request for friending.
 **/
#define NUMBER_OF_FRIENDS 20

//This is the table in the center of the screen
@property (strong, nonatomic) IBOutlet UITableView *myTableView;

//This is the Facebook login button
@property (strong, nonatomic) IBOutlet FBSDKLoginButton *loginButton;

//This is where we will see the name of the current logged in user
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;

//This is an array containing our TestFriends which will
//be displayed in TableView
@property (strong, nonatomic) NSMutableArray *tableData;

//The access token of the current logged in user for convenience
@property (strong, nonatomic) NSString *currentUserToken;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //This button is actually used and the program will segfault if we
    //do not have this initialization
    FBSDKLoginButton *loginButton __attribute__((unused)) = [[FBSDKLoginButton alloc] init];
    
    self.loginButton.readPermissions =
    @[@"public_profile", @"email", @"user_friends"];

}

-(void) viewWillAppear:(BOOL)animated{
    self.currentUserToken = [FBSDKAccessToken currentAccessToken].tokenString;
    
    if ([FBSDKAccessToken currentAccessToken]) {
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"/me"
                                    parameters:@{@"fields": @"id, name"}
                                    tokenString:self.currentUserToken
                                    version:nil
                                    HTTPMethod:@"GET"]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             
             self.nameLabel.text = [result objectForKey:@"name"] ;
             if (!error) {
                 NSLog(@"%@", result);
             }
         }];
    } else {
        self.nameLabel.text = @"No logged in user...";
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * This method creates NUMBER_OF_ACCOUNTS amount of test users into the application.
 **/
-(IBAction) createTestUsers:(id)sender  {
    for (int i = 0; i<NUMBER_OF_ACCOUNTS; i++) {
        //Facebook does not always name the user this name so look into
        NSString *name = [[NSString alloc] initWithFormat:@"Test User %@", [self getNameForNumber:i]];
        //For this app to work the test users need to be initialized as installed
        //(so that they can friend one an other), have the user_friends permission
        //so that we can see their mutual friends
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
            if(i == NUMBER_OF_ACCOUNTS - 1){
                NSString *message = [[NSString alloc] initWithFormat:@"%d test users created!", NUMBER_OF_ACCOUNTS];
                
                UIAlertView *toast = [[UIAlertView alloc] initWithTitle:nil
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:nil, nil];
                [toast show];
                
                int duration = 2; // duration in seconds
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [toast dismissWithClickedButtonIndex:0 animated:YES];
                });
            }
        }];
    }
    
}

/**
 * This is a way to name the users predictably making user 1-> Test User a 
 * and user 37 Test User aa and so on. This can name the first 1,296 users 
 * uniquely and since Facebook only lets you have 2000 Test users, this is 
 * adequate.
 **/
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
        if(length <= 1){
            return;
        }
        for(int i = 0; i <length; i++){
            NSMutableSet *alreadyFriendsWith = [[NSMutableSet alloc] init];
            [alreadyFriendsWith addObject:[[NSNumber alloc] initWithInt:i]];
            //Make everyone have NUMBER_OF_FRIENDS different friends. This might not actually be the case
            //Since when doing the request we might get an error.
            for(int j = 0; j < NUMBER_OF_FRIENDS; j++) {
                int randomIndex = [self getRandomIndex: alreadyFriendsWith :length ];
                TestUserAccount *user1 = [accountIds objectAtIndex:i];
                TestUserAccount *user2 = [accountIds objectAtIndex:randomIndex];
                [self doFriendPosting:user1 :user2: false];
                [self doFriendPosting:user2 :user1: i == length-1 && j == NUMBER_OF_FRIENDS -1 ];
                [alreadyFriendsWith addObject:[[NSNumber alloc] initWithInt:randomIndex]];
                
            }
        }
    }];
}
/**
 * Helper method to get a random index to get another user to become friends with who
 * they have not friended before and who is not them self.
 **/
-(int)getRandomIndex: (NSMutableSet *) alreadyFriendsWith : (unsigned long) length{
    int randomIndex;
    do {
        randomIndex = arc4random_uniform(length-1);
    } while([alreadyFriendsWith containsObject:[[NSNumber alloc] initWithInt:randomIndex]] );
    return randomIndex;
    
}

/**
 * This method calls the Facebook API to make two test users friends. In order for two
 * users to become friends you must call this function twice, swapping the order of the 
 * arguments. This is because you need to call the API with both users access tokens.
 **/
-(void) doFriendPosting: (TestUserAccount *) user1 : (TestUserAccount *)user2 : (BOOL) isLastPost{
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
        if(isLastPost){
            NSString *message = @"Network of friends created!";
            
            UIAlertView *toast = [[UIAlertView alloc] initWithTitle:nil
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:nil, nil];
            [toast show];
            
            int duration = 2; // duration in seconds
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [toast dismissWithClickedButtonIndex:0 animated:YES];
            });
        }
    }];
}


/**
 * Method that deletes all the test users for this application. If there are more than
 * LIMIT_FOR_FB_REQUEST users then it it will only delete the first LIMIT_FOR_FB_REQUEST,
 * so you might have to call it multiple times.
 **/
-(IBAction) deleteAllTestUsers:(id)sender  {
    
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:@"/"APP_ID"/accounts"
                                      parameters:@{@"fields": @"id, name",@"limit":@LIMIT_FOR_FB_REQUEST}
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
                    if([items lastObject]== account){
                        NSString *message = @"All test users deleted!";
                        
                        UIAlertView *toast = [[UIAlertView alloc] initWithTitle:nil
                                                                        message:message
                                                                       delegate:nil
                                                              cancelButtonTitle:nil
                                                              otherButtonTitles:nil, nil];
                        [toast show];
                        
                        int duration = 2; // duration in seconds
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            [toast dismissWithClickedButtonIndex:0 animated:YES];
                        });
                    }
                }];
            }
            
        }];


}

/**
 * This is the function for the project. This function returns all of the currently logged
 * in users friends who have 1 or more mutual friends with you. It does this by getting the 
 * current logged in users friends list, then calls the mutual friend API to determine if 
 * this user should be solved (if they have more than one mutual friend with you). 
 * The time complexity is O(n+nm) where n is the number of friends you have and m is the
 * number of mutual friends your friends have. You could bring this down to O(n) if you
 * did not want to collect the mutual friends.
 *
 **/
- (IBAction)getFriendsButtonPressed:(id)sender {
    //We are going to need a new set of data for the table view
    self.tableData = [[NSMutableArray alloc] init];
    //The accumulator to put all of the friends we found
    NSMutableArray *unproccessedFriends = [[NSMutableArray alloc]init];
    //The request to get all the friends of the current user who use the app
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"me/friends"
                                  parameters:@{@"fields": @"id, name",@"limit":@LIMIT_FOR_FB_REQUEST}
                                  tokenString:self.currentUserToken
                                  version:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        //Process all of the users friends we have found
        NSArray *items = [result objectForKey:@"data"];
        for(id account in items){
            TestFriend *friend = [[TestFriend alloc] init];
            friend.uid = [account objectForKey:@"id"];
            friend.name = [account objectForKey:@"name"];
            [unproccessedFriends addObject:friend];
        }

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
                        //Gather all the mutual friends
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
                    
                }
            }];


        }
    }];
    
}

/*------------------ Table View Methods ------------------*/

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    TestFriend *testFriend = self.tableData[indexPath.row];
    NSString *msg =  @"";
    NSString *title = [[NSString alloc] initWithFormat:@"%@ and %@ Mutual Friends", self.nameLabel.text, testFriend.name];
    for(NSDictionary *friend in testFriend.mutualFriends){

        NSString *s =[[NSString alloc] initWithFormat:@"\n%@", [friend objectForKey:@"name"]];
        msg = [msg stringByAppendingString:s];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}


@end

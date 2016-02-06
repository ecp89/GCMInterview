//
//  ViewController.m
//  GCMInterview
//
//  Created by Eric Pass on 2/1/16.
//  Copyright © 2016 Eric Pass. All rights reserved.
//

#import "ViewController.h"
#import "FriendTableViewController.h"
#import "MutualFriendCell.h"
#import "TestUserAccount.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>



@interface ViewController ()

#define APP_ID "1127706020607554"
#define ACCESS_TOKEN "1127706020607554|Oy4CN4YXBFNVTG3K4aWAYape4Ng"
#define NUMBER_OF_ACCOUNTS 50
#define LIMIT_FOR_FB_REQUEST "500"
#define NUMBER_OF_FRIENDS 10


@property (strong, nonatomic) IBOutlet UITableView *myTableView;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) NSMutableArray *friends;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.loginButton = [[FBSDKLoginButton alloc] init];
    // Optional: Place the button in the center of your view.
    
    if ([FBSDKAccessToken currentAccessToken]) {
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id, name"}]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            self.nameLabel.text = [result objectForKey:@"name"] ;
             if (!error) {
                  NSLog(@"%@", result);
             }
         }];
    }


    
   


    
    
    

}

-(IBAction)loginButtonPressed:(id)sender{
    NSLog(@"Login button pressed");
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login
     logInWithReadPermissions: @[@"user_friends"]
     fromViewController:self
     handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
         if (error) {
             NSLog(@"Process error");
         } else if (result.isCancelled) {
             NSLog(@"Cancelled");
         } else {
             NSLog(@"Logged in");
         }
     }];
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
                                      parameters:@{@"access_token": @ACCESS_TOKEN, @"limit":@LIMIT_FOR_FB_REQUEST}
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
                                              parameters:@{@"access_token": @ACCESS_TOKEN}
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
        //For this app to work the test users need to initilized as installed
        //(so that they can friend one an other), have the user_friends permission
        //so that we can see their mutual friends and the access_token to make the
        //actuall request
        NSDictionary *params = @{
                                 @"installed": @"true",
                                 @"permissions":@"user_friends",
                                 @"access_token": @ACCESS_TOKEN,
                                 };
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:@"/"APP_ID"/accounts/test-users"
                                      parameters:params
                                      HTTPMethod:@"POST"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
        }];
    }
    
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
                                  parameters:@{@"access_token": @ACCESS_TOKEN,@"fields": @"id, access_token",@"limit":@LIMIT_FOR_FB_REQUEST}
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
                                  parameters:@{@"access_token": @ACCESS_TOKEN,@"fields": @"id, access_token",@"limit":@LIMIT_FOR_FB_REQUEST}
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        NSLog(@"%@",result);
        self.friends = [[NSMutableArray alloc]init];
        NSArray *items = [result objectForKey:@"data"];
        
        for(id account in items){
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:[account objectForKey:@"id"] forKey:@"uid"];
            [self.friends addObject:dict];
            
        }
        [self.myTableView reloadData];
    }];
    
}
/**
 * This method does the acutall friending. The easiest way was to do an actuall HTTP request
 * and to not go through the API. In order to for two test users to become friends they must both
 * have installed the app and you must have their access tokens. You have to call
 * https://graph.facebook.com/USER_1_ID/friends/USER_2_ID?access_token=USER_1_ACCESS_TOKEN then
 * https://graph.facebook.com/USER_2_ID/friends/USER_1_ID?access_token=USER_2_ACCESS_TOKEN for
 * user 1 and user 2 to become friends.
 **/
-(void) doFriendPosting: (TestUserAccount *) user1 : (TestUserAccount *)user2{
    NSString *urlString = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/friends/%@", user1.uid, user2.uid];
    NSURL *testUserUrl = [NSURL URLWithString:urlString];
    NSMutableURLRequest *testUserRequest = [[NSMutableURLRequest alloc] initWithURL:testUserUrl];
    [testUserRequest setHTTPMethod:@"POST"];
    [testUserRequest addValue:@"text/plain" forHTTPHeaderField:@"content-type"];
    NSString *bodyString = [[NSString alloc] initWithFormat:@"access_token=%@", user1.access_token];
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [testUserRequest setHTTPBody:bodyData];
    [NSURLConnection sendAsynchronousRequest:testUserRequest queue:[NSOperationQueue currentQueue]
                           completionHandler: ^(NSURLResponse * response, NSData * data, NSError * error) {
                               NSLog(@"%@", response);
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
    return [self.friends count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // The header for the section is the region name -- get this from the region at the section index
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifier = @"MyReuseIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:MyIdentifier];
    }
    NSDictionary *rowData = self.friends[indexPath.row];
    cell.textLabel.text = rowData[@"uid"];
    return cell;
}

/*------------------------------------- DEPRECATED CODE FOR REF ------------------------------------------*/

-(IBAction)createTestUser:(id)sender{
    NSString *urlString = @"https://graph.facebook.com/"APP_ID"/accounts/test-users";
    NSURL *testUserUrl = [NSURL URLWithString:urlString];
    NSMutableURLRequest *testUserRequest = [[NSMutableURLRequest alloc] initWithURL:testUserUrl];
    [testUserRequest setHTTPMethod:@"POST"];
    [testUserRequest addValue:@"text/plain" forHTTPHeaderField:@"content-type"];
    NSString *bodyString = @"installed=true&permissions=user_friends&access_token=1127706020607554|Oy4CN4YXBFNVTG3K4aWAYape4Ng";
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [testUserRequest setHTTPBody:bodyData];
    [NSURLConnection sendAsynchronousRequest:testUserRequest queue:[NSOperationQueue currentQueue]
                           completionHandler: ^(NSURLResponse * response, NSData * data, NSError * error) {
                               NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse*)response;
                               if(!error){
                                   NSLog(@"Response to test user creation: %@",httpResponse);
                               } else {
                                   NSLog(@"ERROR to test user creation: %@", error);
                               }
                           }
     ];
    
}

/**
 Recursive method that given the accounts url populates the accumulator with all
 of the accountID's for this app.
 **/
- (void)doFriendRequestHelper: (NSString*) url : (NSMutableSet *) accumulator  {
    NSLog(@"In FriendRequestHelper%@", accumulator);
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:url
                                  parameters:@{@"access_token": @"1127706020607554|Oy4CN4YXBFNVTG3K4aWAYape4Ng",@"fields": @"id, acces_token"}
                                  HTTPMethod:@"GET"];
    
    
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        //NSLog(@"%@", result);
        //NSLog(@"%@", error);
        
        NSArray *items = [result objectForKey:@"data"];
        NSString *nextURL = [[result objectForKey:@"paging"] objectForKey:@"next"];
        
        
        for(id account in items){
            TestUserAccount *testUserAccount = [[TestUserAccount alloc] init];
            testUserAccount.uid = [account objectForKey:@"id"];
            testUserAccount.access_token = [account objectForKey:@"access_token"];
            
            [accumulator addObject: testUserAccount];
        }
        
        //Base case
        if(nextURL == NULL){
            
            
            
            
            return;
        }
        
        //Need to strip the url of this junk so it can be used in a FBSDKGraphRequest
        NSString *prefix = @"https://graph.facebook.com/v2.5/";
        NSRange substringRange = NSMakeRange(prefix.length,
                                             nextURL.length - prefix.length);
        NSString *fixedURL = [nextURL substringWithRange:substringRange];
        
        //[self.waitForAccountsToFinishProcesssing unlock];
        //Recursive call
        
        [self doFriendRequestHelper :fixedURL :accumulator];
        
        
    }];
    
}


@end

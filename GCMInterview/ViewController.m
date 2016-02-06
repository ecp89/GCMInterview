//
//  ViewController.m
//  GCMInterview
//
//  Created by Eric Pass on 2/1/16.
//  Copyright © 2016 Eric Pass. All rights reserved.
//

#import "ViewController.h"
#import "TestUserAccount.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>



@interface ViewController ()

#define APP_ID "1127706020607554"
#define ACCESS_TOKEN "1127706020607554|Oy4CN4YXBFNVTG3K4aWAYape4Ng"
#define NUMBER_OF_ACCOUNTS 50


@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
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




-(IBAction) deleteAllTestUsers:(id)sender  {
    
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:@"/"APP_ID"/accounts"
                                      parameters:@{@"access_token": @ACCESS_TOKEN, @"limit":@"500"}
                                      HTTPMethod:@"GET"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            NSLog(@"%@", result);
            NSLog(@"%@", error);
            
            NSArray *items = [result objectForKey:@"data"];
            for(id account in items){
                NSString *apiCall =[NSString stringWithFormat:@"/%@", [account objectForKey:@"id"]];
                FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                              initWithGraphPath:apiCall
                                              parameters:@{@"access_token": @ACCESS_TOKEN}
                                              HTTPMethod:@"DELETE"];
                [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                                      id result,
                                                      NSError *error) {
                    NSLog(@"%@", result);
                    NSLog(@"%@", error);
                
                }];
            }
            
            
            
        }];
    


}

-(IBAction) generateRandomNetwork:(id)sender  {
    for (int i = 0; i<NUMBER_OF_ACCOUNTS; i++) {
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

- (IBAction)doFriendRequest:(id)sender {

    NSString *rootURL = @"/"APP_ID"/accounts";
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:rootURL
                                  parameters:@{@"access_token": @ACCESS_TOKEN,@"fields": @"id, access_token"}
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        NSMutableSet *accumulator = [[NSMutableSet alloc] init];
        //NSLog(@"%@", result);
        //NSLog(@"%@", error);
        
        NSArray *items = [result objectForKey:@"data"];
        
        for(id account in items){
            TestUserAccount *testUserAccount = [[TestUserAccount alloc] init];
            testUserAccount.uid = [account objectForKey:@"id"];
            testUserAccount.access_token = [account objectForKey:@"access_token"];
            
            [accumulator addObject: testUserAccount];
        }
        
        NSLog(@"%@", accumulator);
        NSArray *accountIds = [accumulator allObjects];
        unsigned long length = [accountIds count];
        for(int i = 0; i <length; i++){
            NSMutableSet *alreadyFriendsWith = [[NSMutableSet alloc] init];
            [alreadyFriendsWith addObject:[[NSNumber alloc] initWithInt:i]];
            //Make everyone have 10 different friends
            for(int j = 0; j < 10; j++) {
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

-(int)getRandomIndex: (NSMutableSet *) alreadyFriendsWith : (unsigned long) length{
    int randomIndex;
    do {
        randomIndex = arc4random_uniform(length-1);
    } while([alreadyFriendsWith containsObject:[[NSNumber alloc] initWithInt:randomIndex]] );
    return randomIndex;
    
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



@end

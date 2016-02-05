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




@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property BOOL *stillProcessingAcconts;
@property id waitForAccountsToFinishProcesssing;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.stillProcessingAcconts = false;
    self.waitForAccountsToFinishProcesssing = [[NSCondition alloc] init];
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

- (IBAction)pressedButton:(id)sender {
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"/me/taggable_friends"
                                  parameters:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
         NSLog(@"%@", result);
        
     }];
}

-(IBAction)createTestUser:(id)sender{
    NSString *urlString = @"https://graph.facebook.com/1127706020607554/accounts/test-users";
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

-(IBAction) deleteAllTestUsers:(id)sender  {
    
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:@"/1127706020607554/accounts"
                                      parameters:@{@"access_token": @"1127706020607554|Oy4CN4YXBFNVTG3K4aWAYape4Ng"}
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
                                              parameters:@{@"access_token": @"1127706020607554|Oy4CN4YXBFNVTG3K4aWAYape4Ng"}
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
    for (int i = 0; i<50; i++) {
        NSDictionary *params = @{
                                 @"installed": @"true",
                                 @"permissions":@"user_friends",
                                 @"access_token": @"1127706020607554|Oy4CN4YXBFNVTG3K4aWAYape4Ng",
                                 };
        /* make the API call */
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:@"/1127706020607554/accounts/test-users"
                                      parameters:params
                                      HTTPMethod:@"POST"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            // Handle the result
        }];
    }
    
}

- (IBAction)doFriendRequest:(id)sender {
    [self.waitForAccountsToFinishProcesssing lock];
    NSString *rootURL = @"/1127706020607554/accounts";
    NSMutableSet *accumulator = [[NSMutableSet alloc] init];
    dispatch_queue_t friendQueue = dispatch_queue_create("Friend Queue",NULL);
    dispatch_async(friendQueue, ^{
        self.stillProcessingAcconts = true;
        [self doFriendRequestHelper:rootURL : accumulator];
    });
    while(self.stillProcessingAcconts){
        [self.waitForAccountsToFinishProcesssing wait];
    }
    [self.waitForAccountsToFinishProcesssing unlock];

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
   
   
}

-(void) doFriendPosting: (TestUserAccount *) user1 : (TestUserAccount *)user2{
    NSString *urlString = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/accounts/%@", user1.uid, user2.uid];
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
    NSLog(@"%@", accumulator);
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:url
                                  parameters:@{@"access_token": @"1127706020607554|Oy4CN4YXBFNVTG3K4aWAYape4Ng"}
                                  HTTPMethod:@"GET"];
    
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
         NSLog(@"%@", error);
        NSArray *items = [result objectForKey:@"data"];
        NSString *nextURL = [[result objectForKey:@"paging"] objectForKey:@"next"];
        [self.waitForAccountsToFinishProcesssing lock];
        for(id account in items){
            TestUserAccount *testUserAccount = [[TestUserAccount alloc] init];
            testUserAccount.uid = [account objectForKey:@"id"];
            testUserAccount.access_token = [account objectForKey:@"access_token"];

            [accumulator addObject: testUserAccount];
        }
        
        //Base case
        if(nextURL == NULL){
            self.stillProcessingAcconts =false;
            [self.waitForAccountsToFinishProcesssing signal];
            [self.waitForAccountsToFinishProcesssing unlock];
            
            return;
        }
        
        //Need to strip the url of this junk so it can be used in a FBSDKGraphRequest
        NSString *prefix = @"https://graph.facebook.com/v2.5/";
        NSRange substringRange = NSMakeRange(prefix.length,
                                             nextURL.length - prefix.length);
        NSString *fixedURL = [nextURL substringWithRange:substringRange];
        
        [self.waitForAccountsToFinishProcesssing unlock];
        //Recursive call
        [self doFriendRequestHelper :fixedURL :accumulator];
        
        
    }];

}


@end

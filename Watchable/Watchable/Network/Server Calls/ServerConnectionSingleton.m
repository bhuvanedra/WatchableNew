//
//  ServerConnectionSingleton.m
//  Watchable
//
//  Created by Raja Indirajith on 20/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "ServerConnectionSingleton.h"
#import "Utilities.h"
#import "WatchableConstants.h"
#import "JSONParser.h"
#import "Reachability.h"
#import "ChannelModel.h"
#import "VideoModel.h"
#import "SearchResultModel.h"
#import "DBHandler.h"
#import "AnalyticsEventsHandler.h"
#import "PlaylistModel.h"

@interface ServerConnectionSingleton ()
@property (nonatomic, strong) __block NSURLSessionDataTask *mSearchdataTask;
@property (nonatomic, strong) __block NSURLSessionDataTask *mBitlyShortURLdataTask;
@end
@implementation ServerConnectionSingleton

+ (ServerConnectionSingleton *)sharedInstance
{
    static ServerConnectionSingleton *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[ServerConnectionSingleton alloc] init];
      // mReachability=[[Reachability alloc]init];
    });
    return sharedInstance;
}

#pragma mark Get Session Token
- (void)sendRequestToGetSessionTokenFromServer:(BOOL)shouldFetchFromServer WithresponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    NetworkStatus aNetworkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (aNetworkStatus == NotReachable)
    {
        NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kErrorCodeNotReachable userInfo:[NSDictionary dictionaryWithObject:@"Internet connection appears to be offline." forKey:NSLocalizedDescriptionKey]];

        inErrorBlock(aError);

        return;
    }

    if (!shouldFetchFromServer)
    {
        BOOL isValidToken = [self isSessionTokenValid];
        if (isValidToken)
        {
            inResponseBlock(nil);
            return;
        }
    }
    NSLog(@"Send request for session token");
    NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kSecureZincBaseURL, kURLAuthenticationPathTemplate];
    NSURL *url = [NSURL URLWithString:aURLStr];
    NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
    [aRequest setHTTPMethod:@"POST"];
    [aRequest addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
    NSString *aBodyStr = kSecretKey;
    [aRequest setHTTPBody:[aBodyStr dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLSession *session = [self createSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                  NSLog(@"response=%@", response);
                                                  NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                 encoding:NSUTF8StringEncoding];
                                                  NSLog(@"aResponsestr=%@", aResponsestr);
                                                  NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                  if (aServerResponse.statusCode != 200)
                                                  {
                                                      if (aServerResponse.statusCode != 204)
                                                      {
                                                          [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                      }
                                                  }

                                                  NSLog(@"aServerResponse.code=%d", (int)aServerResponse.statusCode);
                                                  NSLog(@"error=%@", error);
                                                  if (error)
                                                  {
                                                      if (response)
                                                      {
                                                          [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                      }
                                                      inErrorBlock(error);
                                                  }
                                                  else
                                                  {
                                                      NSDictionary *aResponseHeader = [((NSHTTPURLResponse *)response)allHeaderFields];
                                                      NSString *aSessionToken = [aResponseHeader objectForKey:kSessionTokenKey];
                                                      if (aSessionToken.length)
                                                      {
                                                          [Utilities setValueForKeyInUserDefaults:aSessionToken key:kSessionTokenKey];
                                                          [Utilities setValueForKeyInUserDefaults:[NSDate date] key:kSessionTokenSavedDate];
                                                          NSLog(@"SessionToken=%@", aSessionToken);
                                                          inResponseBlock(aResponseHeader);
                                                      }
                                                      else
                                                      {
                                                          NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];
                                                          inErrorBlock(aError);
                                                      }
                                                  }

                                                }];
    [dataTask resume];
}

- (void)getNewAuthorizationOrSessionTokenWithSelectorForSuccess:(SEL)aSelector withParameter:(NSArray *)aParameterArray isForAuthorization:(BOOL)isAuthorisation
{
    // on success
    if (isAuthorisation)
    {
        [[ServerConnectionSingleton sharedInstance] sendRequestToGetUserProfile:nil
            withResponseBlock:^(NSDictionary *responseDict) {

              [self invokeMethod:aSelector withParameter:aParameterArray];

            }
            errorBlock:^(NSError *error) {

            }
            withVimondCookie:YES];
    }
    else
    {
        [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:YES
                                                                         WithresponseBlock:^(NSDictionary *responseDict) {

                                                                           [self invokeMethod:aSelector withParameter:aParameterArray];

                                                                         }
                                                                                errorBlock:^(NSError *error){

                                                                                }];
    }
}

#pragma mark Login
- (void)sendRequestToAuthenticateUserCrediential:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kSecureZincBaseURL, kLoginURI];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"POST"];
          [aRequest addValue:@"text/plain,application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];
          NSString *aDeviceId = [Utilities getValueFromUserDefaultsForKey:kDeviceId];
          [aRequest addValue:aDeviceId forHTTPHeaderField:kFabricDeviceIdKey];
          NSString *aSessionToken = [Utilities getValueFromUserDefaultsForKey:kSessionTokenKey];
          [aRequest addValue:aSessionToken forHTTPHeaderField:@"SessionToken"];
          NSLog(@"aDict=%@", aDict);
          [aRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:aDict options:kNilOptions error:nil]];

          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }

                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSMutableDictionary *aResponseDict = [[NSMutableDictionary alloc] init];

                                                            if (aServerResponse.statusCode == 200)
                                                            {
                                                                // NSError *aError = nil;
                                                                //id jsonResponse = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableLeaves error: &aError];
                                                                [aResponseDict setValue:[NSNumber numberWithBool:YES] forKey:@"isLoginSuccess"];
                                                                [Utilities setValueForKeyInUserDefaults:aDict key:kUserCredentialBody];
                                                                [aResponseDict setValue:[aDict objectForKey:@"username"] forKey:@"LoginUserNameOrEmailKey"];
                                                                [aResponseDict setValue:[[aServerResponse allHeaderFields] valueForKey:@"Vimond-Cookie"] forKey:@"Vimond-Cookie"];
                                                                [aResponseDict setValue:[[aServerResponse allHeaderFields] valueForKey:kAuthorizationKey] forKey:kAuthorizationKey];
                                                            }
                                                            else if (aServerResponse.statusCode == 0)
                                                            {
                                                                [aResponseDict setValue:[NSNumber numberWithBool:NO] forKey:@"isLoginSuccess"];
                                                                [aResponseDict setValue:@"The username/email or password you entered are not valid" forKey:@"Errormessage"];
                                                            }
                                                            else if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];
                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSDictionary", @"type", aDict, @"data", nil];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToAuthenticateUserCrediential:withResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }

                                                                [aResponseDict setValue:[NSNumber numberWithBool:NO] forKey:@"isLoginSuccess"];
                                                                [aResponseDict setValue:@"The username/email or password is incorrect. Please try again." forKey:@"Errormessage"];
                                                            }
                                                            else
                                                            {
                                                                //                     [aResponseDict setValue:[NSNumber numberWithBool:NO] forKey:@"isLoginSuccess"];
                                                                //                    [aResponseDict setValue:@"Server error, Please try again" forKey:@"Errormessage"];

                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];

                                                                inErrorBlock(aError);
                                                                return;
                                                            }

                                                            inResponseBlock(aResponseDict);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark LogOut
- (void)sendRequestToLogOutwithResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kLogoutURI];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"DELETE"];
          [aRequest addValue:@"text/plain,application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kAuthorizationKey] forHTTPHeaderField:kAuthorizationKey];

          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSMutableDictionary *aResponseDict = [[NSMutableDictionary alloc] init];
                                                            if (aServerResponse.statusCode == 200 || aServerResponse.statusCode == 204)
                                                            {
                                                                [aResponseDict setValue:[NSNumber numberWithBool:YES] forKey:@"isLogoutSuccess"];
                                                            }
                                                            /*else if (aServerResponse.statusCode == 0)
                {
                    [aResponseDict setValue:[NSNumber numberWithBool:NO] forKey:@"isLogoutSuccess"];
                    
                }*/
                                                            else if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToLogOutwithResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                                else
                                                                {
                                                                    //                     [aResponseDict setValue:[NSNumber numberWithBool:NO] forKey:@"isLoginSuccess"];
                                                                    //                    [aResponseDict setValue:@"Server error, Please try again" forKey:@"Errormessage"];

                                                                    NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];

                                                                    inErrorBlock(aError);
                                                                    return;
                                                                }
                                                            }
                                                            else
                                                            {
                                                                //                     [aResponseDict setValue:[NSNumber numberWithBool:NO] forKey:@"isLoginSuccess"];
                                                                //                    [aResponseDict setValue:@"Server error, Please try again" forKey:@"Errormessage"];

                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];

                                                                inErrorBlock(aError);
                                                                return;
                                                            }

                                                            inResponseBlock(aResponseDict);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark Sign up
- (void)sendRequestToSignUpNewUser:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kSecureZincBaseURL, kSignUpURI];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"POST"];
          [aRequest addValue:@"text/plain,application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"Accept"];
          NSString *aSessionToken = [Utilities getValueFromUserDefaultsForKey:kSessionTokenKey];
          [aRequest addValue:aSessionToken forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSLog(@"aDict=%@", aDict);
          [aRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:aDict options:kNilOptions error:nil]];

          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aResponse.statusCode != 200)
                                                            {
                                                                if (aResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            //NSError *aError=nil;
                                                            //                NSString*aResponsestr=   [[NSString alloc] initWithData:data
                                                            //                                                               encoding:NSUTF8StringEncoding];
                                                            //                NSLog(@"aResponsestr=%@",aResponsestr);

                                                            if (aResponse.statusCode == 204)
                                                            {
                                                                NSDictionary *aSuccessDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"Success", nil];
                                                                inResponseBlock(aSuccessDict);
                                                            }
                                                            else if (aResponse.statusCode == 400)
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kUserNameEmailUnavailableErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Username/Email is unavailable" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                            else
                                                            {
                                                                if (aResponse.statusCode == 401)
                                                                {
                                                                    NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                                   encoding:NSUTF8StringEncoding];
                                                                    NSLog(@"aResponsestr=%@", aResponsestr);

                                                                    if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                    {
                                                                        NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];
                                                                        NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSDictionary", @"type", aDict, @"data", nil];

                                                                        NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                        NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                        [aParameterArray addObject:aRequestDataDict];
                                                                        [aParameterArray addObject:aSuccessDataDict];
                                                                        [aParameterArray addObject:aErrorDataDict];

                                                                        //AUTHORIZATION TOKEN INVALID
                                                                        [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToSignUpNewUser:withResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                        return;
                                                                    }
                                                                }

                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark Get user Profile
- (void)sendRequestToGetUserProfile:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock withVimondCookie:(BOOL)isVimondCookieNeed
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kSecureZincBaseURL, kSignUpURI];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"text/plain,application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"Accept"];
          NSString *aSessionToken = [Utilities getValueFromUserDefaultsForKey:kSessionTokenKey];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          [aRequest addValue:aSessionToken forHTTPHeaderField:@"SessionToken"];

          if (isVimondCookieNeed)
          {
              NSString *aVimondCookie = [Utilities getValueFromUserDefaultsForKey:@"Vimond-Cookie"];
              [aRequest addValue:aVimondCookie forHTTPHeaderField:@"Vimond-Cookie"];
          }
          else
          {
              NSString *aAuthorizationToken = [Utilities getValueFromUserDefaultsForKey:kAuthorizationKey];
              [aRequest addValue:aAuthorizationToken forHTTPHeaderField:@"Authorization"];
          }
          NSLog(@"aDict=%@", aDict);

          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aResponse.statusCode != 200)
                                                            {
                                                                if (aResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSError *aError = nil;

                                                            if (aResponse.statusCode == 200)
                                                            {
                                                                [Utilities setValueForKeyInUserDefaults:[[aResponse allHeaderFields] valueForKey:kAuthorizationKey] key:kAuthorizationKey];

                                                                id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                                if ([jsonResponse isKindOfClass:[NSDictionary class]])
                                                                {
                                                                    NSDictionary *aResponseDict = (NSDictionary *)jsonResponse;
                                                                    inResponseBlock(aResponseDict);
                                                                }
                                                                else
                                                                {
                                                                    NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:93 userInfo:[NSDictionary dictionaryWithObject:@"Invalid response" forKey:NSLocalizedDescriptionKey]];
                                                                    inErrorBlock(aError);
                                                                }
                                                            }
                                                            else if (aResponse.statusCode == 400)
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:93 userInfo:[NSDictionary dictionaryWithObject:@"Username/Email is unavailable" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                            else
                                                            {
                                                                if (aResponse.statusCode == 401)
                                                                {
                                                                    NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                                   encoding:NSUTF8StringEncoding];
                                                                    NSLog(@"aResponsestr=%@", aResponsestr);

                                                                    if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                    {
                                                                        NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];
                                                                        NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSDictionary", @"type", aDict, @"data", nil];

                                                                        NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                        NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                        NSDictionary *aisVimondCookieNeedDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSNumber", @"type", [NSNumber numberWithBool:isVimondCookieNeed], @"data", nil];

                                                                        [aParameterArray addObject:aRequestDataDict];
                                                                        [aParameterArray addObject:aSuccessDataDict];
                                                                        [aParameterArray addObject:aErrorDataDict];
                                                                        [aParameterArray addObject:aisVimondCookieNeedDict];

                                                                        //AUTHORIZATION TOKEN INVALID
                                                                        [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetUserProfile:withResponseBlock:errorBlock:withVimondCookie:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                        return;
                                                                    }
                                                                }

                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:93 userInfo:[NSDictionary dictionaryWithObject:@"A server error occurred, please try again" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark Update Profile
- (void)sendRequestToUpdateUserProfile:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kSecureZincBaseURL, kSignUpURI];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"PUT"];
          [aRequest addValue:@"text/plain,application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"Accept"];
          NSString *aSessionToken = [Utilities getValueFromUserDefaultsForKey:kSessionTokenKey];
          [aRequest addValue:aSessionToken forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSString *aAuthorizationToken = [Utilities getValueFromUserDefaultsForKey:kAuthorizationKey];
          [aRequest addValue:aAuthorizationToken forHTTPHeaderField:@"Authorization"];

          NSLog(@"aDict=%@", aDict);
          [aRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:aDict options:kNilOptions error:nil]];

          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aResponse.statusCode != 200)
                                                            {
                                                                if (aResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            //NSError *aError=nil;
                                                            //                NSString*aResponsestr=   [[NSString alloc] initWithData:data
                                                            //                                                               encoding:NSUTF8StringEncoding];
                                                            //                NSLog(@"aResponsestr=%@",aResponsestr);

                                                            if (aResponse.statusCode == 204 || aResponse.statusCode == 200)
                                                            {
                                                                NSArray *aKeyArray = [aDict allKeys];
                                                                BOOL shouldConfirmEmailSend = NO;
                                                                if ([aKeyArray containsObject:@"email"])
                                                                {
                                                                    shouldConfirmEmailSend = YES;
                                                                }
                                                                NSDictionary *aSuccessDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"Success", [NSNumber numberWithBool:shouldConfirmEmailSend], @"shouldConfirmEmailSend", nil];
                                                                inResponseBlock(aSuccessDict);
                                                            }
                                                            else if (aResponse.statusCode == 400)
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kUserNameEmailUnavailableErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Username/Email is unavailable" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                            else if (aResponse.statusCode == 409)
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kWrongOldPassword userInfo:[NSDictionary dictionaryWithObject:@"Old password is wrong" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                            else
                                                            {
                                                                if (aResponse.statusCode == 401)
                                                                {
                                                                    NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                                   encoding:NSUTF8StringEncoding];
                                                                    NSLog(@"aResponsestr=%@", aResponsestr);

                                                                    if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                    {
                                                                        NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];
                                                                        NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSDictionary", @"type", aDict, @"data", nil];

                                                                        NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                        NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                        [aParameterArray addObject:aRequestDataDict];
                                                                        [aParameterArray addObject:aSuccessDataDict];
                                                                        [aParameterArray addObject:aErrorDataDict];

                                                                        //AUTHORIZATION TOKEN INVALID
                                                                        [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToUpdateUserProfile:withResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                        return;
                                                                    }
                                                                }

                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again." forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark Password Reset/forgot Password
- (void)sendRequestToSendConfirmEmail:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aEmailStr = [aDict objectForKey:@"email"];
          NSString *aEncodedEmailStr = [self encodeToPercentEscapeString:aEmailStr];
          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kResendConfirmEmailURL(aEncodedEmailStr)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"PUT"];
          NSString *aSessionToken = [Utilities getValueFromUserDefaultsForKey:kSessionTokenKey];
          [aRequest addValue:aSessionToken forHTTPHeaderField:@"SessionToken"];
          NSString *aAuthorizationToken = [Utilities getValueFromUserDefaultsForKey:kAuthorizationKey];
          [aRequest addValue:aAuthorizationToken forHTTPHeaderField:@"Authorization"];
          [aRequest addValue:@"ABCDEF" forHTTPHeaderField:@"code"];

          NSLog(@"aDict=%@", aDict);
          //        [aRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:aDict options:kNilOptions error:nil]];

          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aResponse.statusCode != 200)
                                                            {
                                                                if (aResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aResponse.statusCode == 204 || aResponse.statusCode == 200)
                                                            {
                                                                NSDictionary *aSuccessDict = [NSDictionary dictionaryWithObjectsAndKeys:[aDict objectForKey:@"email"], @"email", nil];
                                                                inResponseBlock(aSuccessDict);
                                                            }
                                                            else if (aResponse.statusCode == 400 || aResponse.statusCode == 404)
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kUserNameEmailUnavailableErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Account not found" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                            else
                                                            {
                                                                if (aResponse.statusCode == 401)
                                                                {
                                                                    NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                                   encoding:NSUTF8StringEncoding];
                                                                    NSLog(@"aResponsestr=%@", aResponsestr);

                                                                    if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                    {
                                                                        NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];
                                                                        NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSDictionary", @"type", aDict, @"data", nil];

                                                                        NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                        NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                        [aParameterArray addObject:aRequestDataDict];
                                                                        [aParameterArray addObject:aSuccessDataDict];
                                                                        [aParameterArray addObject:aErrorDataDict];

                                                                        //AUTHORIZATION TOKEN INVALID
                                                                        [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToSendConfirmEmail:withResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                        return;
                                                                    }
                                                                }

                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestToGetPasswordResetLinkForEmailId:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kForgotPasswordPathTemplateForEmail];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"PUT"];
          [aRequest addValue:@"text/plain,application/json" forHTTPHeaderField:@"Content-Type"];
          NSString *aSessionToken = [Utilities getValueFromUserDefaultsForKey:kSessionTokenKey];
          [aRequest addValue:aSessionToken forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSLog(@"aDict=%@", aDict);
          [aRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:aDict options:kNilOptions error:nil]];

          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aResponse.statusCode != 200)
                                                            {
                                                                if (aResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aResponse.statusCode == 204)
                                                            {
                                                                NSDictionary *aSuccessDict = [NSDictionary dictionaryWithObjectsAndKeys:[aDict objectForKey:@"email"], @"email", nil];
                                                                inResponseBlock(aSuccessDict);
                                                            }
                                                            else if (aResponse.statusCode == 400 || aResponse.statusCode == 404)
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kUserNameEmailUnavailableErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Account not found" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                            else
                                                            {
                                                                if (aResponse.statusCode == 401)
                                                                {
                                                                    NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                                   encoding:NSUTF8StringEncoding];
                                                                    NSLog(@"aResponsestr=%@", aResponsestr);

                                                                    if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                    {
                                                                        NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];
                                                                        NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSDictionary", @"type", aDict, @"data", nil];

                                                                        NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                        NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                        [aParameterArray addObject:aRequestDataDict];
                                                                        [aParameterArray addObject:aSuccessDataDict];
                                                                        [aParameterArray addObject:aErrorDataDict];

                                                                        //AUTHORIZATION TOKEN INVALID
                                                                        [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetPasswordResetLinkForEmailId:withResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                        return;
                                                                    }
                                                                }

                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestToGetPasswordResetLinkForUsername:(NSDictionary *)aDict withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kForgotPasswordPathTemplateForUsername];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"PUT"];
          [aRequest addValue:@"text/plain,application/json" forHTTPHeaderField:@"Content-Type"];
          NSString *aSessionToken = [Utilities getValueFromUserDefaultsForKey:kSessionTokenKey];
          [aRequest addValue:aSessionToken forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSLog(@"aDict=%@", aDict);
          [aRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:aDict options:kNilOptions error:nil]];

          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aResponse.statusCode != 200)
                                                            {
                                                                if (aResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aResponse.statusCode == 200)
                                                            {
                                                                NSString *aaResponsestr = [[NSString alloc] initWithData:data
                                                                                                                encoding:NSUTF8StringEncoding];
                                                                if (aaResponsestr.length)
                                                                {
                                                                    NSDictionary *aSuccessDict = [NSDictionary dictionaryWithObjectsAndKeys:aaResponsestr, @"email", nil];
                                                                    inResponseBlock(aSuccessDict);
                                                                }
                                                                else
                                                                {
                                                                    NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:93 userInfo:[NSDictionary dictionaryWithObject:@"Account not found" forKey:NSLocalizedDescriptionKey]];
                                                                    inErrorBlock(aError);
                                                                }
                                                            }
                                                            else if (aResponse.statusCode == 400 || aResponse.statusCode == 404)
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kUserNameEmailUnavailableErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Sorry, there is no account for this username or email" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                            else
                                                            {
                                                                if (aResponse.statusCode == 401)
                                                                {
                                                                    NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                                   encoding:NSUTF8StringEncoding];
                                                                    NSLog(@"aResponsestr=%@", aResponsestr);

                                                                    if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                    {
                                                                        NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];
                                                                        NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSDictionary", @"type", aDict, @"data", nil];

                                                                        NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                        NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                        [aParameterArray addObject:aRequestDataDict];
                                                                        [aParameterArray addObject:aSuccessDataDict];
                                                                        [aParameterArray addObject:aErrorDataDict];

                                                                        //AUTHORIZATION TOKEN INVALID
                                                                        [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetPasswordResetLinkForUsername:withResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                        return;
                                                                    }
                                                                }

                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}
- (void)sendRequestToValidateSignUpUserName:(NSString *)aUserName withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kValidateSignUpUsername(aUserName)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          //        [aRequest setHTTPMethod:@"POST"];
          //        [aRequest addValue:@"text/plain,application/json" forHTTPHeaderField:@"Content-Type"];
          //        [aRequest addValue:@"application/json,application/xml" forHTTPHeaderField:@"Accept"];
          NSString *aSessionToken = [Utilities getValueFromUserDefaultsForKey:kSessionTokenKey];
          [aRequest addValue:aSessionToken forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aResponse.statusCode != 200)
                                                            {
                                                                if (aResponse.statusCode != 404)
                                                                {
                                                                    if (aResponse.statusCode != 204)
                                                                    {
                                                                        [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aResponse.statusCode == 404)
                                                            {
                                                                NSDictionary *aSuccessDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"Success", nil];
                                                                inResponseBlock(aSuccessDict);
                                                            }
                                                            else if (aResponse.statusCode == 204)
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:91 userInfo:[NSDictionary dictionaryWithObject:@"Username already in use" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                            else
                                                            {
                                                                if (aResponse.statusCode == 401)
                                                                {
                                                                    NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                                   encoding:NSUTF8StringEncoding];
                                                                    NSLog(@"aResponsestr=%@", aResponsestr);

                                                                    if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                    {
                                                                        NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];
                                                                        NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", aUserName, @"data", nil];

                                                                        NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                        NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                        [aParameterArray addObject:aRequestDataDict];
                                                                        [aParameterArray addObject:aSuccessDataDict];
                                                                        [aParameterArray addObject:aErrorDataDict];

                                                                        //AUTHORIZATION TOKEN INVALID
                                                                        [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToValidateSignUpUserName:withResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                        return;
                                                                    }
                                                                }

                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:92 userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try later" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestToValidateSignUpEmailId:(NSString *)aEmailId withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kValidateSignUpEmailId(aEmailId)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          //        [aRequest setHTTPMethod:@"POST"];
          //        [aRequest addValue:@"text/plain,application/json" forHTTPHeaderField:@"Content-Type"];
          //        [aRequest addValue:@"application/json,application/xml" forHTTPHeaderField:@"Accept"];
          NSString *aSessionToken = [Utilities getValueFromUserDefaultsForKey:kSessionTokenKey];
          [aRequest addValue:aSessionToken forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aResponse.statusCode != 200)
                                                            {
                                                                if (aResponse.statusCode != 404)
                                                                {
                                                                    if (aResponse.statusCode != 204)
                                                                    {
                                                                        [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aResponse.statusCode == 404)
                                                            {
                                                                NSDictionary *aSuccessDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"Success", nil];
                                                                inResponseBlock(aSuccessDict);
                                                            }
                                                            else if (aResponse.statusCode == 204)
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:91 userInfo:[NSDictionary dictionaryWithObject:@"Email address already in use" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                            else
                                                            {
                                                                if (aResponse.statusCode == 401)
                                                                {
                                                                    NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                                   encoding:NSUTF8StringEncoding];
                                                                    NSLog(@"aResponsestr=%@", aResponsestr);

                                                                    if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                    {
                                                                        NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];
                                                                        NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", aEmailId, @"data", nil];

                                                                        NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                        NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                        [aParameterArray addObject:aRequestDataDict];
                                                                        [aParameterArray addObject:aSuccessDataDict];
                                                                        [aParameterArray addObject:aErrorDataDict];

                                                                        //AUTHORIZATION TOKEN INVALID
                                                                        [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToValidateSignUpEmailId:withResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                        return;
                                                                    }
                                                                }

                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server Error. Please try later." forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark Get PlayList
- (void)sendRequestToGetPlayListresponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kURLPlayListPathTemplate];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];

          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSLog(@"playlist errror=%@", error);
                                                        NSHTTPURLResponse *aSerResponse = (NSHTTPURLResponse *)response;
                                                        NSLog(@"a response code=%ld", aSerResponse.statusCode);
                                                        if (response)
                                                        {
                                                            if (aSerResponse.statusCode != 200)
                                                            {
                                                                if (aSerResponse.statusCode != 204)
                                                                {
                                                                    if (aSerResponse.statusCode != 404)
                                                                    {
                                                                        [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aSerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aSerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        NSError *Error = nil;
                                                        id aSResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&Error];

                                                        NSLog(@"a response=%@", aSResponse);
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aSerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSError *aError = nil;
                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                            if (aError)
                                                            {
                                                                inErrorBlock(error);
                                                            }
                                                            else
                                                            {
                                                                NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;

                                                                if (aServerResponse.statusCode == 401)
                                                                {
                                                                    NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                                   encoding:NSUTF8StringEncoding];
                                                                    NSLog(@"aResponsestr=%@", aResponsestr);

                                                                    if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                    {
                                                                        NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                        NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerPlaylistResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                        NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                        [aParameterArray addObject:aSuccessDataDict];
                                                                        [aParameterArray addObject:aErrorDataDict];

                                                                        //AUTHORIZATION TOKEN INVALID
                                                                        [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetPlayListresponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                        return;
                                                                    }
                                                                }

                                                                if (aSerResponse.statusCode == 404)
                                                                {
                                                                    inResponseBlock(nil);
                                                                    return;
                                                                }

                                                                NSArray *aResponseArray = [JSONParser parseDataForCuratedPlayList:aResponse];
                                                                inResponseBlock(aResponseArray);
                                                            }
                                                        }

                                                      }];
          [dataTask resume];
        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark Get MyShows
- (void)sendRequestToGetMyShowListresponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          //        [self getNewBearerTokenForUser:(NSDictionary*)[Utilities getValueFromUserDefaultsForKey:kUserCredentialBody]];
          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kURLMyShowsListPathTemplate];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kAuthorizationKey] forHTTPHeaderField:@"Authorization"];

          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;

                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    if (aServerResponse.statusCode != 404)
                                                                        [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerPlaylistResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetMyShowListresponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }
                                                            else if (aServerResponse.statusCode == 404)
                                                            {
                                                                inResponseBlock(nil);
                                                                return;
                                                            }
                                                            NSError *aError = nil;

                                                            //                NSString*aResponsestr=   [[NSString alloc] initWithData:data
                                                            //                                                               encoding:NSUTF8StringEncoding];

                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                            if (aError)
                                                            {
                                                                inErrorBlock(error);
                                                            }
                                                            else
                                                            {
                                                                NSArray *aResponseArray = [JSONParser parseDataForChannels:aResponse];

                                                                inResponseBlock(aResponseArray);
                                                            }
                                                        }
                                                      }];

          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark Get MyHistory List
- (void)sendRequestToGetMyHistoryListresponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kUserHistoryVideoListURL];
          NSURL *url = [NSURL URLWithString:aURLStr];

          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];
          NSLog(@"SESSIONtOKEN=%@", [Utilities getValueFromUserDefaultsForKey:kSessionTokenKey]);
          NSLog(@"atOKEN=%@", [Utilities getValueFromUserDefaultsForKey:kAuthorizationKey]);
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kAuthorizationKey] forHTTPHeaderField:@"Authorization"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];

          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    if (aServerResponse.statusCode != 404)
                                                                    {
                                                                        [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSError *aError = nil;
                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                            if (aError)
                                                            {
                                                                inErrorBlock(error);
                                                            }
                                                            else
                                                            {
                                                                if (aServerResponse.statusCode == 200)
                                                                {
                                                                    NSArray *aResponseArray = [JSONParser parseDataForHistoryMetaData:aResponse];
                                                                    [[DBHandler sharedInstance] createHistoryEntityForLoggedInUser:aResponseArray];
                                                                    NSArray *aHistoryModelArray = [[DBHandler sharedInstance] getAllHistoryModelsForLoggedInUser];
                                                                    inResponseBlock(aHistoryModelArray);
                                                                    return;
                                                                }
                                                                else if (aServerResponse.statusCode == 401)
                                                                {
                                                                    NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                                   encoding:NSUTF8StringEncoding];
                                                                    NSLog(@"aResponsestr=%@", aResponsestr);

                                                                    if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                    {
                                                                        NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                        NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerPlaylistResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                        NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                        [aParameterArray addObject:aSuccessDataDict];
                                                                        [aParameterArray addObject:aErrorDataDict];

                                                                        //AUTHORIZATION TOKEN INVALID
                                                                        [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetMyHistoryListresponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                        return;
                                                                    }
                                                                }

                                                                if (aServerResponse.statusCode == 404)
                                                                {
                                                                    [[DBHandler sharedInstance] createHistoryEntityForLoggedInUser:nil];
                                                                    NSArray *aHistoryModelArray = [[DBHandler sharedInstance] getAllHistoryModelsForLoggedInUser];
                                                                    inResponseBlock(aHistoryModelArray);
                                                                    return;
                                                                }

                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try later" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestToDeleteMyHistoryListresponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kDeleteUserHistoryVideoListURL];
          NSURL *url = [NSURL URLWithString:aURLStr];

          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"DELETE"];
          //       [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          //        [aRequest addValue:@"application/json" forHTTPHeaderField:@"accept"];
          //        NSLog(@"SESSIONtOKEN=%@",[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey]);
          //        NSLog(@"atOKEN=%@",[Utilities getValueFromUserDefaultsForKey:kAuthorizationKey]);
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kAuthorizationKey] forHTTPHeaderField:@"Authorization"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                           encoding:NSUTF8StringEncoding];
                                                            NSLog(@"aResponsestr=%@", aResponsestr);

                                                            if (aServerResponse.statusCode == 200 || aServerResponse.statusCode == 204)
                                                            {
                                                                inResponseBlock(nil);
                                                                return;
                                                            }
                                                            else if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToDeleteMyHistoryListresponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try later" forKey:NSLocalizedDescriptionKey]];
                                                            inErrorBlock(aError);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestToDeleteMyHistoryVideoId:(NSString *)aVideoId responseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kDeleteUserHistoryVideoIdURL(aVideoId)];
          NSURL *url = [NSURL URLWithString:aURLStr];

          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"DELETE"];
          //[aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          // [aRequest addValue:@"application/json" forHTTPHeaderField:@"accept"];
          NSLog(@"SESSIONtOKEN=%@", [Utilities getValueFromUserDefaultsForKey:kSessionTokenKey]);
          NSLog(@"atOKEN=%@", [Utilities getValueFromUserDefaultsForKey:kAuthorizationKey]);
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kAuthorizationKey] forHTTPHeaderField:@"Authorization"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                           encoding:NSUTF8StringEncoding];
                                                            NSLog(@"aResponsestr=%@", aResponsestr);

                                                            if (aServerResponse.statusCode == 200 || aServerResponse.statusCode == 204)
                                                            {
                                                                inResponseBlock(nil);
                                                                return;
                                                            }
                                                            else if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", aVideoId, @"data", nil];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToDeleteMyHistoryVideoId:responseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try later" forKey:NSLocalizedDescriptionKey]];
                                                            inErrorBlock(aError);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark Get Genre For channel
/*-(void)sendRequestToGetChannelresponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock forGenreId:(NSString*)genreID withPageNumber:(NSString*)aPageNo
 {
 [[ServerConnectionSingleton sharedInstance]sendRequestToGetSessionTokenFromServer:NO WithresponseBlock:^(NSDictionary *responseDict) {
 NSString *aPageQuery=[NSString stringWithFormat:@"?pageNum=%@&pageSize=%@",aPageNo,kNumberOfAssetsToFetch];
 NSString *aURLStr=[NSString stringWithFormat:@"%@%@%@",kZincBaseURL,genreID,aPageQuery];
 NSURL *url =[NSURL URLWithString:aURLStr];
 NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
 [aRequest setHTTPMethod:@"GET"];
 [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
 [aRequest addValue:@"application/json" forHTTPHeaderField:@"accept"];
 
 [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
 [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
 NSURLSession *session = [self createSession];
 NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
 
 NSHTTPURLResponse *aServerResponse=(NSHTTPURLResponse*)response;
 if (aServerResponse.statusCode != 200 ) {
 
 if (aServerResponse.statusCode != 204) {
 
 [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d",(int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString*)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
 }
 
 }
 if(error)
 {
 [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d",(int)error.code] offendingUrl:aURLStr andUUID:(NSString*)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
 inErrorBlock(error);
 }
 else
 {
 NSError *aError=nil;
 
 if (aServerResponse.statusCode == 401)
 {
 NSString*aResponsestr=   [[NSString alloc] initWithData:data
 encoding:NSUTF8StringEncoding];
 NSLog(@"aResponsestr=%@",aResponsestr);
 
 if([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame )
 {
 NSMutableArray *aParameterArray=[[NSMutableArray alloc]init];
 
 NSDictionary *aSuccessDataDict=[NSDictionary dictionaryWithObjectsAndKeys:@"successBlock",@"parameterType",@"ServerResponseBlock",@"type",inResponseBlock,@"data", nil];
 
 NSDictionary *aErrorDataDict=[NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock",@"parameterType",@"ServerErrorBlock",@"type",inErrorBlock,@"data", nil];
 
 NSDictionary *aRequestDataDict=[NSDictionary dictionaryWithObjectsAndKeys:@"requestData",@"parameterType",@"NSString",@"type",genreID,@"data", nil];
 
 NSDictionary *aRequestDataDict1=[NSDictionary dictionaryWithObjectsAndKeys:@"requestData",@"parameterType",@"NSString",@"type",aPageNo,@"data", nil];
 
 
 [aParameterArray addObject:aSuccessDataDict];
 [aParameterArray addObject:aErrorDataDict];
 [aParameterArray addObject:aRequestDataDict];
 [aParameterArray addObject:aRequestDataDict1];
 //AUTHORIZATION TOKEN INVALID
 [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetChannelresponseBlock: errorBlock: forGenreId: withPageNumber:)  withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame)?YES:NO];
 
 return ;
 }
 }
 
 
 id aResponse = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableLeaves error: &aError];
 
 NSArray *aResponseArray= [JSONParser parseDataForChannels:aResponse];
 NSDictionary *aResponseDict=nil;
 if(aResponseArray.count)
 {
 NSDictionary *aDictionary=(NSDictionary*)aResponse;
 NSString *aTotalItemsStr=[aDictionary objectForKey:@"totalItems"];
 
 aResponseDict=[NSDictionary dictionaryWithObjectsAndKeys:aResponseArray,@"response",aTotalItemsStr,@"totalItems",aPageNo,@"pageNumber",nil];
 }
 
 inResponseBlock(aResponseDict);
 }
 
 }];
 [dataTask resume];
 
 } errorBlock:^(NSError *error) {
 
 inErrorBlock(error);
 }];
 
 
 }*/

- (void)sendRequestToGetChannelresponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock forGenreId:(NSString *)genreID
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {
          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, genreID];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          //[aRequest addValue:@"application/json" forHTTPHeaderField:@"accept"];
          [aRequest addValue:kAcceptTypeWithVersionForGenre forHTTPHeaderField:@"accept"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    if (aServerResponse.statusCode != 404)
                                                                    {
                                                                        [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSError *aError = nil;

                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", genreID, @"data", nil];

                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];
                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetChannelresponseBlock:errorBlock:forGenreId:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            if (aServerResponse.statusCode == 404)
                                                            {
                                                                inResponseBlock(nil);
                                                            }

                                                            NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                           encoding:NSUTF8StringEncoding];
                                                            NSLog(@"aResponsestr=%@", aResponsestr);

                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];

                                                            NSArray *aResponseArray = [JSONParser parseDataForChannels:aResponse];
                                                            NSDictionary *aResponseDict = nil;
                                                            if (aResponseArray.count)
                                                            {
                                                                NSDictionary *aDictionary = (NSDictionary *)aResponse;
                                                                NSString *aTotalItemsStr = [aDictionary objectForKey:@"totalItems"];

                                                                aResponseDict = [NSDictionary dictionaryWithObjectsAndKeys:aResponseArray, @"response", aTotalItemsStr, @"totalItems", nil];
                                                            }

                                                            inResponseBlock(aResponseDict);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestTogetGenreForChannel:(NSString *)genreLink WithResponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, genreLink];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", genreLink, @"data", nil];
                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerPlaylistResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestTogetGenreForChannel:WithResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            NSError *aError = nil;
                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                            NSArray *aResponseArray = [JSONParser parseDataForGenreForChannels:aResponse];
                                                            inResponseBlock(aResponseArray);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestToGetChannelForPublisherresponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock forAPiFormat:(NSString *)apiStr
{
    // NSLog(@"Raja1");
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          //NSLog(@"Raja2");
          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kURLChannelForPublisherPathTemplate(apiStr)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    if (aServerResponse.statusCode != 404)
                                                                    {
                                                                        [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerPlaylistResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", apiStr, @"data", nil];

                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];
                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetChannelForPublisherresponseBlock:errorBlock:forAPiFormat:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            if (aServerResponse.statusCode == 404)
                                                            {
                                                                inResponseBlock(nil);
                                                                return;
                                                            }

                                                            NSError *aError = nil;
                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                            NSArray *aResponseArray = [JSONParser parseDataForChannels:aResponse];
                                                            inResponseBlock(aResponseArray);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestToGetPublisherresponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock forAPiFormat:(NSString *)apiStr
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kURLPublisherPathTemplate(apiStr)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerPlaylistResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", apiStr, @"data", nil];

                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];
                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetPublisherresponseBlock:errorBlock:forAPiFormat:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            NSError *aError = nil;
                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                            NSArray *aResponseArray = [JSONParser parseDataForProvider:aResponse];
                                                            inResponseBlock(aResponseArray);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestToGetChannelInfoWithURL:(NSString *)aRelativeURL responseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, aRelativeURL];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", aRelativeURL, @"data", nil];
                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerPlaylistResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetChannelInfoWithURL:responseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            NSError *aError = nil;
                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];

                                                            if ([aResponse isKindOfClass:[NSDictionary class]])
                                                            {
                                                                NSDictionary *aDict = (NSDictionary *)aResponse;
                                                                ChannelModel *aModel = [[ChannelModel alloc] initWithJSONData:aDict];
                                                                NSArray *aResponseArray = [NSArray arrayWithObject:aModel];
                                                                inResponseBlock(aResponseArray);
                                                            }
                                                            else
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:93 userInfo:[NSDictionary dictionaryWithObject:@"Unable to fetch channel info from server." forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                            }
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark Get Videos For Show ID

//TODO:Not in use, need to be removed.
- (void)sendRequestToGetVideoForShowId:(NSString *)aShowId responseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kBaseURL, kURLVideoForShowIdPathTemplate(aShowId)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", aShowId, @"data", nil];
                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerPlaylistResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetVideoForShowId:responseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            NSError *aError = nil;
                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                            NSArray *aResponseArray = [JSONParser parseDataForVideoList:aResponse];
                                                            inResponseBlock(aResponseArray);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

//

#pragma mark Get Videos For Playlists

- (void)sendRequestToGetVideoForPlaylist:(NSString *)videoListUrl withPlayListUniqueId:(NSString *)aPlayListUniqueId responseBlock:(ServerPlaylistResponseBlock)inResponseBlock withPlayListModelResponseBlock:(ServerResponseBlockForGetPlayListModel)inPlayListModelResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, videoListUrl];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    if (aServerResponse.statusCode != 404)
                                                                    {
                                                                        [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;

                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", videoListUrl, @"data", nil];
                                                                    NSDictionary *aRequestDataDict2 = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", aPlayListUniqueId, @"data", nil];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerPlaylistResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aSuccessDataDict2 = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlockForGetPlayListModel", @"type", inPlayListModelResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aRequestDataDict2];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict2];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetVideoForPlaylist:withPlayListUniqueId:responseBlock:withPlayListModelResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }
                                                            if (aServerResponse.statusCode == 404)
                                                            {
                                                                //inPlayListModelResponseBlock(nil);
                                                                inResponseBlock(nil);
                                                                return;
                                                            }
                                                            NSError *aError = nil;
                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                            PlaylistModel *aPlayListModel = [[PlaylistModel alloc] init];
                                                            aPlayListModel.uniqueId = aPlayListUniqueId;

                                                            NSArray *aResponseArray = [JSONParser parseDataForVideoList:aResponse withPlayListModel:aPlayListModel];
                                                            inPlayListModelResponseBlock(aPlayListModel);
                                                            inResponseBlock(aResponseArray);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestToGetVideoForChannelId:(NSString *)aChannelId responseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kURLVideoForChannelIdPathTemplate(aChannelId)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    if (aServerResponse.statusCode != 404)
                                                                    {
                                                                        [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", aChannelId, @"data", nil];
                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerPlaylistResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetVideoForChannelId:responseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            if (aServerResponse.statusCode == 404)
                                                            {
                                                                inResponseBlock(nil);
                                                                return;
                                                            }
                                                            NSError *aError = nil;
                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                            NSArray *aResponseArray = [JSONParser parseDataForChannelVideoList:aResponse];
                                                            inResponseBlock(aResponseArray);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestToGetVideoForVideoId:(NSString *)aVideoId responseBlock:(ServerNextVideoResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kURLGetVideoInfo(aVideoId)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", aVideoId, @"data", nil];
                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerNextVideoResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetVideoForVideoId:responseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            NSError *aError = nil;
                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];

                                                            if ([aResponse isKindOfClass:[NSDictionary class]])
                                                            {
                                                                NSDictionary *aDict = (NSDictionary *)aResponse;
                                                                VideoModel *aVideoModel = [[VideoModel alloc] initVideoUnderChannelFromJsonData:aDict];
                                                                [[DBHandler sharedInstance] setVideoModelForHistoryAsset:aVideoModel];
                                                                inResponseBlock(aVideoModel);
                                                                return;
                                                            }
                                                            NSError *Error = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:93 userInfo:[NSDictionary dictionaryWithObject:@"Unable to fetch channel info from server." forKey:NSLocalizedDescriptionKey]];
                                                            inErrorBlock(Error);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestToUpdateVideoProgressTime:(NSDictionary *)aDict responseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aVideoId = [aDict objectForKey:@"videoId"];
          NSString *aProgressTime = [aDict objectForKey:@"progressTime"];

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kUpdatePlayProgressTimeForVideo(aVideoId, aProgressTime)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"PUT"];
          //        [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          //        [aRequest addValue:@"application/json" forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kAuthorizationKey] forHTTPHeaderField:@"Authorization"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aServerResponse.statusCode == 200 || aServerResponse.statusCode == 204)
                                                            {
                                                                //NSError *aError=nil;
                                                                //id aResponse = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableLeaves error: &aError];

                                                                /* if([aResponse isKindOfClass:[NSDictionary class]])
                     {
                     NSDictionary *aDict=(NSDictionary*)aResponse;
                     
                     inResponseBlock(aDict);
                     return;
                     }*/
                                                                NSMutableDictionary *aResponseDict = [NSMutableDictionary dictionaryWithDictionary:aDict];
                                                                long long aTimeInterval = (long long)[[NSDate date] timeIntervalSince1970];
                                                                NSNumber *aCurrentDateInSec = [NSNumber numberWithLongLong:aTimeInterval * 1000];
                                                                [aResponseDict setObject:aCurrentDateInSec forKey:@"lastUpdatedTime"];
                                                                inResponseBlock(aResponseDict);
                                                                return;
                                                            }

                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSDictionary", @"type", aDict, @"data", nil];
                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToUpdateVideoProgressTime:responseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            NSError *Error = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:93 userInfo:[NSDictionary dictionaryWithObject:@"Unable to fetch channel info from server." forKey:NSLocalizedDescriptionKey]];
                                                            inErrorBlock(Error);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestToUpdateVideoCount:(NSDictionary *)aDict responseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aVideoId = [aDict objectForKey:@"videoId"];
          NSDictionary *aLogData = [aDict objectForKey:@"logData"];

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kURLPostLogData(aVideoId)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"PUT"];
          [aRequest addValue:@"text/plain,application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];

          //[aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kAuthorizationKey] forHTTPHeaderField:@"Authorization"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];

          [aRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:aLogData options:kNilOptions error:nil]];

          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aServerResponse.statusCode == 200 || aServerResponse.statusCode == 204)
                                                            {
                                                                inResponseBlock(nil);
                                                                return;
                                                            }

                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSDictionary", @"type", aDict, @"data", nil];
                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToUpdateVideoCount:responseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            NSError *Error = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:93 userInfo:[NSDictionary dictionaryWithObject:@"Unable to fetch channel info from server." forKey:NSLocalizedDescriptionKey]];
                                                            inErrorBlock(Error);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestTogetGenreWithResponseBlock:(ServerPlaylistResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kURLForGenrePathTemplate];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          //[aRequest addValue:@"application/json" forHTTPHeaderField:@"accept"];
          [aRequest addValue:kAcceptTypeWithVersionForGenre forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    if (aServerResponse.statusCode != 404)
                                                                    {
                                                                        [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerPlaylistResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestTogetGenreWithResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            if (aServerResponse.statusCode == 404)
                                                            {
                                                                inResponseBlock(nil);
                                                                return;
                                                            }
                                                            NSError *aError = nil;
                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                            NSArray *aResponseArray = [JSONParser parseDataForGenre:aResponse];
                                                            inResponseBlock(aResponseArray);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestTogetFeaturedShowWithResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kURLForFeaturedShowPathTemplate];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          //[aRequest addValue:@"application/json" forHTTPHeaderField:@"accept"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    if (aServerResponse.statusCode != 404)
                                                                    {
                                                                        [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestTogetFeaturedShowWithResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            if (aServerResponse.statusCode == 404)
                                                            {
                                                                inResponseBlock(nil);
                                                                return;
                                                            }
                                                            NSError *aError = nil;
                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];

                                                            NSString *aTitle = nil;
                                                            NSArray *aResponseArray = [JSONParser parseDataForFeaturedChannels:aResponse withTitle:&aTitle];

                                                            NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:aResponseArray, @"response", aTitle, @"title", nil];
                                                            inResponseBlock(aDict);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark Get PlaybackURI for VideoID
- (void)sendRequestToGetPlaybackURIForVideoId:(NSDictionary *)aVideoInfo responseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aVideoId = [aVideoInfo objectForKey:@"videoId"];
          //          BOOL isMaxBitRate = ((NSNumber *)[aVideoInfo objectForKey:@"isMaxBitRate"]).boolValue;

          NSString *aVideoPlayBackURI = nil;
          if (/*isMaxBitRate*/ 0)
          {
              aVideoPlayBackURI = kURLGetPlayBackURIWithBitRateTemplate(aVideoId);
          }
          else
          {
              aVideoPlayBackURI = kURLGetPlayBackURITemplate(aVideoId);
          }

          NSLog(@"==============*****aVideoPlayBackURI = %@", aVideoPlayBackURI);
          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, aVideoPlayBackURI];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;

                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSDictionary", @"type", aVideoInfo, @"data", nil];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetPlaybackURIForVideoId:responseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            NSError *aError = nil;

                                                            NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                           encoding:NSUTF8StringEncoding];
                                                            NSLog(@"aResponsestr=%@", aResponsestr);

                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                            NSLog(@"Response=%@", aResponse);
                                                            if ([aResponse isKindOfClass:[NSDictionary class]])
                                                            {
                                                                NSDictionary *aDict = (NSDictionary *)aResponse;
                                                                NSString *aLogDataString = [aDict objectForKey:@"logData"];
                                                                if ([[aDict allKeys] containsObject:@"playbackItems"])
                                                                {
                                                                    NSArray *aResponseArray = [aDict objectForKey:@"playbackItems"];
                                                                    if (aResponseArray.count)
                                                                    {
                                                                        NSDictionary *aResponseDict = [aResponseArray objectAtIndex:0];
                                                                        NSMutableDictionary *ResponseDict = [[NSMutableDictionary alloc] initWithDictionary:aResponseDict];
                                                                        if (aLogDataString.length)
                                                                        {
                                                                            [ResponseDict setObject:aDict forKey:@"logData"];
                                                                        }
                                                                        inResponseBlock(ResponseDict);
                                                                        return;
                                                                    }
                                                                }
                                                            }
                                                            if (!aError)
                                                            {
                                                                aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Error in process" forKey:NSLocalizedDescriptionKey]];
                                                            }
                                                            inErrorBlock(aError);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendRequestToGetNextVideoForChannelId:(NSString *)channelId responseBlock:(ServerNextVideoResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kNextVideoUnderChannelPathTemplate(channelId)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kAuthorizationKey] forHTTPHeaderField:@"Authorization"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;

                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", channelId, @"data", nil];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerNextVideoResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetNextVideoForChannelId:responseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            NSError *aError = nil;
                                                            id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                            if (aError)
                                                            {
                                                                inErrorBlock(error);
                                                            }
                                                            else
                                                            {
                                                                VideoModel *videoModel = [JSONParser parseDataForNextVideoUnderChannel:aResponse];
                                                                inResponseBlock(videoModel);
                                                            }
                                                        }

                                                      }];
          // dataTask.priority = NSURLSessionTaskPriorityHigh;
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark Methods related to Channels subscription.

- (void)sendrequestToGetSubscriptionStatusForChannel:(NSString *)channelId withResponseBlock:(ServerChannelSubscriptionResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          //[self getNewBearerTokenForUser:(NSDictionary*)[Utilities getValueFromUserDefaultsForKey:kUserCredentialBody]];
          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kURLFollowChannelPathTemplate(channelId)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];

          [aRequest addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kAuthorizationKey] forHTTPHeaderField:@"Authorization"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 404)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;

                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", channelId, @"data", nil];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerChannelSubscriptionResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendrequestToGetSubscriptionStatusForChannel:withResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            BOOL subscribed = NO;
                                                            if (((NSHTTPURLResponse *)response).statusCode == 204)
                                                            {
                                                                subscribed = YES;
                                                            }
                                                            else if (((NSHTTPURLResponse *)response).statusCode == 404)
                                                            {
                                                                subscribed = NO;
                                                            }
                                                            else if (((NSHTTPURLResponse *)response).statusCode == 400)
                                                            {
                                                                NSLog(@"Bad Request,  can not get channel subscribe status");
                                                            }
                                                            else
                                                            {
                                                                NSLog(@"Error occured, can not get channel subscribe status");
                                                            }

                                                            inResponseBlock(subscribed);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendrequestToSubscribeChannel:(NSString *)channelId withResponseBlock:(ServerChannelSubscriptionResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          //[self getNewBearerTokenForUser:(NSDictionary*)[Utilities getValueFromUserDefaultsForKey:kUserCredentialBody]];
          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kURLFollowChannelPathTemplate(channelId)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"POST"];
          [aRequest addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kAuthorizationKey] forHTTPHeaderField:@"Authorization"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;

                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", channelId, @"data", nil];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerChannelSubscriptionResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendrequestToSubscribeChannel:withResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            BOOL subscribed = NO;
                                                            if (((NSHTTPURLResponse *)response).statusCode == 200 || ((NSHTTPURLResponse *)response).statusCode == 204)
                                                            {
                                                                subscribed = YES;
                                                                inResponseBlock(subscribed);
                                                            }
                                                            else if (((NSHTTPURLResponse *)response).statusCode == 400)
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                                NSLog(@"Bad Request, channel could not subscribe");
                                                            }
                                                            else
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                                NSLog(@"Error occured, channel could not subscribe");
                                                            }
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)sendrequestToUnSubscribeChannel:(NSString *)channelId withResponseBlock:(ServerChannelSubscriptionResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          //[self getNewBearerTokenForUser:(NSDictionary*)[Utilities getValueFromUserDefaultsForKey:kUserCredentialBody]];
          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kURLFollowChannelPathTemplate(channelId)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"DELETE"];
          [aRequest addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kAuthorizationKey] forHTTPHeaderField:@"Authorization"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;

                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", channelId, @"data", nil];

                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerChannelSubscriptionResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendrequestToUnSubscribeChannel:withResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }

                                                            BOOL subscribed = NO;
                                                            if (((NSHTTPURLResponse *)response).statusCode == 200 || ((NSHTTPURLResponse *)response).statusCode == 204)
                                                            {
                                                                subscribed = YES;
                                                                inResponseBlock(subscribed);
                                                            }
                                                            else if (((NSHTTPURLResponse *)response).statusCode == 400)
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                                NSLog(@"Bad Request, channel could not Unsubscribe");
                                                            }
                                                            else
                                                            {
                                                                NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(aError);
                                                                NSLog(@"Error occured, channel could not Unsubscribe");
                                                            }
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark Methods related to Search.
//Methods related to search

- (void)sendRequestToGetSearchResultForString:(NSString *)searchString withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          // NSString *aEncodedSearchString=[searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

          NSString *SearchTextEscaped = [self encodeToPercentEscapeString:searchString];

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kURLSearchPathTemplate(SearchTextEscaped)];

          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          [self cancelSearchServerAPICall];
          self.mSearchdataTask = [session dataTaskWithRequest:aRequest
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                              NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                              if (response)
                                              {
                                                  if (aServerResponse.statusCode != 200)
                                                  {
                                                      if (aServerResponse.statusCode != 204)
                                                      {
                                                          if (aServerResponse.statusCode != 404)
                                                          {
                                                              [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                          }
                                                      }
                                                  }
                                              }
                                              if (error)
                                              {
                                                  if (response)
                                                  {
                                                      [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                  }
                                                  if (!([error.localizedDescription caseInsensitiveCompare:@"cancelled"] == NSOrderedSame))
                                                  {
                                                      inErrorBlock(error);
                                                  }
                                              }
                                              else
                                              {
                                                  if (aServerResponse.statusCode == 404)
                                                  {
                                                      inResponseBlock(nil);
                                                      return;
                                                  }

                                                  NSError *aError = nil;
                                                  id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                  if (aError)
                                                  {
                                                      inErrorBlock(error);
                                                  }
                                                  else
                                                  {
                                                      NSDictionary *aResponseDictionary = nil;

                                                      aResponseDictionary = [JSONParser parseDataForSearchResult:aResponse];

                                                      NSMutableDictionary *aResponseDictWithSearchString = [[NSMutableDictionary alloc] init];
                                                      [aResponseDictWithSearchString setObject:searchString forKey:@"searchedStirng"];

                                                      if (aResponseDictionary)
                                                          [aResponseDictWithSearchString setObject:aResponseDictionary forKey:@"response"];

                                                      inResponseBlock(aResponseDictWithSearchString);
                                                  }
                                              }

                                            }];
          [self.mSearchdataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

- (void)cancelSearchServerAPICall
{
    if (self.mSearchdataTask)
    {
        [self.mSearchdataTask cancel];
        self.mSearchdataTask = nil;
    }
}

- (void)cancelBitlyShortURLServerAPICall
{
    if (self.mBitlyShortURLdataTask)
    {
        [self.mBitlyShortURLdataTask cancel];
        self.mBitlyShortURLdataTask = nil;
    }
}
#pragma mark -

- (BOOL)isSessionTokenValid
{
    NSDate *aDate = (NSDate *)[Utilities getValueFromUserDefaultsForKey:kSessionTokenSavedDate];
    if (aDate)
    {
        NSDate *currentDate = [NSDate date];
        double aDifference = [currentDate timeIntervalSinceDate:aDate];

        if (aDifference < kSessionTimeoutSec)
        {
            return YES;
        }
    }
    return NO;
}

- (void)invokeMethod:(SEL)aSelector withParameter:(NSArray *)aParameterArray
{
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[[ServerConnectionSingleton sharedInstance] methodSignatureForSelector:aSelector]];
    [inv setSelector:aSelector];
    [inv setTarget:[ServerConnectionSingleton sharedInstance]];

    for (int x = 0; x < aParameterArray.count; x++)
    {
        NSDictionary *aDict = [aParameterArray objectAtIndex:x];

        NSString *aParameterType = [aDict objectForKey:@"parameterType"];

        if ([aParameterType isEqualToString:@"requestData"])
        {
            if ([[aDict objectForKey:@"type"] isEqualToString:@"NSString"])
            {
                NSString *aData = (NSString *)[aDict objectForKey:@"data"];
                [inv setArgument:&aData atIndex:2 + x];
            }
            else if ([[aDict objectForKey:@"type"] isEqualToString:@"NSDictionary"])
            {
                NSDictionary *aData = (NSDictionary *)[aDict objectForKey:@"data"];
                [inv setArgument:&aData atIndex:2 + x];
            }
            else if ([[aDict objectForKey:@"type"] isEqualToString:@"NSArray"])
            {
                NSArray *aData = (NSArray *)[aDict objectForKey:@"data"];
                [inv setArgument:&aData atIndex:2 + x];
            }
            else if ([[aDict objectForKey:@"type"] isEqualToString:@"NSNumber"])
            {
                NSNumber *aNSNumber = (NSNumber *)[aDict objectForKey:@"data"];
                BOOL aBool = [aNSNumber boolValue];
                [inv setArgument:&aBool atIndex:2 + x];
            }
        }
        else if ([aParameterType isEqualToString:@"successBlock"])
        {
            if ([[aDict objectForKey:@"type"] isEqualToString:@"ServerResponseBlock"])
            {
                ServerResponseBlock aData = (ServerResponseBlock)[aDict objectForKey:@"data"];
                [inv setArgument:&aData atIndex:2 + x];
            }
            else if ([[aDict objectForKey:@"type"] isEqualToString:@"ServerPlaylistResponseBlock"])
            {
                ServerPlaylistResponseBlock aData = (ServerPlaylistResponseBlock)[aDict objectForKey:@"data"];
                [inv setArgument:&aData atIndex:2 + x];
            }
            else if ([[aDict objectForKey:@"type"] isEqualToString:@"ServerNextVideoResponseBlock"])
            {
                ServerNextVideoResponseBlock aData = (ServerNextVideoResponseBlock)[aDict objectForKey:@"data"];
                [inv setArgument:&aData atIndex:2 + x];
            }
            else if ([[aDict objectForKey:@"type"] isEqualToString:@"ServerChannelSubscriptionResponseBlock"])
            {
                ServerChannelSubscriptionResponseBlock aData = (ServerChannelSubscriptionResponseBlock)[aDict objectForKey:@"data"];
                [inv setArgument:&aData atIndex:2 + x];
            }
            else if ([[aDict objectForKey:@"type"] isEqualToString:@"ServerResponseBlockForGetPlayListModel"])
            {
                ServerResponseBlockForGetPlayListModel aData = (ServerResponseBlockForGetPlayListModel)[aDict objectForKey:@"data"];
                [inv setArgument:&aData atIndex:2 + x];
            }
            else if ([[aDict objectForKey:@"type"] isEqualToString:@"ServerResponseBlockForGetChannelModel"])
            {
                ServerResponseBlockForGetChannelModel aData = (ServerResponseBlockForGetChannelModel)[aDict objectForKey:@"data"];
                [inv setArgument:&aData atIndex:2 + x];
            }
        }
        else if ([aParameterType isEqualToString:@"errorBlock"])
        {
            if ([[aDict objectForKey:@"type"] isEqualToString:@"ServerErrorBlock"])
            {
                ServerErrorBlock aData = (ServerErrorBlock)[aDict objectForKey:@"data"];
                [inv setArgument:&aData atIndex:2 + x];
            }
        }

        //[inv setArgument:&aElement atIndex:2+x];
        //       if([[aParameterArray objectAtIndex:x] class]
        //
        //        [inv setArgument:&aElement atIndex:2+x]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
    }
    [inv invoke];
}

#pragma mark Get FAS (Analytics) Methods

- (void)getAnalyticsTrackingSessionIdForPathTemplate:(NSString *)pathTemplate withResponseBlock:(AnalyticsServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    NetworkStatus aNetworkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (aNetworkStatus == NotReachable)
    {
        NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kErrorCodeNotReachable userInfo:[NSDictionary dictionaryWithObject:@"Internet connection appears to be offline." forKey:NSLocalizedDescriptionKey]];

        inErrorBlock(aError);

        return;
    }

    NSLog(@"Send request for analytics token");
    NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kAnalyticsBaseURLforSessionIDs, pathTemplate];
    NSURL *url = [NSURL URLWithString:aURLStr];
    NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
    [aRequest setHTTPMethod:@"GET"];
    [aRequest addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];

    NSURLSession *session = [self createSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                  if (error)
                                                  {
                                                      inErrorBlock(error);
                                                  }
                                                  else
                                                  {
                                                      NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                      if (aServerResponse.statusCode == 200)
                                                      {
                                                          NSString *aResponsestr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                          inResponseBlock(aResponsestr);
                                                      }
                                                      else
                                                      {
                                                          NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];
                                                          inErrorBlock(aError);
                                                      }
                                                  }

                                                }];
    [dataTask resume];
}

- (void)getAnalyticsDeviceForPathTemplate:(NSString *)pathTemplate withResponseBlock:(AnalyticsServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    NetworkStatus aNetworkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (aNetworkStatus == NotReachable)
    {
        NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kErrorCodeNotReachable userInfo:[NSDictionary dictionaryWithObject:@"Internet connection appears to be offline." forKey:NSLocalizedDescriptionKey]];

        inErrorBlock(aError);

        return;
    }

    NSLog(@"Send request for analytics token");
    NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kAnalyticsBaseURLforSessionIDs, pathTemplate];
    NSURL *url = [NSURL URLWithString:aURLStr];
    NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
    [aRequest setHTTPMethod:@"GET"];
    [aRequest addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];

    NSURLSession *session = [self createSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                  if (error)
                                                  {
                                                      inErrorBlock(error);
                                                  }
                                                  else
                                                  {
                                                      NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                      if (aServerResponse.statusCode == 200)
                                                      {
                                                          NSString *aResponsestr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                          inResponseBlock(aResponsestr);
                                                      }
                                                      else
                                                      {
                                                          NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];
                                                          inErrorBlock(aError);
                                                      }
                                                  }

                                                }];
    [dataTask resume];
}

- (void)getAnalyticsSubsessionIdForPathTemplate:(NSString *)pathTemplate withResponseBlock:(AnalyticsServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    NetworkStatus aNetworkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (aNetworkStatus == NotReachable)
    {
        NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kErrorCodeNotReachable userInfo:[NSDictionary dictionaryWithObject:@"Internet connection appears to be offline." forKey:NSLocalizedDescriptionKey]];

        inErrorBlock(aError);

        return;
    }

    NSLog(@"Send request for analytics token");
    NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kAnalyticsBaseURLforSessionIDs, pathTemplate];
    NSURL *url = [NSURL URLWithString:aURLStr];
    NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
    [aRequest setHTTPMethod:@"GET"];
    [aRequest addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];

    NSURLSession *session = [self createSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                  if (error)
                                                  {
                                                      inErrorBlock(error);
                                                  }
                                                  else
                                                  {
                                                      NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                      if (aServerResponse.statusCode == 200)
                                                      {
                                                          NSString *aResponsestr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                          inResponseBlock(aResponsestr);
                                                      }
                                                      else
                                                      {
                                                          NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];
                                                          inErrorBlock(aError);
                                                      }
                                                  }

                                                }];
    [dataTask resume];
}

- (void)getAnalyticsUUIdForPathTemplate:(NSString *)pathTemplate withResponseBlock:(AnalyticsServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    NetworkStatus aNetworkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (aNetworkStatus == NotReachable)
    {
        NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kErrorCodeNotReachable userInfo:[NSDictionary dictionaryWithObject:@"Internet connection appears to be offline." forKey:NSLocalizedDescriptionKey]];

        inErrorBlock(aError);

        return;
    }

    NSLog(@"Send request for analytics token");
    NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kAnalyticsBaseURLforSessionIDs, pathTemplate];
    NSURL *url = [NSURL URLWithString:aURLStr];
    NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
    [aRequest setHTTPMethod:@"GET"];
    [aRequest addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];

    NSURLSession *session = [self createSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                  if (error)
                                                  {
                                                      inErrorBlock(error);
                                                  }
                                                  else
                                                  {
                                                      NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                      if (aServerResponse.statusCode == 200)
                                                      {
                                                          NSString *aResponsestr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                          inResponseBlock(aResponsestr);
                                                      }
                                                      else
                                                      {
                                                          NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:kServerErrorCode userInfo:[NSDictionary dictionaryWithObject:@"Server error, please try again" forKey:NSLocalizedDescriptionKey]];
                                                          inErrorBlock(aError);
                                                      }
                                                  }

                                                }];
    [dataTask resume];
}

- (void)postAnalyticsEventWithEventData:(NSDictionary *)eventData withResponseBlock:(AnalyticsServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kAnalyticsBaseURL, kAnalyticsEventPathTemplate];
    NSURL *url = [NSURL URLWithString:aURLStr];
    NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
    [aRequest setHTTPMethod:@"POST"];
    [aRequest addValue:@"text/plain,application/json" forHTTPHeaderField:@"Content-Type"];

    //[aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
    NSLog(@"eventData=%@", eventData);
    [aRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:eventData options:kNilOptions error:nil]];

    NSURLSession *session = [self createSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                  if (error)
                                                  {
                                                      inErrorBlock(error);
                                                  }
                                                  else
                                                  {
                                                      NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                      if (aServerResponse.statusCode == 200 || aServerResponse.statusCode == 204)

                                                      {
                                                          inResponseBlock(@"Success");
                                                      }
                                                      else
                                                      {
                                                          inResponseBlock(@"Failure");
                                                      }
                                                  }

                                                }];
    [dataTask resume];
}

#pragma mark get IP address Methods

- (void)getIPAddressWithResponseBlock:(AnalyticsServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    NSURL *url = [NSURL URLWithString:kIPAddressUrl];
    NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
    [aRequest setHTTPMethod:@"GET"];
    [aRequest addValue:kAcceptTypeWithVersion forHTTPHeaderField:@"Accept"];
    NSURLSession *session = [self createSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                  if (error)
                                                  {
                                                      inErrorBlock(error);
                                                  }
                                                  else
                                                  {
                                                      NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                      if (aServerResponse.statusCode == 200)

                                                      {
                                                          NSError *aError = nil;
                                                          id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                          if (aError)
                                                          {
                                                              inErrorBlock(error);
                                                          }
                                                          else
                                                          {
                                                              NSString *ip = [aResponse objectForKey:@"ip"];
                                                              inResponseBlock(ip);
                                                          }
                                                      }
                                                      else
                                                      {
                                                          inErrorBlock(error);
                                                      }
                                                  }

                                                }];
    [dataTask resume];
}

- (void)sendRequestToGetChannelInfo:(NSString *)aChannelId responseBlock:(ServerResponseBlockForGetChannelModel)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kZincBaseURL, kGetChannelInfo(aChannelId)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          //        [aRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
          //        [aRequest addValue:@"application/json" forHTTPHeaderField:@"accept"];

          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey] forHTTPHeaderField:@"SessionToken"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kAuthorizationKey] forHTTPHeaderField:@"Authorization"];
          [aRequest addValue:[Utilities getValueFromUserDefaultsForKey:kDeviceId] forHTTPHeaderField:kFabricDeviceIdKey];
          NSURLSession *session = [self createSession];
          NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:aRequest
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                        NSHTTPURLResponse *aServerResponse = (NSHTTPURLResponse *)response;
                                                        if (response)
                                                        {
                                                            if (aServerResponse.statusCode != 200)
                                                            {
                                                                if (aServerResponse.statusCode != 204)
                                                                {
                                                                    [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aServerResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                                }
                                                            }
                                                        }
                                                        if (error)
                                                        {
                                                            if (response)
                                                            {
                                                                [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aServerResponse.allHeaderFields objectForKey:@"uuid"]];
                                                            }
                                                            inErrorBlock(error);
                                                        }
                                                        else
                                                        {
                                                            if (aServerResponse.statusCode == 200 || aServerResponse.statusCode == 204)
                                                            {
                                                                NSError *aError = nil;
                                                                id aResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&aError];
                                                                if (aError)
                                                                {
                                                                    inErrorBlock(error);
                                                                    return;
                                                                }
                                                                else
                                                                {
                                                                    ChannelModel *aModel = [[ChannelModel alloc] initWithJSONData:aResponse];

                                                                    inResponseBlock(aModel);
                                                                    return;
                                                                }
                                                            }

                                                            if (aServerResponse.statusCode == 401)
                                                            {
                                                                NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                               encoding:NSUTF8StringEncoding];
                                                                NSLog(@"aResponsestr=%@", aResponsestr);

                                                                if ([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame || [aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                {
                                                                    NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];

                                                                    NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", aChannelId, @"data", nil];
                                                                    NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlockForGetChannelModel", @"type", inResponseBlock, @"data", nil];

                                                                    NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                    [aParameterArray addObject:aRequestDataDict];
                                                                    [aParameterArray addObject:aSuccessDataDict];
                                                                    [aParameterArray addObject:aErrorDataDict];

                                                                    //AUTHORIZATION TOKEN INVALID
                                                                    [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToUpdateVideoProgressTime:responseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                    return;
                                                                }
                                                            }
                                                            if (aServerResponse.statusCode == 404)
                                                            {
                                                                NSError *Error = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:404 userInfo:[NSDictionary dictionaryWithObject:@"The Show which you are looking for is not available now." forKey:NSLocalizedDescriptionKey]];
                                                                inErrorBlock(Error);
                                                                return;
                                                            }

                                                            NSError *Error = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:93 userInfo:[NSDictionary dictionaryWithObject:@"Unable to fetch channel info from server." forKey:NSLocalizedDescriptionKey]];
                                                            inErrorBlock(Error);
                                                        }

                                                      }];
          [dataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark Bitly
- (void)sendRequestToGetBitlyShareUrl:(NSString *)aShareLongUrl withShareData:(NSString *)aShareData withResponseBlock:(ServerResponseBlock)inResponseBlock errorBlock:(ServerErrorBlock)inErrorBlock
{
    [[ServerConnectionSingleton sharedInstance] sendRequestToGetSessionTokenFromServer:NO
        WithresponseBlock:^(NSDictionary *responseDict) {

          // NSString *aURLStr=@"http://fabricgroup.xidio.com/fbitlys/api/link/transform?longurl=http://www.watchable.com/videos/71727-st-patrick-s-day-beer-goggles-explained&deeplink=playlists/agdDnWKYR";
          NSString *aURLStr = [NSString stringWithFormat:@"%@%@", kFabricHybrid, kGetBitlyURL(aShareLongUrl, aShareData)];
          NSURL *url = [NSURL URLWithString:aURLStr];
          NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:url];
          [aRequest setHTTPMethod:@"GET"];
          [aRequest addValue:@"text/plain,application/json" forHTTPHeaderField:@"Content-Type"];
          //[aRequest addValue:@"application/json,application/xml" forHTTPHeaderField:@"Accept"];
          // NSString *aSessionToken=[Utilities getValueFromUserDefaultsForKey:kSessionTokenKey];
          //[aRequest addValue:aSessionToken forHTTPHeaderField:@"SessionToken"];

          NSURLSession *session = [self createSession];
          [self cancelBitlyShortURLServerAPICall];
          self.mBitlyShortURLdataTask = [session dataTaskWithRequest:aRequest
                                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                     self.mBitlyShortURLdataTask = nil;

                                                     NSHTTPURLResponse *aResponse = (NSHTTPURLResponse *)response;
                                                     if (response)
                                                     {
                                                         if (aResponse.statusCode != 200)
                                                         {
                                                             if (aResponse.statusCode != 204)
                                                             {
                                                                 [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)aResponse.statusCode] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                             }
                                                         }
                                                     }
                                                     if (error)
                                                     {
                                                         if (response)
                                                         {
                                                             [[AnalyticsEventsHandler sharedInstance] postAnalyticsErrorForEventType:kEventTypeError eventName:kEventNameError errorCode:[NSString stringWithFormat:@"%d", (int)error.code] offendingUrl:aURLStr andUUID:(NSString *)[aResponse.allHeaderFields objectForKey:@"uuid"]];
                                                         }
                                                         inErrorBlock(error);
                                                     }
                                                     else
                                                     {
                                                         if (aResponse.statusCode == 200)
                                                         {
                                                             NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                            encoding:NSUTF8StringEncoding];
                                                             NSLog(@"Bitlyurl ---- %@", aResponsestr);

                                                             if (aResponsestr.length && ([aResponsestr rangeOfString:@"http" options:NSCaseInsensitiveSearch].location != NSNotFound))
                                                             {
                                                                 NSDictionary *aResponseDict = @{ @"shortUrl" : aResponsestr };
                                                                 inResponseBlock(aResponseDict);
                                                             }
                                                             else
                                                             {
                                                                 NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:93 userInfo:[NSDictionary dictionaryWithObject:@"Invalid response" forKey:NSLocalizedDescriptionKey]];
                                                                 inErrorBlock(aError);
                                                             }
                                                         }
                                                         else
                                                         {
                                                             if (aResponse.statusCode == 401)
                                                             {
                                                                 NSString *aResponsestr = [[NSString alloc] initWithData:data
                                                                                                                encoding:NSUTF8StringEncoding];
                                                                 NSLog(@"aResponsestr=%@", aResponsestr);

                                                                 if ([aResponsestr caseInsensitiveCompare:@"FABRIC"] == NSOrderedSame)
                                                                 {
                                                                     NSMutableArray *aParameterArray = [[NSMutableArray alloc] init];
                                                                     NSDictionary *aRequestDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", aShareLongUrl, @"data", nil];

                                                                     NSDictionary *aRequestDataDict2 = [NSDictionary dictionaryWithObjectsAndKeys:@"requestData", @"parameterType", @"NSString", @"type", aShareData, @"data", nil];

                                                                     NSDictionary *aSuccessDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"successBlock", @"parameterType", @"ServerResponseBlock", @"type", inResponseBlock, @"data", nil];

                                                                     NSDictionary *aErrorDataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"errorBlock", @"parameterType", @"ServerErrorBlock", @"type", inErrorBlock, @"data", nil];

                                                                     [aParameterArray addObject:aRequestDataDict];
                                                                     [aParameterArray addObject:aRequestDataDict2];
                                                                     [aParameterArray addObject:aSuccessDataDict];
                                                                     [aParameterArray addObject:aErrorDataDict];

                                                                     //AUTHORIZATION TOKEN INVALID
                                                                     [self getNewAuthorizationOrSessionTokenWithSelectorForSuccess:@selector(sendRequestToGetBitlyShareUrl:withShareData:withResponseBlock:errorBlock:) withParameter:aParameterArray isForAuthorization:([aResponsestr caseInsensitiveCompare:@"USER"] == NSOrderedSame) ? YES : NO];

                                                                     return;
                                                                 }
                                                             }

                                                             NSError *aError = [NSError errorWithDomain:@"com.Comcast.Watchable.ErrorDomain" code:93 userInfo:[NSDictionary dictionaryWithObject:@"A server error occurred, please try again" forKey:NSLocalizedDescriptionKey]];
                                                             inErrorBlock(aError);
                                                         }
                                                     }

                                                   }];
          [self.mBitlyShortURLdataTask resume];

        }
        errorBlock:^(NSError *error) {

          inErrorBlock(error);
        }];
}

#pragma mark NSURLSession delegate Methods

- (void)URLSession:(NSURLSession *)session
    didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
      completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    // completionHandler(NSURLSessionAuthChallengeUseCredential,[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);

    NSLog(@"didReceiveChallenge");

    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    if (serverTrust)
    {
        // if (1 /*[self shouldTrustProtectionSpace:challenge.protectionSpace]*/) {
        NSString *certPath = [[NSBundle mainBundle] pathForResource:@"server0716" ofType:@"der"];
        NSData *certData = [[NSData alloc] initWithContentsOfFile:certPath];

        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        SecCertificateRef remoteVersionOfServerCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
        CFDataRef remoteCertificateData = SecCertificateCopyData(remoteVersionOfServerCertificate);
        BOOL certificatesAreTheSame = [certData isEqualToData:(__bridge NSData *)remoteCertificateData];
        if (certificatesAreTheSame)
        {
            NSLog(@"didReceiveChallenge=certificatesAreTheSame");
            completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
        }
        else
        {
            completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
        }
        //        }
        //        else {
        //           completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace,nil);
        //        }
    }
    else
    {
        completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
    }
}

- (BOOL)shouldTrustProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    // Load up the bundled certificate.

    NSString *certPath = [[NSBundle mainBundle] pathForResource:@"server0716" ofType:@"der"];
    NSData *certData = [[NSData alloc] initWithContentsOfFile:certPath];
    CFDataRef certDataRef = (__bridge_retained CFDataRef)certData;
    SecCertificateRef cert = SecCertificateCreateWithData(NULL, certDataRef);

    // Establish a chain of trust anchored on our bundled certificate.
    CFArrayRef certArrayRef = CFArrayCreate(NULL, (void *)&cert, 1, NULL);
    SecTrustRef serverTrust = protectionSpace.serverTrust;
    SecTrustSetAnchorCertificates(serverTrust, certArrayRef);
    // Verify that trust.
    SecTrustResultType trustResult;
    SecTrustEvaluate(serverTrust, &trustResult);

    if (trustResult == kSecTrustResultRecoverableTrustFailure)
    {
        CFDataRef errDataRef = SecTrustCopyExceptions(serverTrust);
        SecTrustSetExceptions(serverTrust, errDataRef);
        SecTrustEvaluate(serverTrust, &trustResult);
    }
    // Clean up.
    CFRelease(certArrayRef);
    CFRelease(cert);
    CFRelease(certDataRef);

    return trustResult == kSecTrustResultUnspecified || trustResult == kSecTrustResultProceed;

    /*  NSString *certPath = [[NSBundle mainBundle] pathForResource:@"server0716" ofType:@"der"];
     NSData *certData = [[NSData alloc] initWithContentsOfFile:certPath];
     
     SecTrustRef serverTrust = protectionSpace.serverTrust;
     SecCertificateRef remoteVersionOfServerCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
     CFDataRef remoteCertificateData = SecCertificateCopyData(remoteVersionOfServerCertificate);
     BOOL certificatesAreTheSame = [certData isEqualToData: (__bridge NSData *)remoteCertificateData];
     
     return certificatesAreTheSame;*/
}

- (NSURLSession *)createSession
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                          delegate:self
                                                     delegateQueue:nil];
    return session;
}

- (NSString *)encodeToPercentEscapeString:(NSString *)aString
{
    NSString *escapedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
        NULL,
        (__bridge CFStringRef)aString,
        NULL,
        CFSTR("!*'();:@&=+$,/?%#[]\" "),
        kCFStringEncodingUTF8));
    return escapedString;
}

//-(NSString*)getErrorUuidFromResponse:(NSHTTPURLResponse*)response{
//
//    NSString *uuid = nil;
//    if(response != nil){
//    uuid = [response.allHeaderFields objectForKey:@"uuid"];
//    }
//    return uuid;
//}

@end

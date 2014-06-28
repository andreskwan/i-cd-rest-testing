//
//  KCViewController.m
//  TestApiRest
//
//  Created by Andres Kwan on 6/19/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import "KCViewController.h"

static NSString* const kBaseURL = @"http://localhost:3001/seriestv";

@interface KCViewController ()

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) NSDictionary *dict1;
@end

@implementation KCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)getAllButtonPressed {

    //    #warning REST add URL to persist data
    NSURL* url = [NSURL URLWithString:kBaseURL];
    
    //    #warning REST create the request with the url
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    //    #warning REST PUT update or POST create
    //    request.HTTPMethod = isExistingLocation ? @"PUT" : @"POST"; //2
    request.HTTPMethod =@"GET";
    
    [request addValue:@"application/json"
   forHTTPHeaderField:@"Accept"]; //4
    
    //id
    NSURLSessionConfiguration* config =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) { //5
                   if (error == nil) {
                       NSError *error;
                       NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data
                                                                                options:0
                                                                                  error:&error];
                       //            NSArray * keyArray = [jsonDict allValues];
                       //            NSDictionary *dic2 = [[NSDictionary alloc]init];
                       //            NSInteger * i = 0;
                       for (id obj in jsonDict)
                       {
                           self.dict1 = obj;
                           //here obj is a dictionary too
                           NSLog(@"obj class:%@", [obj class]);
                           //                NSLog(@"objt: %@",obj);
                           //                i+=1;
                           //                //here obj is a key of the obj dictionary
                           //                for (id obj2 in obj) {
                           ////                  NSLog(@"obj2 class:%@", [obj2 class]);
                           //                    NSLog(@"\nobj2 key: %@\n",obj2);
                           //                    NSLog(@"obj2 value: %@", [obj objectForKey:obj2]);
                           //
                           //                }
                       }
                       
                       //            NSLog(@"%@", );
                       //             NSArray* responseArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                       //            if ([responseArray count])
                       //            {
                       //                self.label.text = [jsonDict objectForKey:<#(id)#>;
                       //            }
                   }
               }];
    [dataTask resume]; //8
    self.label.text = [self.dict1 objectForKey:@"title"];
    //    self.label.text = [self.dict1 objectForKey:@"title"];
}

- (IBAction)getObjButtonPressed {
    
    
    self.label.text = @"Get button pressed";
    NSString * idString = @"5362a8449cb4c8e21d09f45b";
    NSString * urlString = [NSString stringWithFormat:@"http://localhost:3001/seriestv/%@", idString];
    //    #warning REST add URL to persist data
    NSURL* url = [NSURL URLWithString:urlString];
    
    //    #warning REST create the request with the url
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    //    #warning REST PUT update or POST create
    //    request.HTTPMethod = isExistingLocation ? @"PUT" : @"POST"; //2
    request.HTTPMethod =@"GET";
    
    [request addValue:@"application/json"
   forHTTPHeaderField:@"Accept"]; //4
    
    //id
    NSURLSessionConfiguration* config =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) { //5
                   if (error == nil) {
                       NSError *error;
                       NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data
                                                                                options:0
                                                                                  error:&error];
                       NSLog(@"obj class:%@", [jsonDict class]);
                       NSLog(@"obj title:%@", jsonDict[@"title"]);
                       //ui is not updated from here!
                       self.label.text = jsonDict[@"title"];
                                        }
               }];
    [dataTask resume]; //8
    self.label.text = [self.dict1 objectForKey:@"title"];
}

- (NSDictionary *)dict1
{
    if (!_dict1) _dict1 = [[NSDictionary alloc]init];
    return _dict1;
}

- (IBAction)postObjButtonPressed {
    NSDictionary * const kSerieObj = @{
                                       @"title": @"LOST",
                                       @"year": @2000,
                                       @"country": @"USA",
                                       @"poster": @"http://ia.media-imdb.com/images/M/MV5BMjA3NzMyMzU1MV5BMl5BanBnXkFtZTcwNjc1ODUwMg@@._V1_SY317_CR17,0,214,317_.jpg",
                                       @"seasons": @6,
                                       @"genre": @"Sci-Fi",
                                       @"summary": @"The survivors of a plane crash are forced to live with each other on a remote island, a dangerous new world that poses unique threats of its own."
                                       };

    NSString * urlString = [NSString stringWithFormat:@"http://localhost:3001/seriestv"];
    //    #warning REST add URL to persist data
    NSURL* url = [NSURL URLWithString:urlString];
    
    //    #warning REST create the request with the url
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    
    NSData * dataToPost = [NSJSONSerialization dataWithJSONObject:kSerieObj
                                                          options:0
                                                            error:NULL];

    //    #warning REST PUT update or POST create
    //    request.HTTPMethod = isExistingLocation ? @"PUT" : @"POST"; //2
    request.HTTPMethod =@"POST";
    
    [request addValue:@"application/json"
   forHTTPHeaderField:@"Content-Type"]; //4
    
    request.HTTPBody = dataToPost;

    NSURLSessionConfiguration* config =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) { //5
                   if (error == nil) {
                       NSError *error;
//                       NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data
//                                                                                options:0
//                                                                                  error:&error];
                       NSLog(@"obj error:%@", error);
                       NSLog(@"obj data:%@", data);
                       //ui is not updated from here!
//                       self.label.text = jsonDict[@"title"];
                   }
               }];
    [dataTask resume]; //8
//    self.label.text = [self.dict1 objectForKey:@"title"];
}

@end

//
//  ViewController.h
//  WeatherForecast
//
//  Created by Samoilov Denis on 23.09.15.
//  Copyright (c) 2015 Nubaslon LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate>

+ (CLLocationManager *)sharedLocationManager;

@end


//
//  ViewController.m
//  WeatherForecast
//
//  Created by Samoilov Denis on 23.09.15.
//  Copyright (c) 2015 Nubaslon LLC. All rights reserved.
//

#import "ViewController.h"
#import "WeatherAPI.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
{
    WeatherAPI *weatherAPIObject;
    CLLocationCoordinate2D coordinates;
    CLPlacemark *placemark;
    NSString *cityByLocationName;
    NSArray *forecastWeather;
    NSDateFormatter *_dateFormatter;
}

@property (weak, nonatomic) IBOutlet UITextField *cityNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *curTemperatureLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *currentPlaceTemp;

@end

@implementation ViewController

+ (CLLocationManager *)sharedLocationManager {
    static CLLocationManager *_locationManager;
    
    @synchronized(self) {
        if (_locationManager == nil) {
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        }
    }
    return _locationManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self getCurrentLocation];
    
    [self.currentPlaceTemp addTarget:self action:@selector(getCurrentLocation) forControlEvents:UIControlEventTouchUpInside];
    
    NSString *dateComponents = @"H:m yyMMMMd";
    NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:[NSLocale systemLocale] ];
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:dateFormat];

    weatherAPIObject = [[WeatherAPI alloc] initWithKey:@"1111111111"];
    
    [self checkLocationEnable];
}


#pragma mark - Location
- (void)getCurrentLocation{
    forecastWeather = @[];
    [self.tableView reloadData];
    if ([CLLocationManager locationServicesEnabled] == NO) {
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [servicesDisabledAlert show];
    } else {
        CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
        
        if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted){
            NSLog(@"authorizationStatus failed");
        } else {
            NSLog(@"authorizationStatus authorized");
            CLLocationManager *locationManager = [ViewController sharedLocationManager];
            locationManager.delegate = self;
            locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            
            if ([[ViewController sharedLocationManager] respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [[ViewController sharedLocationManager] requestWhenInUseAuthorization];
            }
            [locationManager startUpdatingLocation];
        }
    }
}

#pragma mark - CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    switch([error code])
    {
        case kCLErrorNetwork:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Please check your network connection." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        case kCLErrorDenied:{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enable Location Service" message:@"You have to enable the Location Service to use this App. To enable, please go to Settings->Privacy->Location Services" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        default:
        {
            
        }
            break;
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *currentLocation = [locations lastObject];
    
    if (currentLocation != nil) {
        coordinates = currentLocation.coordinate;
    }
    
    CLLocationManager *locationManager = [ViewController sharedLocationManager];
    [locationManager stopUpdatingLocation];
    
    [self getCityByLocation:currentLocation];
}

-(NSString*)getCityByLocation:(CLLocation*)location{
    // Reverse Geocoding
    NSLog(@"Resolving the Address");
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        //NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            cityByLocationName = [NSString stringWithFormat:@"%@", placemark.locality];
            NSLog(@"Location - %@", cityByLocationName);
            self.cityNameLabel.text = cityByLocationName;
            [weatherAPIObject curWeatherByLocation:coordinates onSuccess:^(NSError *error, NSDictionary *result) {
                self.curTemperatureLabel.text = [NSString stringWithFormat:@"%.1f℃", [result[@"main"][@"temp"] floatValue]];
                [weatherAPIObject forecastWeatherByCoordinate:coordinates onSuccess:^(NSError *error, NSDictionary *result) {
                    if (error) {
                        return;
                    }
                    forecastWeather = result[@"list"];
                    [self.tableView reloadData];
                }];
            }];
        } else {
            self.cityNameLabel.text = @"Enter name of city...";
            NSLog(@"ERROR - %@", error.debugDescription);
        }
    }];
    return cityByLocationName;
}

-(void)checkLocationEnable{
    if([CLLocationManager locationServicesEnabled]){
        
        NSLog(@"Location Services Enabled");
        
        if([CLLocationManager authorizationStatus]==kCLAuthorizationStatusDenied){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"App Permission Denied"
                                                            message:@"To re-enable, please go to Settings and turn on Location Service for this app."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if (textField.text.length > 0) {
        [weatherAPIObject curWeatherByCityName:textField.text onSuccess:^(NSError *error, NSDictionary *result) {
            forecastWeather = @[];
            [self.tableView reloadData];
            self.curTemperatureLabel.text = [NSString stringWithFormat:@"%.1f℃", [result[@"main"][@"temp"] floatValue]];
            [weatherAPIObject forecastWeatherByCityName:textField.text onSuccess:^(NSError *error, NSDictionary *result) {
                if (error) {
                    return;
                }
                forecastWeather = result[@"list"];
                [self.tableView reloadData];
            }];
        }];
    }
    
    return NO;
}

#pragma mark - tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return forecastWeather.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    
    NSDictionary *forecastData = [forecastWeather objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%.1f℃ - %@",
                           [forecastData[@"main"][@"temp"] floatValue],
                           forecastData[@"weather"][0][@"main"]
                           ];
    
    cell.detailTextLabel.text = [_dateFormatter stringFromDate:forecastData[@"dt"]];
    
    return cell;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

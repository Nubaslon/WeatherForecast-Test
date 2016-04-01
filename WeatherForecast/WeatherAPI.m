//
//  WeatherAPI.m
//  WeatherForecast
//
//  Created by Samoilov Denis on 23.09.15.
//  Copyright (c) 2015 Nubaslon LLC. All rights reserved.
//

#import "WeatherAPI.h"
#import <AFNetworking/AFNetworking.h>

static NSString* const BASE_URL = @"http://api.openweathermap.org";
static NSString* const CUR_BY_CITY_NAME = @"/data/2.5/weather?q=";
static NSString* const CUR_BY_LOCATION = @"/data/2.5/weather?";
static NSString* const FORC_BY_CITY_NAME = @"/data/2.5/forecast?q=";
static NSString* const FORC_BY_LOCATION = @"/data/2.5/forecast?";

@interface WeatherAPI ()
{
    NSString *keyApi;
    FormatTemperature currentTemFormat;
}

@property (strong, nonatomic) AFHTTPRequestOperationManager *requestOperationManager;

@end

@implementation WeatherAPI

-(id)initWithKey:(NSString *)key{
    self = [super init];
    if (self) {
        keyApi = key;
        currentTemFormat = kTempCelcius;
        self.requestOperationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
        self.requestOperationManager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    }
    return self;
}

-(void)curWeatherByCityName:(NSString *)name
                    onSuccess:( void (^)( NSError* error, NSDictionary *result ) )success{
    NSString *path = [NSString stringWithFormat:@"%@%@", CUR_BY_CITY_NAME, name];
    
    [self requestByPath:path onSucces:success];
}

-(void)curWeatherByLocation:(CLLocationCoordinate2D)coordinate
                    onSuccess:(void (^)(NSError *, NSDictionary *))success{
    NSString *path = [NSString stringWithFormat:@"%@lat=%f&lon=%f", CUR_BY_LOCATION, coordinate.latitude, coordinate.longitude];
    
    [self requestByPath:path onSucces:success];
}

-(void)forecastWeatherByCityName:(NSString *)name
                       onSuccess:(void (^)(NSError *, NSDictionary *))success{
    NSString *path = [NSString stringWithFormat:@"%@%@", FORC_BY_CITY_NAME, name];
    
    [self requestByPath:path onSucces:success];
}

-(void)forecastWeatherByCoordinate:(CLLocationCoordinate2D)coordinate
                         onSuccess:(void (^)(NSError *, NSDictionary *))success{
    NSString *path = [NSString stringWithFormat:@"%@lat=%f&lon=%f", FORC_BY_LOCATION, coordinate.latitude, coordinate.longitude];
    
    [self requestByPath:path onSucces:success];
}

-(void)searchCityByName:(NSString *)name onSuccess:(void (^)(NSError *, NSDictionary *))success{
    NSString *path = [NSString stringWithFormat:@"/find?q=%@&units=metric", [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [self requestByPath:path onSucces:success];
}

-(void)requestByPath:(NSString*)path onSucces:(void (^)( NSError* error, NSDictionary *result))success{
    NSString *urlPath = [NSString stringWithFormat:@"%@&APPID=%@", path, keyApi];
    
    [self.requestOperationManager POST:urlPath parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *resultTmp = [self convertResult:responseObject];
        success(nil, resultTmp);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        success(error, nil);
    }];
}

- (NSDictionary *)convertResult:(NSDictionary *)res {
    
    NSMutableDictionary *dic = [res mutableCopy];
    
    NSMutableDictionary *main = [[dic objectForKey:@"main"] mutableCopy];
    if (main) {
        main[@"temp"] = [self convertTemp:main[@"temp"]];
        main[@"temp_min"] = [self convertTemp:main[@"temp_min"]];
        main[@"temp_max"] = [self convertTemp:main[@"temp_max"]];
        
        dic[@"main"] = [main copy];
    }
    
    NSMutableDictionary *temp = [[dic objectForKey:@"temp"] mutableCopy];
    if (temp) {
        temp[@"day"] = [self convertTemp:temp[@"day"]];
        temp[@"eve"] = [self convertTemp:temp[@"eve"]];
        temp[@"max"] = [self convertTemp:temp[@"max"]];
        temp[@"min"] = [self convertTemp:temp[@"min"]];
        temp[@"morn"] = [self convertTemp:temp[@"morn"]];
        temp[@"night"] = [self convertTemp:temp[@"night"]];
        
        dic[@"temp"] = [temp copy];
    }
    
    
    NSMutableDictionary *sys = [[dic objectForKey:@"sys"] mutableCopy];
    if (sys) {
        
        sys[@"sunrise"] = [self convertToDate: sys[@"sunrise"]];
        sys[@"sunset"] = [self convertToDate: sys[@"sunset"]];
        
        dic[@"sys"] = [sys copy];
    }
    
    
    NSMutableArray *list = [[dic objectForKey:@"list"] mutableCopy];
    if (list) {
        
        for (int i = 0; i < list.count; i++) {
            [list replaceObjectAtIndex:i withObject:[self convertResult: list[i]]];
        }
        
        dic[@"list"] = [list copy];
    }
    
    dic[@"dt"] = [self convertToDate:dic[@"dt"]];
    
    return [dic copy];
}

- (NSNumber *) convertTemp:(NSNumber *) temp {
    if (currentTemFormat == kTempCelcius) {
        return [self tempToCelcius:temp];
    } else if (currentTemFormat == kTempFahrenheit) {
        return [self tempToFahrenheit:temp];
    } else {
        return temp;
    }
}

- (NSNumber *) tempToCelcius:(NSNumber *) tempKelvin
{
    return @(tempKelvin.floatValue - 273.15);
}

- (NSNumber *) tempToFahrenheit:(NSNumber *) tempKelvin
{
    return @((tempKelvin.floatValue * 9/5) - 459.67);
}

- (NSDate *) convertToDate:(NSNumber *) num {
    return [NSDate dateWithTimeIntervalSince1970:num.intValue];
}

@end

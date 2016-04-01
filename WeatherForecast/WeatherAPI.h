//
//  WeatherAPI.h
//  WeatherForecast
//
//  Created by Samoilov Denis on 23.09.15.
//  Copyright (c) 2015 Nubaslon LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef enum {
    kTempKelvin,
    kTempCelcius,
    kTempFahrenheit
} FormatTemperature;

@interface WeatherAPI : NSObject

-(id)initWithKey:(NSString*)key;


//Получение текущей погоды по названию города
-(void)curWeatherByCityName:(NSString *) name
                    onSuccess:(void(^)(NSError* error, NSDictionary *result))success;

//Получение текущей погоды по координатам
-(void)curWeatherByLocation:(CLLocationCoordinate2D)coordinate
                      onSuccess:(void(^)(NSError* error, NSDictionary *result))success;

//Получение будущей погоды по названию города
-(void)forecastWeatherByCityName:(NSString *)name
                     onSuccess:(void(^)(NSError* error, NSDictionary *result))success;

//Получение будущей погоды по координатам
-(void)forecastWeatherByCoordinate:(CLLocationCoordinate2D)coordinate
                       onSuccess:(void(^)(NSError* error, NSDictionary *result))success;

@end

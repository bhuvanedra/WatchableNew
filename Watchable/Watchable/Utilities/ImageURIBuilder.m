//
//  ImageURIBuilder.m
//  Watchable
//
//  Created by Raja Indirajith on 21/02/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "ImageURIBuilder.h"

static NSString *queryString = @"?width={width}&height={height}";
static NSString *providerImageQueryString = @"?location=thumb&width={width}&height={height}";

@implementation ImageURIBuilder

+ (NSString *)buildURLWithString:(NSString *)imageUrl withSize:(CGSize)size
{
    NSString *urlStr = imageUrl;
    if (![urlStr isKindOfClass:[NSString class]])
    {
        return nil;
    }
    if (imageUrl == nil)
    {
        return nil;
    }
    NSMutableDictionary *param = [NSMutableDictionary new];

    if ([imageUrl rangeOfString:queryString].location == NSNotFound)
    {
        urlStr = [imageUrl stringByAppendingString:queryString];
    }

    NSString *widthStr = [NSString stringWithFormat:@"%d", [ImageURIBuilder getDeviceResolutionScale] * (int)size.width];
    NSString *heightStr = [NSString stringWithFormat:@"%d", [ImageURIBuilder getDeviceResolutionScale] * (int)size.height];
    [param setObject:widthStr forKey:@"width"];
    [param setObject:heightStr forKey:@"height"];

    return [ImageURIBuilder getUrlForParameters:param andBaseUrl:urlStr];
}

+ (NSString *)buildProviderImageURLWithString:(NSString *)imageUrl withSize:(CGSize)size
{
    if (imageUrl == nil)
    {
        return nil;
    }
    NSString *urlStr = imageUrl;
    NSMutableDictionary *param = [NSMutableDictionary new];

    if ([imageUrl rangeOfString:providerImageQueryString].location == NSNotFound)
    {
        urlStr = [imageUrl stringByAppendingString:providerImageQueryString];
    }

    NSString *widthStr = [NSString stringWithFormat:@"%d", [ImageURIBuilder getDeviceResolutionScale] * (int)size.width];
    NSString *heightStr = [NSString stringWithFormat:@"%d", [ImageURIBuilder getDeviceResolutionScale] * (int)size.height];

    [param setObject:widthStr forKey:@"width"];
    [param setObject:heightStr forKey:@"height"];

    return [ImageURIBuilder getUrlForParameters:param andBaseUrl:urlStr];
}

+ (NSString *)buildImageUrlWithString:(NSString *)imageUrl ForImageType:(ImageType)imageType withSize:(CGSize)size
{
    if (imageUrl == nil)
    {
        return nil;
    }
    NSString *pathTemplate = [NSString stringWithFormat:@"%@", [ImageURIBuilder stringForImageType:imageType]];
    NSString *urlStr = imageUrl;
    NSMutableDictionary *param = [NSMutableDictionary new];
    urlStr = [imageUrl stringByAppendingString:pathTemplate];
    NSString *widthStr = [NSString stringWithFormat:@"%d", [ImageURIBuilder getDeviceResolutionScale] * (int)size.width];
    NSString *heightStr = [NSString stringWithFormat:@"%d", [ImageURIBuilder getDeviceResolutionScale] * (int)size.height];

    [param setObject:widthStr forKey:@"width"];
    [param setObject:heightStr forKey:@"height"];

    return [ImageURIBuilder getUrlForParameters:param andBaseUrl:urlStr];

    return nil;
}

+ (NSString *)build2XImageUrlWithString:(NSString *)imageUrl ForImageType:(ImageType)imageType withSize:(CGSize)size
{
    if (imageUrl == nil)
    {
        return nil;
    }
    NSString *pathTemplate = [NSString stringWithFormat:@"%@", [ImageURIBuilder stringForImageType:imageType]];
    NSString *urlStr = imageUrl;
    NSMutableDictionary *param = [NSMutableDictionary new];
    urlStr = [imageUrl stringByAppendingString:pathTemplate];
    NSString *widthStr = [NSString stringWithFormat:@"%d", 2 * (int)size.width];
    NSString *heightStr = [NSString stringWithFormat:@"%d", 2 * (int)size.height];

    [param setObject:widthStr forKey:@"width"];
    [param setObject:heightStr forKey:@"height"];

    return [ImageURIBuilder getUrlForParameters:param andBaseUrl:urlStr];

    return nil;
}

+ (NSString *)stringForImageType:(ImageType)imageType
{
    NSString *iStr = @"";

    switch (imageType)
    {
        case Cover_art:
            iStr = @"?location=cover_art&width={width}&height={height}";
            break;
        case Horizontal_logo:
        {
            //iStr = @"?location=horizontal_logo&width={width}&height={height}";
            iStr = @"?location=horizontal_logo";
        }
        break;
        case Horizontal_lc_logo:
        {
            //iStr = @"?location=location=horizontal-lc-logo&width={width}&height={height}";
            iStr = @"?location=horizontal-lc-logo";
        }
        break;
        case Two2One_logo:
            iStr = @"?location=2to1_logo&width={width}&height={height}";
            break;

        default:
            break;
    }

    return iStr;
}

+ (NSString *)getUrlForParameters:(NSMutableDictionary *)param andBaseUrl:(NSString *)baseUrl
{
    NSString *result = baseUrl;
    for (NSString *key in [param allKeys])
    {
        result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{%@}", key] withString:[ImageURIBuilder convertToString:[param objectForKey:key]]];
    }
    return result;
}

+ (NSString *)convertToString:(id)value
{
    if (value == nil || value == [NSNull null])
    {
        return nil;
    }
    if ([value isKindOfClass:[NSString class]])
    {
        return value;
    }
    if ([value respondsToSelector:@selector(stringValue)])
    {
        return [value stringValue];
    }
    @throw [NSException exceptionWithName:@"Type error" reason:[NSString stringWithFormat:@"Don't know how to convert '%@' (%@) to NSString", [value description], [value class]] userInfo:nil];
}

+ (int)getDeviceResolutionScale
{
    int aScale = (int)[[UIScreen mainScreen] scale];

    // NSLog(@"ascale=%d",aScale);

    return aScale;
}

@end

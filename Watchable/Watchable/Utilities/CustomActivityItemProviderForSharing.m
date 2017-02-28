//
//  CustomActivityItemProviderForSharing.m
//  Watchable
//
//  Created by Valtech on 04/08/15.
//  Copyright (c) 2015 comcast. All rights reserved.
//

#import "CustomActivityItemProviderForSharing.h"

@interface CustomActivityItemProviderForSharing ()
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) UIImage *Image;
@property (nonatomic, assign) ShareContentType aContentType;
@property (nonatomic, assign) BOOL isCalledForImage;
@end

@implementation CustomActivityItemProviderForSharing

- (id)initWithText:(NSString *)text urlText:(NSURL *)url withShareType:(ShareContentType)aShareContentType title:(NSString *)aTitle
{
    if ((self = [super initWithPlaceholderItem:text]))
    {
        self.text = text;
        self.title = aTitle;
        self.url = url;
        self.isCalledForImage = NO;
        self.aContentType = aShareContentType;
    }
    return self;
}

- (id)initWithImage:(UIImage *)aImage withShareType:(ShareContentType)aShareContentType
{
    if ((self = [super initWithPlaceholderItem:aImage]))
    {
        self.Image = aImage;
        self.isCalledForImage = YES;
        self.aContentType = aShareContentType;
    }
    return self;
}

- (id)initWithImageURL:(NSURL *)imageUrl withShareType:(ShareContentType)aShareContentType
{
    if ((self = [super initWithPlaceholderItem:imageUrl]))
    {
        self.imageURL = imageUrl;
        self.isCalledForImage = YES;
        self.aContentType = aShareContentType;
    }
    return self;
}

- (id)item
{
    NSString *activityType = self.activityType;

    if ([self.activityType isEqualToString:UIActivityTypePostToFacebook])
    {
        if (!self.isCalledForImage)
        {
            NSString *contentType = @"";

            if (self.aContentType == ePlayList)
            {
                contentType = @"playlist";
            }
            else if (self.aContentType == eVideo)
            {
                contentType = @"video";
            }

            NSString *aShareText = [NSString stringWithFormat:@"%@ from @WatchableNow", self.title];

            return aShareText;
        }
        else
        {
            return self.imageURL;
        }
    }
    else if ([self.activityType isEqualToString:UIActivityTypePostToTwitter])
    {
        if (!self.isCalledForImage)
        {
            NSString *contentType = @"";

            if (self.aContentType == ePlayList)
            {
                contentType = @"playlist";
            }
            else if (self.aContentType == eVideo)
            {
                contentType = @"video";
            }

            NSString *aShareText = [NSString stringWithFormat:@"%@ from @WatchableNow", self.title];

            return aShareText;
        }
        else
        {
            return self.imageURL;
        }
    }
    else if ([activityType isEqualToString:UIActivityTypeMail])
    {
        if (!self.isCalledForImage)
        {
            NSString *contentType = @"";

            if (self.aContentType == ePlayList)
            {
                contentType = @"playlist";
            }
            else if (self.aContentType == eVideo)
            {
                contentType = @"video";
            }
            //  NSURL *Watchableurl = [NSURL URLWithString:kWatchableURLForShare];

            NSString *dottedLine = @"<html><body><hr style='border: none; border-top: 1px dotted #000000;'/></body></html>";
            NSString *htmlWatchNow = [NSString stringWithFormat:@"<html><body><br><br> <a href=%@>Watch Now!</a> <br><br></body></html>", self.url];
            NSString *htmlurl = [NSString stringWithFormat:@"<html><body><br><br> <a href=%@>%@</a> <br><br></body></html>", self.url, self.url];
            NSString *htmlDottedLine = [NSString stringWithFormat:@"%@", dottedLine];
            NSString *htmlWatchable = [NSString stringWithFormat:@"<html><body><br><br> <a href=http://%@>www.watchable.com</a><br><br></body></html>", kWatchableURLForShare];

            NSString *htmlMessage = [NSString stringWithFormat:@"<html><body><i>Whether you’re looking for hit web series, ground-breaking comedy, style and food gurus, jaw-dropping extreme sports, or the latest movie trailers...Watchable has it all.</i></body></html>"];

            NSString *aShareText = [NSString stringWithFormat:@"I found this great %@ on Watchable and thought you would enjoy it! %@ Please copy the url below and paste it into your browser if the link does not work. %@ %@ %@ %@", contentType, htmlWatchNow, htmlurl, htmlDottedLine, htmlMessage, htmlWatchable];

            return aShareText;
        }
        else
        {
            return @"";
        }
    }
    else if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard])
    {
        if (!self.isCalledForImage)
            return self.url;

        return @"";
    }
    else if ([activityType isEqualToString:UIActivityTypeMessage])
    {
        if (!self.isCalledForImage)
        {
            //                NSString *contentType=@"";
            //
            //                if(self.aContentType==ePlayList)
            //                {
            //                    contentType=@"playlist";
            //                }
            //                else if(self.aContentType==eVideo)
            //                {
            //                    contentType=@"video";
            //                }

            //                NSURL *Watchableurl = [NSURL URLWithString:kWatchableURLForShare];
            //
            //                NSString *aShareText=[NSString stringWithFormat:@"Hi,\n\nI found this great %@ on Watchable and thought you would enjoy it:\n%@\n\n%@\n\n%@",contentType,self.url,@"Whether you’re looking for hit web series, ground-breaking comedy, style and food gurus, jaw-dropping extreme sports, or the latest movie trailers...Watchable has it all.",Watchableurl];

            return self.url;
        }
        else
        {
            return @"";
        }
    }
    else
    {
        if (!self.isCalledForImage)
        {
            /*  NSString *contentType=@"";
                
                if(self.aContentType==ePlayList)
                {
                    contentType=@"playlist";
                }
                else if(self.aContentType==eVideo)
                {
                    contentType=@"video";
                }
                NSURL *Watchableurl = [NSURL URLWithString:kWatchableURLForShare];
                
                NSString *aShareText=[NSString stringWithFormat:@"Hi,\n\nI found this great %@ on Watchable and thought you would enjoy it:\n%@\n\n%@\n\n%@",contentType,self.url,@"Whether you’re looking for hit web series, ground-breaking comedy, style and food gurus, jaw-dropping extreme sports, or the latest movie trailers...Watchable has it all.",Watchableurl];
                */
            return self.url;
        }
        else
        {
            return @"";
        }
    }

    return self.placeholderItem;
}

@end
//
//  FacebookNativeCustomEvent.m
//  MoPub
//
//  Copyright (c) 2014 MoPub. All rights reserved.
//
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import "FacebookNativeCustomEvent.h"
#import "FacebookNativeAdAdapter.h"
#if __has_include("MoPub.h")
    #import "MPNativeAd.h"
    #import "MPLogging.h"
    #import "MPNativeAdError.h"
    #import "MPNativeAdConstants.h"
#endif

static const NSInteger FacebookNoFillErrorCode = 1001;
static BOOL gVideoEnabled = NO;

@interface FacebookNativeCustomEvent () <FBNativeAdDelegate>

@property (nonatomic, readwrite, strong) FBNativeAd *fbNativeAd;
@property (nonatomic) BOOL videoEnabled;

@end

@implementation FacebookNativeCustomEvent

+ (void)setVideoEnabled:(BOOL)enabled
{
    gVideoEnabled = enabled;
}

- (void)requestAdWithCustomEventInfo:(NSDictionary *)info
{
    [self requestAdWithCustomEventInfo:info adMarkup:nil];
}

- (void)requestAdWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup
{
    NSString *placementID = [info objectForKey:@"placement_id"];

    if ([info objectForKey:kFBVideoAdsEnabledKey] == nil) {
        self.videoEnabled = gVideoEnabled;
    } else {
        self.videoEnabled = [[info objectForKey:kFBVideoAdsEnabledKey] boolValue];
    }

    if (placementID) {
        _fbNativeAd = [[FBNativeAd alloc] initWithPlacementID:placementID];
        self.fbNativeAd.delegate = self;
        [FBAdSettings setMediationService:[NSString stringWithFormat:@"MOPUB_%@", MP_SDK_VERSION]];
        
        // Load the advanced bid payload.
        if (adMarkup != nil) {
            MPLogInfo(@"Loading Facebook native ad markup");
            [self.fbNativeAd loadAdWithBidPayload:adMarkup];
        }
        else {
            MPLogInfo(@"Requesting Facebook native ad");
            [self.fbNativeAd loadAd];
        }
    } else {
        [self.delegate nativeCustomEvent:self didFailToLoadAdWithError:MPNativeAdNSErrorForInvalidAdServerResponse(@"Invalid Facebook placement ID")];
    }
}

#pragma mark - FBNativeAdDelegate

- (void)nativeAdDidLoad:(FBNativeAd *)nativeAd
{
    FacebookNativeAdAdapter *adAdapter = [[FacebookNativeAdAdapter alloc] initWithFBNativeAd:nativeAd adProperties:@{kFBVideoAdsEnabledKey:@(self.videoEnabled)}];
    MPNativeAd *interfaceAd = [[MPNativeAd alloc] initWithAdAdapter:adAdapter];
    [self.delegate nativeCustomEvent:self didLoadAd:interfaceAd];
}

- (void)nativeAd:(FBNativeAd *)nativeAd didFailWithError:(NSError *)error
{
    if (error.code == FacebookNoFillErrorCode) {
        [self.delegate nativeCustomEvent:self didFailToLoadAdWithError:MPNativeAdNSErrorForNoInventory()];
    } else {
        [self.delegate nativeCustomEvent:self didFailToLoadAdWithError:MPNativeAdNSErrorForInvalidAdServerResponse(@"Facebook ad load error")];
    }
}

@end

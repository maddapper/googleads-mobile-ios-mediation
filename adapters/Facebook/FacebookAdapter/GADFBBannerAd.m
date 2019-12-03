// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADFBBannerAd.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#import "GADFBAdapterDelegate.h"
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"

/// Converts ad size from Google Mobile Ads SDK to ad size interpreted by Facebook Audience Network.
static FBAdSize GADFBAdSizeFromAdSize(GADAdSize gadAdSize) {
  CGSize gadAdCGSize = CGSizeFromGADAdSize(gadAdSize);
  GADAdSize banner50 =
      GADAdSizeFromCGSize(CGSizeMake(gadAdCGSize.width, kFBAdSizeHeight50Banner.size.height));
  GADAdSize banner90 =
      GADAdSizeFromCGSize(CGSizeMake(gadAdCGSize.width, kFBAdSizeHeight90Banner.size.height));
  GADAdSize mRect =
      GADAdSizeFromCGSize(CGSizeMake(gadAdCGSize.width, kFBAdSizeHeight250Rectangle.size.height));
  GADAdSize interstitial = GADAdSizeFromCGSize(kFBAdSizeInterstitial.size);
  NSArray *potentials = @[
    NSValueFromGADAdSize(banner50), NSValueFromGADAdSize(banner90), NSValueFromGADAdSize(mRect),
    NSValueFromGADAdSize(interstitial)
  ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);
  CGSize size = CGSizeFromGADAdSize(closestSize);
    
  FBAdSize fbSize;
  if (size.height == kFBAdSizeHeight50Banner.size.height) {
      fbSize = kFBAdSize320x50;
  } else if (size.height == kFBAdSizeHeight90Banner.size.height) {
      fbSize.size = CGSizeZero;
  } else if (size.height == kFBAdSizeHeight250Rectangle.size.height) {
      fbSize.size = CGSizeMake(300, 250);
  } else if (CGSizeEqualToSize(size, kFBAdSizeInterstitial.size)) {
      fbSize.size = CGSizeZero;
  } else {
      fbSize.size = CGSizeZero;
  }
    
  return fbSize;
}

@implementation GADFBBannerAd {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Banner ad obtained from Facebook's Audience Network.
  FBAdView *_bannerAd;

  /// Handles delegate notifications from bannerAd.
  GADFBAdapterDelegate *_adapterDelegate;
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;

    _adapterDelegate = [[GADFBAdapterDelegate alloc] initWithAdapter:adapter connector:connector];
  }
  return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
//  NSLog(@"Serving Facebook Audience Network banner.");
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongConnector || !strongAdapter) {
    return;
  }

  NSError *error = nil;
  FBAdSize size = GADFBAdSizeFromAdSize(adSize);

  // size translation error
  if (CGSizeEqualToSize(size.size, CGSizeZero)) {
    error = GADFBErrorWithDescription([NSString stringWithFormat:@"Invalid size for Facebook mediation adapter. Size: %@",
                                       NSStringFromGADAdSize(adSize)]);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  // -[FBAdView initWithPlacementID:adSize:rootViewController:] throws an NSInvalidArgumentException
  // if the root view controller is nil.
  UIViewController *rootViewController = [strongConnector viewControllerForPresentingModalView];
  if (!rootViewController) {
    error = GADFBErrorWithDescription(@"Root view controller cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  // -[FBAdView initWithPlacementID:adSize:rootViewController:] throws an NSInvalidArgumentException
  // if the placement ID is nil.
  NSString *placementID = [strongConnector publisherId];
  if (!placementID) {
    error = GADFBErrorWithDescription(@"Placement ID cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _bannerAd = [[FBAdView alloc] initWithPlacementID:placementID
                                             adSize:size
                                 rootViewController:rootViewController];
//    NSLog(@"placementID: %@", placementID);
//    NSLog(@"GADsize: %@", NSStringFromCGSize(adSize.size));
//    NSLog(@"FBsize: %@", NSStringFromCGSize(size.size));
  if (!_bannerAd) {
    NSString *description = [NSString
        stringWithFormat:@"%@ failed to initialize.", NSStringFromClass([FBAdView class])];
    NSError *error = GADFBErrorWithDescription(description);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

    [_bannerAd disableAutoRefresh];
  _bannerAd.delegate = _adapterDelegate;

  if (size.size.width < 0) {
    _adapterDelegate.finalBannerSize = adSize.size;
  }
  GADFBConfigureMediationService();
  [_bannerAd loadAd];
}

- (void)stopBeingDelegate {
  _adapterDelegate = nil;
}

+ (FBAdSize)fBAdSizeFromGADAdSize:(GADAdSize)adSize {
    return GADFBAdSizeFromAdSize(adSize);
}

@end

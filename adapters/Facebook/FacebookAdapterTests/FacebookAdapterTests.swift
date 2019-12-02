//
//  FacebookAdapterTests.swift
//  FacebookAdapterTests
//
//  Created by Dean Chang on 12/2/19.
//  Copyright © 2019 Google. All rights reserved.
//

import XCTest
@testable import FacebookAdapter
import FBAudienceNetwork
import GoogleMobileAds

class FacebookAdapterTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStandardBannerSize() {
        let fbSize = GADFBBannerAd.fBAdSize(from: kGADAdSizeBanner)
        XCTAssertTrue(fbSize.size.equalTo(CGSize(width: 320, height: 50)))
    }
    
    func testMediumRectSize() {
        let fbSize = GADFBBannerAd.fBAdSize(from: kGADAdSizeMediumRectangle)
        XCTAssertTrue(fbSize.size.equalTo(CGSize(width: 300, height: 250)))
    }
    
    func testUnsupportedSize() {
        let fbSize = GADFBBannerAd.fBAdSize(from: kGADAdSizeLargeBanner)
        let isValid: Bool = fbSize.size.equalTo(CGSize(width: 300, height: 250)) ||
            fbSize.size.equalTo(CGSize(width: 320, height: 50))
        XCTAssertFalse(isValid)
    }
}

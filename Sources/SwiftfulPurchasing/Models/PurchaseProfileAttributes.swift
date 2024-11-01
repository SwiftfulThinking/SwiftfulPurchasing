//
//  PurchaseProfileAttributes.swift
//  SwiftfulPurchasing
//
//  Created by Nick Sarno on 11/1/24.
//
import Foundation

public struct PurchaseProfileAttributes: Sendable {
    // User Profile attributes
    public let email: String?
    public let phoneNumber: String?
    public let displayName: String?
    public let pushToken: String?
    
    // Dependencies & Integration attributes
    public let adjustId: String?
    public let appsFlyerId: String?
    public let facebookAnonymousId: String?
    public let mParticleId: String?
    public let oneSignalId: String?
    public let airshipChannelId: String?
    public let cleverAppId: String?
    public let kochavaDeviceId: String?
    public let mixpanelDistinctId: String?
    public let firebaseAppInstanceId: String?
    public let brazeAliasName: String?
    public let brazeAliasLabel: String?
    
    // Install attributes
    
    /// Install campaign for the user (ie. utm_source=facebook&utm_campaign=spring_sale)
    public let installMediaSource: String?
    
    /// Install ad group for the user
    public let installAdGroup: String?
    
    /// Install ad for the user
    public let installAd: String?
    
    /// Install keyword for the user
    public let installKeyword: String?
    
    /// Install ad creative for the user
    public let installCreative: String?
    
    public init(
        email: String? = nil,
        phoneNumber: String? = nil,
        displayName: String? = nil,
        pushToken: String? = nil,
        adjustId: String? = nil,
        appsFlyerId: String? = nil,
        facebookAnonymousId: String? = nil,
        mParticleId: String? = nil,
        oneSignalId: String? = nil,
        airshipChannelId: String? = nil,
        cleverAppId: String? = nil,
        kochavaDeviceId: String? = nil,
        mixpanelDistinctId: String? = nil,
        firebaseAppInstanceId: String? = nil,
        brazeAliasName: String? = nil,
        brazeAliasLabel: String? = nil,
        installMediaSource: String? = nil,
        installAdGroup: String? = nil,
        installAd: String? = nil,
        installKeyword: String? = nil,
        installCreative: String? = nil
    ) {
        self.email = email
        self.phoneNumber = phoneNumber
        self.displayName = displayName
        self.pushToken = pushToken
        self.adjustId = adjustId
        self.appsFlyerId = appsFlyerId
        self.facebookAnonymousId = facebookAnonymousId
        self.mParticleId = mParticleId
        self.oneSignalId = oneSignalId
        self.airshipChannelId = airshipChannelId
        self.cleverAppId = cleverAppId
        self.kochavaDeviceId = kochavaDeviceId
        self.mixpanelDistinctId = mixpanelDistinctId
        self.firebaseAppInstanceId = firebaseAppInstanceId
        self.brazeAliasName = brazeAliasName
        self.brazeAliasLabel = brazeAliasLabel
        self.installMediaSource = installMediaSource
        self.installAdGroup = installAdGroup
        self.installAd = installAd
        self.installKeyword = installKeyword
        self.installCreative = installCreative
    }
}

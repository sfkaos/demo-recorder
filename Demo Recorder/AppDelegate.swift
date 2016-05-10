//
//  AppDelegate.swift
//  Demo Recorder
//
//  Created by Peter Sobot on 1/12/15.
//  Copyright (c) 2015 The Working Group. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    //  MARK: Application Lifecycle

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        //saveNSLogToFile()
        configureAWS()

        return true
    }

    //  MARK: Helpers

    func configureAWS() {
       // AWSLogger.defaultLogger().logLevel = AWSLogLevel.Debug
		let config = AWSServiceConfiguration(
			region: AWSRegionType.USEast1,
			credentialsProvider: AWSStaticCredentialsProvider(
				accessKey: Secrets.AWSAccessKey,
				secretKey: Secrets.AWSSecretKey
			)
		)
		
		
        let serviceManager = AWSServiceManager.defaultServiceManager()
		serviceManager.defaultServiceConfiguration = config
    }

    func saveNSLogToFile() {
        let docDirectory: NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as NSString
        let logpath = docDirectory.stringByAppendingPathComponent("ns.log")
        freopen(logpath.cStringUsingEncoding(NSASCIIStringEncoding)!, "a+", stderr)
    }

}


//
//  Secrets.swift
//  Demo Recorder
//
//  Created by Peter Sobot on 1/26/15.
//  Copyright (c) 2015 The Working Group. All rights reserved.
//
//  Replace the constants in this file with your own constants
//  before building this project.
//

import Foundation

class Secrets {

    //  This is the S3 bucket that videos will be uploaded to.
    class var AWSS3Bucket: NSString { return "mybucket" }

    //  This is the prefix that videos will be uploaded to in that bucket.
    //  With these defaults, videos will be saved in s3://mybucket/foo/bar/.
    //  Videos are titled by start time, and their filenames look like: 2015-01-01 00:00:00.mp4
    class var AWSS3KeyPrefix: NSString { return "foo/bar" }

    //  AWS access credentials.
    //  It is strongly suggested that you generate a separate IAM user for this application,
    //  and that you give that user only the PutObject permission on the S3 bucket listed above.
    class var AWSAccessKey: NSString { return "AKI-----------------" }
    class var AWSSecretKey: NSString { return "-------------------------/-/------------" }

    Remove this line once you've added in your keys above.
}

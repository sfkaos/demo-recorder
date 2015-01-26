//
//  NSURL+Extensions.swift
//  Demo Recorder
//
//  Created by Peter Sobot on 1/26/15.
//  Copyright (c) 2015 The Working Group. All rights reserved.
//

import Foundation

let CHUNK_SIZE = 8192

extension NSURL {
    func computeMD5() -> NSString {
        var error: NSError?

        let handle: NSFileHandle = NSFileHandle(forReadingFromURL: self, error: &error)!

        let md5 = UnsafeMutablePointer<CC_MD5_CTX>.alloc(1)
        CC_MD5_Init(md5)

        while (true) {
            let fileData = handle.readDataOfLength(CHUNK_SIZE)
            CC_MD5_Update(md5, fileData.bytes, CC_LONG(fileData.length));
            if fileData.length == 0 {
                break
            }
        }

        var digest = Array<UInt8>(count:Int(CC_MD5_DIGEST_LENGTH), repeatedValue:0)

        CC_MD5_Final(&digest, md5)
        md5.dealloc(1)

        return digest.reduce("", combine: { (string: NSString, digit: UInt8) -> NSString in
            return string.stringByAppendingString(NSString(format: "%02x", digit))
        })
    }
}
//
//  UIInterfaceOrientation+Extensions.swift
//  Demo Recorder
//
//  Created by Peter Sobot on 1/16/15.
//  Copyright (c) 2015 The Working Group. All rights reserved.
//

import Foundation
import AVFoundation

extension UIInterfaceOrientation {
    var captureOrientation: AVCaptureVideoOrientation {
        get {
            switch (self) {
            case UIInterfaceOrientation.LandscapeLeft:
                return AVCaptureVideoOrientation.LandscapeLeft;
            case UIInterfaceOrientation.LandscapeRight:
                return AVCaptureVideoOrientation.LandscapeRight;
            case UIInterfaceOrientation.Portrait:
                return AVCaptureVideoOrientation.Portrait;
            case UIInterfaceOrientation.PortraitUpsideDown:
                return AVCaptureVideoOrientation.PortraitUpsideDown;
            default:
                return AVCaptureVideoOrientation.Portrait;
            }
        }
    }
}
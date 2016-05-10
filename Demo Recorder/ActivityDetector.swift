//
//  ActivityDetector.swift
//  Demo Recorder
//
//  Created by Peter Sobot on 1/27/15.
//  Copyright (c) 2015 The Working Group. All rights reserved.
//

import Foundation

@objc protocol ActivityDetectorDelegate {
    /*!
    @method currentSensorValue
    @abstract
    Returns the current sensor value (be it from a microphone, light sensor, or whatever)
    to feed to the ActivityDetector.

    @result
    A double value representing an arbitrary sensor value.
    */
    func currentSensorValue() -> Double

    /*!
    @method activityWasDetected
    @abstract
    Called when activity is detected by the ActivityDetector.
    This method is triggered on the "rising edge" of activity.
    */
    optional func activityWasDetected()

    /*!
    @method inactivityWasDetected
    @abstract
    Called when a lack of activity is detected by the ActivityDetector.
    This method is triggered on the "falling edge" of activity.
    */
    optional func inactivityWasDetected()

    /*!
    @method secondsLeftUntilTransitionChanged
    @abstract
    Called when the number of seconds left until a mode transition
    changes. This method can be used to update the UI.
    */
    optional func secondsLeftUntilTransitionChanged()
}

class ActivityDetector {
    //  MARK: Data Types
    enum Mode {
        case Inactive
        case Active
    }

    //  MARK: Initialization & Lifecycle
    var mode: Mode = Mode.Inactive
    let pollInterval: NSTimeInterval = 0.6
    var measuredConsecutiveReadings: Int = 0

    var delegate: ActivityDetectorDelegate?
    init() {

        NSNotificationCenter.defaultCenter().addObserver(self,
		selector:#selector(ActivityDetector.updateCalibrationParameters),
            name:NSUserDefaultsDidChangeNotification,
            object:nil
        )
    }

    deinit {
        stopDetecting()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: Calibration Parameters & NSUserDefaults
    var threshold: Double = -10;
    var secondsRequiredToStart: NSTimeInterval = 0.6;
    var secondsRequiredToStop: NSTimeInterval = 10;

	@objc func updateCalibrationParameters() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var value: Double = 0

        value = userDefaults.doubleForKey("DRThreshold")
        if value != 0 {
            threshold = value
        }

        value = userDefaults.doubleForKey("DRMinimumTriggerTime")
        if value != 0 {
            secondsRequiredToStart = value
        }

        value = userDefaults.doubleForKey("DRMinimumRecordTime")
        if value != 0 {
            secondsRequiredToStop = value
        }
    }

    //  MARK: Properties
    var secondsLeftUntilTransition: NSTimeInterval {
        get {
            let elapsedSeconds = (NSTimeInterval(measuredConsecutiveReadings) * pollInterval)

            switch (mode) {
            case Mode.Inactive:
                return secondsRequiredToStart - elapsedSeconds
            case Mode.Active:
                return secondsRequiredToStop - elapsedSeconds
            }
        }
    }

    //  MARK: Public Functions
    var timer: NSTimer?
    func startDetecting() {
        stopDetecting()
        timer = NSTimer.scheduledTimerWithTimeInterval(
            pollInterval,
            target: self,
            selector: #selector(ActivityDetector.pollSensor),
            userInfo: nil,
            repeats: true
        )
    }

    func stopDetecting() {
        if let existingTimer = timer {
            existingTimer.invalidate()
        }
    }


    //  MARK: Private Functions
    @objc private func pollSensor() {
        if let delegate = self.delegate {
            let value = delegate.currentSensorValue()

            var exceedsThreshold: Bool = false
            switch (mode) {
            case Mode.Inactive:
                exceedsThreshold = value > threshold
            case Mode.Active:
                exceedsThreshold = value < threshold
            }

            let previousNumberOfReadings = measuredConsecutiveReadings
            if (exceedsThreshold) {
                measuredConsecutiveReadings += 1
            } else {
                measuredConsecutiveReadings = 0
            }

            if previousNumberOfReadings != measuredConsecutiveReadings {
                delegate.secondsLeftUntilTransitionChanged?()
            }

            let secondsElapsed = NSTimeInterval(measuredConsecutiveReadings) * pollInterval

            switch (mode) {
            case Mode.Inactive:
                if secondsElapsed > secondsRequiredToStart {
                    mode = Mode.Active
                    delegate.activityWasDetected?()
                    measuredConsecutiveReadings = 0
                    delegate.secondsLeftUntilTransitionChanged?()
                }

            case Mode.Active:
                if secondsElapsed > secondsRequiredToStop {
                    mode = Mode.Inactive
                    delegate.inactivityWasDetected?()
                    measuredConsecutiveReadings = 0
                    delegate.secondsLeftUntilTransitionChanged?()
                }
            }
        }
    }
}
//
//  ViewController.swift
//  Demo Recorder
//
//  Created by Peter Sobot on 1/12/15.
//  Copyright (c) 2015 The Working Group. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    // MARK: Views
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var uploadLabel: UILabel!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var cameraPreviewView: UIView!

    // MARK: Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:Selector("updateCalibrationParameters"),
            name:NSUserDefaultsDidChangeNotification,
            object:nil
        )

        stopRecording()

        let backCamera: AVCaptureDevice? = AVCaptureDevice.devices().find {
            $0.hasMediaType(AVMediaTypeVideo)
         && $0.position == AVCaptureDevicePosition.Back
        } as? AVCaptureDevice;

        if let camera = backCamera {
            beginSession(camera: camera)
        } else {
            UIAlertView(
                title: "Could not find cameras",
                message: "This iOS device has no cameras.",
                delegate: nil,
                cancelButtonTitle: "OK"
            ).show()
        }
    }

    override func viewDidLayoutSubviews() {
        if let layer = previewLayer {
            layer.frame = cameraPreviewView.bounds
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateCalibrationParameters()
    }


    // MARK: Calibration Parameters & NSUserDefaults
    var threshold: Double = -10;
    var secondsRequiredToStart: NSTimeInterval = 0.6;
    var secondsRequiredToStop: NSTimeInterval = 10;

    func updateCalibrationParameters() {
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

    // MARK: Video Capture
    enum Mode {
        case WaitingForAudioActivity
        case Recording
    }

    let captureSession = AVCaptureSession()

    let sessionPreset = AVCaptureSessionPreset1280x720
    let pollInterval: NSTimeInterval = 0.1

    var measuredConsecutiveReadings: Int = 0;
    var mode: Mode = Mode.WaitingForAudioActivity
    var movieOutput: AVCaptureMovieFileOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?

    func secondsLeftUntilTransition() -> NSTimeInterval {
        let elapsedSeconds = (NSTimeInterval(measuredConsecutiveReadings) * pollInterval)

        switch (mode) {
        case Mode.WaitingForAudioActivity:
            return secondsRequiredToStart - elapsedSeconds
        case Mode.Recording:
            return secondsRequiredToStop - elapsedSeconds
        }
    }

    func beginSession(#camera: AVCaptureDevice) {
        captureSession.sessionPreset = sessionPreset

        var err : NSError? = nil

        captureSession.addInput(AVCaptureDeviceInput(device: camera, error: &err))
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }

        let microphone = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        let microphoneInput = AVCaptureDeviceInput(device: microphone, error: &err)
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }

        captureSession.addInput(microphoneInput)

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if let layer = previewLayer {
            layer.frame = CGRect(origin: CGPointZero, size: cameraPreviewView.frame.size)
            cameraPreviewView.layer.addSublayer(layer)

            let previewLayerConnection: AVCaptureConnection = layer.connection

            if (previewLayerConnection.supportsVideoOrientation) {
                let orientation = UIApplication.sharedApplication().statusBarOrientation
                previewLayerConnection.videoOrientation = orientation.captureOrientation
            }
        }

        movieOutput = AVCaptureMovieFileOutput();
        captureSession.addOutput(movieOutput);
        let videoConnection = movieOutput!.connectionWithMediaType(AVMediaTypeVideo)

        if (videoConnection.supportsVideoOrientation) {
            let orientation = UIApplication.sharedApplication().statusBarOrientation
            videoConnection.videoOrientation = orientation.captureOrientation
        }

        captureSession.startRunning()
        NSTimer.scheduledTimerWithTimeInterval(
            pollInterval,
            target: self,
            selector: Selector("readPowerLevel"),
            userInfo: nil,
            repeats: true
        )
    }

    func readPowerLevel() {
        if let output = movieOutput {
            let connection: AVCaptureConnection = output.connectionWithMediaType(AVMediaTypeAudio) as AVCaptureConnection

            if let channel = connection.audioChannels.first as? AVCaptureAudioChannel {
                var exceedsThreshold: Bool = false

                switch (mode) {
                case Mode.WaitingForAudioActivity:
                    exceedsThreshold = Double(channel.averagePowerLevel) > threshold
                case Mode.Recording:
                    exceedsThreshold = Double(channel.averagePowerLevel) < threshold
                }

                if (exceedsThreshold) {
                    measuredConsecutiveReadings++
                } else {
                    measuredConsecutiveReadings = 0
                }
            }
        }

        let secondsElapsed = NSTimeInterval(measuredConsecutiveReadings) * pollInterval

        switch (mode) {
        case Mode.WaitingForAudioActivity:
            if secondsElapsed > secondsRequiredToStart {
                startRecording()
                measuredConsecutiveReadings = 0
            }
            countdownLabel.text = NSString(format: "%2.2f seconds of audio required to start", secondsLeftUntilTransition())
        case Mode.Recording:
            if secondsElapsed > secondsRequiredToStop {
                stopRecording()
                measuredConsecutiveReadings = 0
            }
            countdownLabel.text = NSString(format: "%2.2f seconds of recording left", secondsLeftUntilTransition())
        }
    }

    func startRecording() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory, .UserDomainMask, true
        ).first as NSString

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone.localTimeZone()

        let filename = dateFormatter.stringFromDate(NSDate())

        let filePath: NSString = documentsPath.stringByAppendingPathComponent(filename + ".mp4")
        let fileURL: NSURL = NSURL(fileURLWithPath: filePath)!

        if let output = movieOutput {
            NSLog("Recording to %@", fileURL);
            output.startRecordingToOutputFileURL(fileURL, recordingDelegate:self);
            mode = Mode.Recording
            stateLabel.text = "Recording..."
            updateViewColor()
        } else {
            stateLabel.text = "Could not start recording."
        }
    }

    func stopRecording() {
        if let movie = movieOutput {
            movie.stopRecording()
        }
        mode = Mode.WaitingForAudioActivity
        stateLabel.text = "Waiting for audio activity..."
        updateViewColor()
    }

    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        if error == nil {
            NSLog("Capture output did finish recording to %@", outputFileURL);
            upload(outputFileURL);
        } else {
            NSLog("Capture output did finish recording with error %@", error);
        }
    }

    //  MARK: Amazon S3 Interface
    var transferManager: AWSS3TransferManager?

    func upload(outputFileURL: NSURL!) {
        if transferManager == nil {
            transferManager = AWSS3TransferManager.defaultS3TransferManager()
        }

        let request = AWSS3TransferManagerUploadRequest()
        request.bucket = Secrets.AWSS3Bucket
        request.key = Secrets.AWSS3KeyPrefix.stringByAppendingPathComponent(outputFileURL.lastPathComponent!)
        request.body = outputFileURL
        request.storageClass = AWSS3StorageClass.ReducedRedundancy
        request.uploadProgress = ({
            (bytesSent: Int64, totalBytesSent: Int64,  totalBytesExpectedToSend: Int64) in
            dispatch_async(dispatch_get_main_queue(), {
                let percent = Double(totalBytesSent) / Double(totalBytesExpectedToSend);
                self.uploads.setValue(percent, forKey: request.key)
                self.updateUploadLabel()
            })
        })

        uploads.setValue(0.0, forKey: request.key);
        updateUploadLabel();

        transferManager!.upload(request).continueWithBlock({ (task: BFTask!) -> AnyObject! in
            if task.error != nil {
                if task.error.domain == AWSS3TransferManagerErrorDomain {
                    switch task.error.code {
                    case AWSS3TransferManagerErrorType.Cancelled.rawValue:
                        NSLog("Upload cancelled!");
                    case AWSS3TransferManagerErrorType.Paused.rawValue:
                        NSLog("Upload paused!");
                    default:
                        NSLog("Error: %@", task.error);

                        //  Retry the upload after 5 seconds
                        let delaySeconds = 5.0
                        let delayTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW,
                            Int64(delaySeconds * Double(NSEC_PER_SEC)))
                        dispatch_after(delayTime, dispatch_get_main_queue()) {
                            self.upload(outputFileURL);
                        }
                    }
                } else {
                    NSLog("Unknown error while uploading: %@", task.error);
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.uploads.setValue(-1.0, forKey:request.key);
                });
            } else {
                NSLog("File %@ uploaded successfully.", outputFileURL);

                var deleteError: NSError?
                NSFileManager.defaultManager().removeItemAtURL(outputFileURL, error: &deleteError)
                if let error = deleteError {
                    NSLog("Could not delete %@: %@", outputFileURL, error)
                }

                dispatch_async(dispatch_get_main_queue(), {
                    self.uploads.removeObjectForKey(request.key);
                });
            }

            dispatch_async(dispatch_get_main_queue(), {
                self.updateUploadLabel();
            });

            return nil;
        })
    }

    //  MARK: View Management

    let uploads = NSMutableDictionary()
    func updateUploadLabel() {
        var text = ""
        if uploads.count > 0 {
            text = "Uploading: "
        }
        var count = 0
        for (key, progress) in uploads {
            if let key: NSString = key as? NSString {
                if let progress: Double = progress as? Double {
                    if count > 0 {
                        text = text.stringByAppendingString(", ")
                    }
                    text = text.stringByAppendingString(NSString(format:"%@: %2.2f%%", key, progress * 100))
                    count++
                }
            }
        }
        uploadLabel.text = text
    }

    func updateViewColor() {
        switch (mode) {
        case Mode.WaitingForAudioActivity:
            colorView.backgroundColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1)
        case Mode.Recording:
            colorView.backgroundColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1)
        }
    }
}


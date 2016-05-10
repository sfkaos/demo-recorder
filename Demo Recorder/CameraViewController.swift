//
//  ViewController.swift
//  Demo Recorder
//
//  Created by Peter Sobot on 1/12/15.
//  Copyright (c) 2015 The Working Group. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, ActivityDetectorDelegate {
    // MARK: Views
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var uploadLabel: UILabel!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var cameraPreviewView: UIView!

    // MARK: Globals & Lifecycle
    let activityDetector = ActivityDetector()

    override func viewDidLoad() {
        super.viewDidLoad()
        stopRecording()

        let backCamera: AVCaptureDevice? = AVCaptureDevice.devices().find {
            $0.hasMediaType(AVMediaTypeVideo)
         && $0.position == AVCaptureDevicePosition.Back
        } as? AVCaptureDevice;

        if let camera = backCamera {
            beginSession(camera)
        } else {
            UIAlertView(
                title: "Could not find cameras",
                message: "This iOS device has no cameras.",
                delegate: nil,
                cancelButtonTitle: "OK"
            ).show()
        }
    }

    // MARK: Video Capture
    let captureSession = AVCaptureSession()

    let sessionPreset = AVCaptureSessionPreset1280x720
    var movieOutput: AVCaptureMovieFileOutput?

    func beginSession(camera: AVCaptureDevice) {
		
        activityDetector.delegate = self

        captureSession.sessionPreset = sessionPreset
		
		do {
			let input = try AVCaptureDeviceInput(device: camera)
			captureSession.addInput(input)
		}
		catch _ {
			print("Unable to add AVCaptureDeviceInput for camera")
		}

        let microphone = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
		do {
			let microphoneInput = try AVCaptureDeviceInput(device: microphone)
			captureSession.addInput(microphoneInput)
		}
		catch _ {
			print("Unable to add microphone for camera")
		}

        cameraPreviewView.layoutIfNeeded()
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(origin: CGPointZero, size: cameraPreviewView.frame.size)
        cameraPreviewView.layer.addSublayer(previewLayer)

        let previewLayerConnection: AVCaptureConnection = previewLayer.connection

        if (previewLayerConnection.supportsVideoOrientation) {
            let orientation = UIApplication.sharedApplication().statusBarOrientation
            previewLayerConnection.videoOrientation = orientation.captureOrientation
        }

        movieOutput = AVCaptureMovieFileOutput();
        captureSession.addOutput(movieOutput);
        let videoConnection = movieOutput!.connectionWithMediaType(AVMediaTypeVideo)

        if (videoConnection.supportsVideoOrientation) {
            let orientation = UIApplication.sharedApplication().statusBarOrientation
            videoConnection.videoOrientation = orientation.captureOrientation
        }

        captureSession.startRunning()
        activityDetector.startDetecting()
    }

    func startRecording() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory, .UserDomainMask, true
        ).first as String?

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone.localTimeZone()

        let filename = dateFormatter.stringFromDate(NSDate())

		let folderURL:NSURL = NSURL(fileURLWithPath: documentsPath!)
		
        let fileURL: NSURL = folderURL.URLByAppendingPathComponent(filename + ".mp4")

        if let output = movieOutput {
            NSLog("Recording to %@", fileURL);
            output.startRecordingToOutputFileURL(fileURL, recordingDelegate:self);
            updateView()
        } else {
            stateLabel.text = "Could not start recording."
        }
    }

    func stopRecording() {
        if let movie = movieOutput {
            movie.stopRecording()
        }

        updateView()
    }

    //  MARK: AVCaptureFileOutputRecordingDelegate Implementation

    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
		if error == nil {
            NSLog("Capture output did finish recording to %@", outputFileURL);
            upload(outputFileURL);
        } else {
            NSLog("Capture output did finish recording with error %@", error);
        }
    }

    //  MARK: Amazon S3 Interface

    func upload(outputFileURL: NSURL!) {
		
		let transferManager:AWSS3TransferManager = AWSS3TransferManager.defaultS3TransferManager()
		
        let request = AWSS3TransferManagerUploadRequest()
        request.bucket = Secrets.AWSS3Bucket
        request.key = Secrets.AWSS3KeyPrefix + "/" + outputFileURL.lastPathComponent!
        request.body = outputFileURL
        request.storageClass = AWSS3StorageClass.ReducedRedundancy
        request.uploadProgress = ({
            (bytesSent: Int64, totalBytesSent: Int64,  totalBytesExpectedToSend: Int64) in
            dispatch_async(dispatch_get_main_queue(), {
                let percent = Double(totalBytesSent) / Double(totalBytesExpectedToSend);
                self.uploads.setValue(percent, forKey: request.key!)
                self.updateUploadLabel()
            })
        })

        uploads.setValue(0.0, forKey: request.key!);
        updateUploadLabel();
		
		transferManager.upload(request).continueWithBlock({ (task: AWSTask) -> AnyObject! in
			if task.error != nil {
				if task.error!.domain == AWSS3TransferManagerErrorDomain {
					switch task.error!.code {
					case AWSS3TransferManagerErrorType.Cancelled.rawValue:
						print("Upload cancelled!");
					case AWSS3TransferManagerErrorType.Paused.rawValue:
						print("Upload paused!");
					default:
						print("Error: %@", task.error);
						
						//  Retry the upload after 5 seconds
						let delaySeconds = 5.0
						let delayTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW,
							Int64(delaySeconds * Double(NSEC_PER_SEC)))
						dispatch_after(delayTime, dispatch_get_main_queue()) {
							self.upload(outputFileURL);
						}
					}
				} else {
					print("Unknown error while uploading: %@", task.error);
				}
				dispatch_async(dispatch_get_main_queue(), {
					self.uploads.setValue(-1.0, forKey:request.key!);
				});
			} else {
				print("File %@ uploaded successfully. %@", outputFileURL, task.exception);
				
				do {
					try NSFileManager.defaultManager().removeItemAtURL(outputFileURL)
				}
				catch _ {
					print("Could not delete %@", outputFileURL)
				}
				
				dispatch_async(dispatch_get_main_queue(), {
					self.uploads.removeObjectForKey(request.key!);
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
                    text = text.stringByAppendingString(String(format:"%@: %2.2f%%", key, progress * 100))
                    count += 1
                }
            }
        }
        uploadLabel.text = text
    }

    func updateView() {
		
        switch (activityDetector.mode) {
        case ActivityDetector.Mode.Inactive:
            stateLabel.text = "Waiting for audio activity..."
            countdownLabel.text = String(format: "%2.2f seconds of sound required to trigger...", activityDetector.secondsLeftUntilTransition)
            colorView.backgroundColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1)
        case ActivityDetector.Mode.Active:
            stateLabel.text = "Recording..."
            countdownLabel.text = String(format: "%2.2f seconds of silence required to stop...", activityDetector.secondsLeftUntilTransition)
            colorView.backgroundColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1)
        }
    }

    //  MARK: ActivityDetectorDelegate Implementation
    func currentSensorValue() -> Double {
		
        if let output = movieOutput {
            let connection = output.connectionWithMediaType(AVMediaTypeAudio) as AVCaptureConnection
            let powerLevels = connection.audioChannels.map {($0 as! AVCaptureAudioChannel).averagePowerLevel}

            switch (powerLevels.count) {
            case 0:
                return 0
            default:
                let sum = powerLevels.reduce(Float(0), combine: +)
                return Double(sum / Float(powerLevels.count))
            }
        }
		return 0
    }

    func secondsLeftUntilTransitionChanged() {
        updateView()
    }

    func activityWasDetected() {
        startRecording()
    }

    func inactivityWasDetected() {
        stopRecording()
    }
}


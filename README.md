![A logo.](https://cloud.githubusercontent.com/assets/213293/5906410/5db23cfe-a565-11e4-8cd0-ae7427e570f7.png)

**Demo Recorder** turns any iOS device with a back camera (iPhone, iPod Touch 4+, iPad 2+) into an automatic video camera, triggered by an audio signal. Simply mount an iOS device facing something you want to monitor, open Demo Recorder, and videos will automatically be recorded and uploaded to [Amazon S3](http://aws.amazon.com/s3/) when audio is detected.

Demo Recorder is most useful when the iOS device used is connected to a microphone or PA system. (You can buy [RCA-to-TRRS cables](http://www.kvconnection.com/product-p/km-iphone-micp-a22.htm) for relatively cheap that will allow you to patch the output of a mixer into your device.)

## Installation

    git clone git@github.com:twg/demo-recorder
    cd demo-recorder
    cp "Demo Recorder/Secrets.example.swift" "Demo Recorder/Secrets.swift"
    open "Demo Recorder.xcworkspace"
    
After cloning and setting up the repo, make sure you add your own Amazon S3 keys, bucket name, and bucket prefix to [`Secrets.swift`](https://github.com/twg/demo-recorder/blob/master/Demo%20Recorder/Secrets.example.swift).

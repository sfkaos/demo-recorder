![A logo.](https://cloud.githubusercontent.com/assets/213293/5906410/5db23cfe-a565-11e4-8cd0-ae7427e570f7.png)

**Demo Recorder** turns any iOS device with a back camera (iPhone, iPod Touch 4+, iPad 2+) into an automatic video camera, triggered by an audio signal. Simply mount an iOS device facing something you want to monitor, open Demo Recorder, and videos will automatically be recorded and uploaded to [Amazon S3](http://aws.amazon.com/s3/) when audio is detected.

![A screenshot.](https://cloud.githubusercontent.com/assets/213293/5978951/8a0c0b9a-a871-11e4-8c34-aa4af48e4205.PNG)

Demo Recorder is most useful when the iOS device used is connected to a microphone or PA system. (You can buy [RCA-to-TRRS cables](http://www.kvconnection.com/product-p/km-iphone-micp-a22.htm) for relatively cheap that will allow you to patch the output of a mixer into your device.)

## Installation

    git clone git@github.com:twg/demo-recorder
    cd demo-recorder
    cp "Demo Recorder/Secrets.example.swift" "Demo Recorder/Secrets.swift"
    open "Demo Recorder.xcworkspace"
    
After cloning and setting up the repo, make sure you add your own Amazon S3 keys, bucket name, and bucket prefix to [`Secrets.swift`](https://github.com/twg/demo-recorder/blob/master/Demo%20Recorder/Secrets.example.swift).

## S3 Setup

When using Demo Recorder, you'll want to set up a single Amazon IAM user
with independent credentials. These credentials can be given only the permissions required
to upload video files to a given bucket. Below is an example IAM policy that provides these permissions:

    {
      "Version": "2012-10-17",
      "Statement":[{
        "Effect": "Allow",
        "Action": "s3:ListAllMyBuckets",
        "Resource": ["arn:aws:s3:::*"]
      }, {
        "Effect": "Allow",
        "Action": "s3:PutObject",
        "Resource": ["arn:aws:s3:::mybucket",
                     "arn:aws:s3:::mybucket/*"]
        }
      ]
    }
    
## S3 Usage

Although Amazon S3 is very cheap online storage, video files - especially HD video captured by iOS devices - is also very big. When using iOS 8, the default 720p video preset records at a rate of approximately 5 GB per hour, which costs $0.12 USD per month to store at current Amazon Reduced-Redundancy rates.


## LICENSE

Demo Recorder is open-source software, licensed under the [MIT license](https://github.com/twg/demo-recorder/blob/master/LICENSE).

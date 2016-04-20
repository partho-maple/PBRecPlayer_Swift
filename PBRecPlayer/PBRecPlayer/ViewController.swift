//
//  ViewController.h
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/12/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//
import UIKit
import AVFoundation
import AVFoundation
import CoreBluetooth


class ViewController: UIViewController, AudioControllerDelegate {
    
    var iRTPDataLen: Int
    var isRunning: Bool
    
    @IBOutlet weak var startStopButton: UIButton!
    
    
    func StartAudio() {
        iosAudio.start()
        iosAudio.resetRTPQueue()
    }

    func StopAudio() {
        iosAudio.stop()
        iosAudio.resetRTPQueue()
    }

    var byteRTPDataToSend: UInt8

    override func viewDidLoad() {
        super.viewDidLoad()
        self.isRunning = false
        self.iRTPDataLen = 0
        iosAudio = AudioHandler()
        iosAudio.audioDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // Basically, it will a callback method which will be called after getting each trp packet.

    func receivedRtpWithData(pChRtp: UInt8, andLength len: Int) {
        var receivedRTPData: Byte
        var receivedRTPDataLength: Int = 0
        receivedRTPDataLength = len
        iosAudio.receiverAudio(receivedRTPData, WithLen: receivedRTPDataLength)
    }
    // This method will be called after pulling each recorded data block

    func recordedRTP(rtpData: Byte, andLenght len: Int) {
            /* Here we will send rtpData(recorded and encoded data to send) to the other end. We have encoder, recorded data into rtpData variable and it's length is into len variable */
        self.iRTPDataLen += len
        self.receivedRtpWithData(byteRTPDataToSend, andLength: self.iRTPDataLen)
        memset(byteRTPDataToSend, 0, 500)
        self.iRTPDataLen = 0
    }

    @IBAction func StartButtonTapped(sender: AnyObject) {
        if self.isRunning {
            self.isRunning = false
            self.StopAudio()
            self.startStopButton.setTitle("START", forState: .Normal)
        }
        else {
            self.isRunning = true
            self.StartAudio()
            self.startStopButton.setTitle("STOP", forState: .Normal)
        }
        self.StartAudio()
    }

}




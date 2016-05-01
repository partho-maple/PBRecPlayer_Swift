//
//  ViewController.swift
//  PBRecPlayer
//
//  Created by Partho Biswas on 5/1/16.
//  Copyright © 2016 Partho Biswas. All rights reserved.
//



import UIKit
import AVFoundation
import AVFoundation
import CoreBluetooth
import Swift


typealias Byte = UInt8


class ViewController: UIViewController, AudioControllerDelegate {
    
    var iRTPDataLen: CInt = 0
    var isRunning: CBool = false
    var byteRTPDataToSend: UInt8 = 0
    
    @IBOutlet weak var startStopButton: UIButton!
    
    
    func StartAudio() {
        AudioHandler.sharedInstance.start()
        AudioHandler.sharedInstance.resetRTPQueue()
    }
    
    func StopAudio() {
        AudioHandler.sharedInstance.stop()
        AudioHandler.sharedInstance.resetRTPQueue()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isRunning = false
        self.iRTPDataLen = 0
        AudioHandler.sharedInstance.audioDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Basically, it will a callback method which will be called after getting each trp packet.
    func receivedRtpWithData(pChRtp: UInt8, andLength len: CInt) {
        let receivedRTPData: Byte
        var receivedRTPDataLength: CInt = 0
        receivedRTPDataLength = len
        //        AudioHandler.sharedInstance().receiverAudio(receivedRTPData, WithLen: receivedRTPDataLength)  // Uncomment this line
    }
    
    
    func recordedRTP(rtpData: Byte, andLenght len: CInt) {
        /* Here we will send rtpData(recorded and encoded data to send) to the other end. We have encoder, recorded data into rtpData variable and it's length is into len variable */
        
        self.iRTPDataLen += len
        self.receivedRtpWithData(byteRTPDataToSend, andLength: self.iRTPDataLen)
        //        memset(byteRTPDataToSend, 0, 500)
        memset(&byteRTPDataToSend, 0, 500)
        self.iRTPDataLen = 0
    }
    
    
    @IBAction func StartButtonTapped(sender: AnyObject) {
        if self.isRunning {
            self.isRunning = false
            self.StopAudio()
            self.startStopButton.setTitle("START", forState: .Normal)
//            AudioMetering().stop()
        }
        else {
            self.isRunning = true
            self.StartAudio()
            self.startStopButton.setTitle("STOP", forState: .Normal)
//            AudioMetering().start()
        }
    }
    
    
}





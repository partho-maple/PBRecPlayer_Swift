//
//  AudioHandler.h
//  PBRecPlayer
//
//  Created by Partho Biswas on 21/04/16.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//

import UIKit
import Foundation
import AudioToolbox
import CoreAudio
import AVFoundation
import Swift

protocol AudioControllerDelegate {
    func recordedRTP(rtpData: Byte, andLenght len: CInt)
}


class AudioHandler: NSObject {
//    var audioUnit: AudioComponentInstance
//    var tempBuffer: AudioBuffer

    var recordedPCMBuffer: TPCircularBuffer
    var receivedPCMBuffer: TPCircularBuffer
    var audioDelegate: AudioControllerDelegate
    var g729EncoderDecoder: G729Wrapper

    var audioUnit:AudioUnit
    var tempBuffer:AudioBuffer

    var pcmRcordedData: BufferQueue

    var isRecordDataPullingThreadRunning: CBool
    var isAudioUnitRunning: CBool
    var isLocalRingBackToneEnabled: CBool
    var isLocalRingToneEnabled: CBool
    var isBufferClean: CBool

    class func sharedInstance() -> AudioHandler {
//        if sharedInstance == nil {
//            sharedInstance = AudioHandler()
//        }
//        return sharedInstance!
        
        return sharedAudioHandler;
    }

    func start() {
        if isAudioUnitRunning {
            return
        }
        
        //    This will enable the proximity monitoring.
        let device: UIDevice = UIDevice.currentDevice()
        device.proximityMonitoringEnabled = true
        g729EncoderDecoder.open()
        var status: OSStatus
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try! audioSession.setActive(true)
        try! audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.None)
        try! audioSession.setActive(true)
        checkStatus(status)
        status = AudioUnitInitialize(audioUnit)
        checkStatus(status)
        status = AudioOutputUnitStart(audioUnit)
        checkStatus(status)
        if !self.isRecordDataPullingThreadRunning {
            recorderThread = NSThread(target: self, selector: #selector(AudioHandler.recordDataPullingMethod), object: nil)
            self.isRecordDataPullingThreadRunning = true
            recorderThread.start()
        }
        isAudioUnitRunning = true
    }

    func stop() {
        if !isAudioUnitRunning {
            return
        }
        let device: UIDevice = UIDevice.currentDevice()
        device.proximityMonitoringEnabled = false
            var status: OSStatus
        status = AudioOutputUnitStop(audioUnit)
        checkStatus(status)
        try! AVAudioSession.sharedInstance().setActive(false)
        checkStatus(status)
        status = AudioUnitUninitialize(audioUnit)
        checkStatus(status)
        isRecordDataPullingThreadRunning = false
        isAudioUnitRunning = false
        g729EncoderDecoder.close()
    }

    func processAudio(bufferList: AudioBufferList) {
        var isRecordedBufferProduceBytes: CBool = false
        
        isRecordedBufferProduceBytes = TPCircularBufferProduceBytes(&recordedPCMBuffer, bufferList.mBuffers[0].mData, bufferList.mBuffers[0].mDataByteSize)
        if !isRecordedBufferProduceBytes {

        }
    }

    func receiverAudio(audio: Byte, WithLen len: CInt) {
        var isBufferProduceBytes: CBool = false
                do {
            var numberOfDecodedShorts: CInt = try g729EncoderDecoder.decodeWithG729(audio, andSize: len, andEncodedPCM: receivedShort)
            isBufferProduceBytes = TPCircularBufferProduceBytes(&receivedPCMBuffer, receivedShort, (numberOfDecodedShorts * 2))
        } catch let exception {
        }
        if !isBufferProduceBytes {

        }
    }

    func recordDataPullingMethod() {
            var availableBytes: CInt
        while self.isRecordDataPullingThreadRunning {
            var buffer: Int16 = TPCircularBufferTail(&recordedPCMBuffer, availableBytes)
            if availableBytes > 159 {
                var g729EncodedBytes: Byte
                var encodedLength: CInt = g729EncoderDecoder.encodeWithPCM(shortArray, andSize: 80, andEncodedG729: g729EncodedBytes)
                if encodedLength > 0 {
//                    if audioDelegate.respondsToSelector("recordedRTP:andLenght:") {
                        audioDelegate.recordedRTP(g729EncodedBytes, andLenght: encodedLength)
//                    }
                }
            }
        }
        recorderThread.cancel()
//        recorderThread = nil
        NSThread.exit()
    }

    func resetRTPQueue() {
    }

    func closeG729Codec() {
        g729EncoderDecoder.close()
    }

    var shortArray: Int8
    var receivedShort: Int8
    var recorderThread: NSThread

    required init?(coder aDecoder: NSCoder) {
        
    }
    
    convenience override init() {
        self.init()
        
        self.audioUnit = AudioUnit()
        var status: OSStatus
        pcmRcordedData = BufferQueue()
        g729EncoderDecoder = G729Wrapper()
        TPCircularBufferInit(&recordedPCMBuffer, 100000)
        TPCircularBufferInit(&receivedPCMBuffer, 100000)

        var desc: AudioComponentDescription = AudioComponentDescription()
        desc.componentType = kAudioUnitType_Output
        desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO
        desc.componentFlags = 0
        desc.componentFlagsMask = 0
        desc.componentManufacturer = kAudioUnitManufacturer_Apple

        var inputComponent: AudioComponent = AudioComponentFindNext(nil, &desc)

        status = AudioComponentInstanceNew(inputComponent, &audioUnit)
        checkStatus(status)

        var flag = UInt32(1)
        status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputBus, &flag, UInt32(sizeof(UInt32)))
        
        checkStatus(status)

        status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, kOutputBus, &flag, UInt32(sizeof(UInt32)))
        checkStatus(status)

        var audioFormat: AudioStreamBasicDescription
        audioFormat.mSampleRate = 8000
        audioFormat.mFormatID = kAudioFormatLinearPCM
        audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        audioFormat.mFramesPerPacket = 1
        audioFormat.mChannelsPerFrame = 1
        audioFormat.mBitsPerChannel = 16
        audioFormat.mBytesPerPacket = 2
        audioFormat.mBytesPerFrame = 2

        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kInputBus, &audioFormat, UInt32(sizeof(UInt32)))
        checkStatus(status)
        
        

        var audioCategory = kAudioSessionCategory_PlayAndRecord
        status = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), audioCategory)
        checkStatus(status)
        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, kOutputBus, &audioFormat, UInt32(sizeof(UInt32)))
        checkStatus(status)
        
        
            // Set input callback
        var callbackStruct: AURenderCallbackStruct
        callbackStruct.inputProc = recordingCallback
        callbackStruct.inputProcRefCon = ((self) as! Void)
        status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, kInputBus, callbackStruct, sizeof())
        checkStatus(status)
        
        // Set output callback
        callbackStruct.inputProc = playbackCallback
        callbackStruct.inputProcRefCon = ((self) as! Void)
        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, kOutputBus, callbackStruct, sizeof())
        checkStatus(status)

        flag = 0
        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, kInputBus, flag, sizeof())


        tempBuffer.mNumberChannels = 1
        tempBuffer.mDataByteSize = 1024 * 2
        tempBuffer.mData = malloc(1024 * 2)
        isAudioUnitRunning = false
        isBufferClean = false
    }
   
    
    
    func recordingCallback(ioData) -> OSStatus {

        
        var buffer: AudioBuffer
        buffer.mNumberChannels = 1
        buffer.mDataByteSize = inNumberFrames * 2
        buffer.mData = malloc(inNumberFrames * 2)

        var bufferList: AudioBufferList
        bufferList.mNumberBuffers = 1
        bufferList.mBuffers[0] = buffer
            var status: OSStatus
        status = AudioUnitRender(sharedInstance!.audioUnit(), ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, bufferList)
        checkStatus(status)

        sharedInstance!.processAudio(bufferList)

        free(bufferList.mBuffers[0].mData)
        return noErr
    }

    
    
    func playbackCallback(ioData) -> OSStatus {

        var THIS: AudioHandler = sharedInstance!
        for var i = 0; i < ioData.mNumberBuffers; i++ {
            var buffer: AudioBuffer = ioData.mBuffers[i]
                var availabeBytes: CInt
                var size: UInt32
            var temp: SInt16? = nil
            availabeBytes = THIS.receivedPCMBuffer.fillCount
            size = min(buffer.mDataByteSize, availabeBytes)
            if size == 0 {
                return 1
            }
            temp = TPCircularBufferTail(&THIS.receivedPCMBuffer, &availabeBytes)
            if temp == nil {
                return 1
            }
            memcpy(buffer.mData, temp!, size)
            buffer.mDataByteSize = size
            TPCircularBufferConsume(&THIS.receivedPCMBuffer, size)
        }
        return noErr
    }

}



let kOutputBus:UInt32 = 0
let kInputBus:UInt32 = 1

private let sharedAudioHandler = AudioHandler()

func checkStatus(status :CInt) {
    if status<0 {
        print("Status not 0! %d\n", status);
    }
}
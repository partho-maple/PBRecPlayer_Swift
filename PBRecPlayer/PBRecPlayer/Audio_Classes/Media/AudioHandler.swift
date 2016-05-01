//
//  AudioHandler.swift
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
import AudioUnit


let preferredIOBufferDuration = 0.005 // a value of 5 ms seems to introduce ~1% of CPU usage on iPhone 5
let kInputBus  = AudioUnitElement(1)
let kOutputBus = AudioUnitElement(0)


protocol AudioControllerDelegate {
    func recordedRTP(rtpData: Byte, andLenght len: CInt)
}



func recordingCallback(inRefCon: UnsafeMutablePointer<Void>,
                      ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                      inTimeStamp: UnsafePointer<AudioTimeStamp>,
                      inBufNumber: UInt32,
                      inNumberFrames: UInt32,
                      ioData: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
    
    print("recordingCallback got fired  >>>")
    
    // Uncomment and fix this block
    /*
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
    */
    
    return noErr
}

    

func playbackCallback(inRefCon: UnsafeMutablePointer<Void>,
                      ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                      inTimeStamp: UnsafePointer<AudioTimeStamp>,
                      inBufNumber: UInt32,
                      inNumberFrames: UInt32,
                      ioData: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
    
    print("playbackCallback got fired  <<<")
    
    //        let delegate = unsafeBitCast(inRefCon, AURenderCallbackDelegate.self)
    //        let result = delegate.performRender(ioActionFlags,
    //                                            inTimeStamp: inTimeStamp,
    //                                            inBufNumber: inBufNumber,
    //                                            inNumberFrames: inNumberFrames,
    //                                            ioData: ioData)
    //        return result
    
    
    
    // Uncomment and fix this block
    /*
    var THIS: AudioHandler = AudioHandler.sharedInstance()
    for var i = 0; i < ioData.mNumberBuffers; i += 1 {
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
    */
    
    return noErr
}
    
    
    

class AudioHandler {

    var shortArray: Int8 = 0
    var receivedShort: Int8 = 0
    var recorderThread: NSThread?
    
    var recordedPCMBuffer: TPCircularBuffer?
    var receivedPCMBuffer: TPCircularBuffer?
    var audioDelegate: AudioControllerDelegate!
    var g729EncoderDecoder: G729Wrapper?

    var audioUnit:AudioUnit = AudioUnit()
    var tempBuffer:AudioBuffer! = AudioBuffer()

    var pcmRcordedData: BufferQueue?

    var isRecordDataPullingThreadRunning: CBool = false
    var isAudioUnitRunning: CBool = false
    var isBufferClean: CBool = true
    

    
    
    class var sharedInstance: AudioHandler {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: AudioHandler? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = AudioHandler()
        }
        return Static.instance!
    }
    
    
    
    
    
    init() {
        
        var status: OSStatus
        pcmRcordedData = BufferQueue()
        g729EncoderDecoder = G729Wrapper()
        
        // Uncomment this block
        //        TPCircularBufferInit(&recordedPCMBuffer!, 100000)
        //        TPCircularBufferInit(&receivedPCMBuffer!, 100000)
        
        
        do {
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(preferredIOBufferDuration)
        } catch let error as NSError {
            print(error)
        }
        
        
        var desc: AudioComponentDescription = AudioComponentDescription()
        desc.componentType = kAudioUnitType_Output
        desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO
        desc.componentFlags = 0
        desc.componentFlagsMask = 0
        desc.componentManufacturer = kAudioUnitManufacturer_Apple
        
        let inputComponent: AudioComponent = AudioComponentFindNext(nil, &desc)
        
        status = AudioComponentInstanceNew(inputComponent, &audioUnit)
        checkStatus(status)
        
        var flag = UInt32(1)
        status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputBus, &flag, UInt32(sizeof(UInt32)))
        checkStatus(status)
        
        status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, kOutputBus, &flag, UInt32(sizeof(UInt32)))
        checkStatus(status)
        
        var audioFormat: AudioStreamBasicDescription! = AudioStreamBasicDescription()
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
        
        
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, kOutputBus, &audioFormat, UInt32(sizeof(UInt32)))
        checkStatus(status)
        
        
        
        
        
        
        
        
        
        
        
//        // Set input/recording callback
//        var callbackStruct: AURenderCallbackStruct! = AURenderCallbackStruct(inputProc: recordingCallback, inputProcRefCon: UnsafeMutablePointer(unsafeAddressOf(self)))
//        callbackStruct.inputProc = recordingCallback
//        callbackStruct.inputProcRefCon = UnsafeMutablePointer(unsafeAddressOf(self))
//        status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, kInputBus, &callbackStruct, UInt32(sizeof(UInt32)))
//        checkStatus(status)
        
        var inputCallbackStruct = AURenderCallbackStruct(inputProc: recordingCallback, inputProcRefCon: UnsafeMutablePointer(unsafeAddressOf(self)))
        AudioUnitSetProperty(audioUnit, AudioUnitPropertyID(kAudioOutputUnitProperty_SetInputCallback), AudioUnitScope(kAudioUnitScope_Global), 1, &inputCallbackStruct, UInt32(sizeof(AURenderCallbackStruct)))
        
        
        
        
        
        
        
//        // Set output/renderar/playback callback
//        var callbackStruct2: AURenderCallbackStruct! = AURenderCallbackStruct(inputProc: playbackCallback, inputProcRefCon: UnsafeMutablePointer(unsafeAddressOf(self)))
//        callbackStruct2.inputProc = playbackCallback
//        callbackStruct2.inputProcRefCon = UnsafeMutablePointer(unsafeAddressOf(self))
//        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, kOutputBus, &callbackStruct2, UInt32(sizeof(UInt32)))
//        checkStatus(status)
        
        var renderCallbackStruct = AURenderCallbackStruct(inputProc: playbackCallback, inputProcRefCon: UnsafeMutablePointer(unsafeAddressOf(self)))
        AudioUnitSetProperty(audioUnit, AudioUnitPropertyID(kAudioUnitProperty_SetRenderCallback), AudioUnitScope(kAudioUnitScope_Global), 0, &renderCallbackStruct, UInt32(sizeof(AURenderCallbackStruct)))
        
        
        
        
        
        
        
        flag = 0
        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, kInputBus, &flag, UInt32(sizeof(UInt32)))
        
        
        tempBuffer.mNumberChannels = 1
        tempBuffer.mDataByteSize = 1024 * 2
        tempBuffer.mData = malloc(1024 * 2)
        isAudioUnitRunning = false
        isBufferClean = false
    }
    
    
    func start() {
        if isAudioUnitRunning {
            return
        }
        
        g729EncoderDecoder!.open()
        var status: OSStatus
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try! audioSession.setActive(true)
        try! audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.None)
        try! audioSession.setActive(true)

        status = AudioUnitInitialize(audioUnit)
        checkStatus(status)
        status = AudioOutputUnitStart(audioUnit)
        checkStatus(status)
        
        // Uncomment this Block
//        if !self.isRecordDataPullingThreadRunning {
//            recorderThread = NSThread(target: self, selector: #selector(AudioHandler.recordDataPullingMethod), object: nil)
//            self.isRecordDataPullingThreadRunning = true
//            recorderThread.start()
//        }
        
        isAudioUnitRunning = true
    }

    func stop() {
        if !isAudioUnitRunning {
            return
        }

        var status: OSStatus
        status = AudioOutputUnitStop(audioUnit)
        checkStatus(status)
        try! AVAudioSession.sharedInstance().setActive(false)
        checkStatus(status)
        status = AudioUnitUninitialize(audioUnit)
        checkStatus(status)
        isRecordDataPullingThreadRunning = false
        isAudioUnitRunning = false
        g729EncoderDecoder!.close()
    }
    

    func resetRTPQueue() {
    }

    
    func closeG729Codec() {
        g729EncoderDecoder!.close()
    }
    
}






func checkStatus(status :CInt) {
    if status<0 {
        print("Status not 0! %d\n", status);
    }
}





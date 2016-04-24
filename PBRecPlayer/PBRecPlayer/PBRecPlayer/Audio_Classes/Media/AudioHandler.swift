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

//import G729Wrapper


//#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
//#define min( a, b ) ( ((a) < (b)) ? (a) : (b) )


protocol AudioControllerDelegate {
    func recordedRTP(rtpData: Byte, andLenght len: CInt)
}


class AudioHandler: NSObject {
//    var audioUnit: AudioComponentInstance
//    var tempBuffer: AudioBuffer
    // this will hold the latest data from the microphone
    var recordedPCMBuffer: TPCircularBuffer
    var receivedPCMBuffer: TPCircularBuffer
    var audioDelegate: AudioControllerDelegate
    var g729EncoderDecoder: G729Wrapper

    var audioUnit:AudioUnit
    var tempBuffer:AudioBuffer

    var pcmRcordedData: BufferQueue
//    weak var audioDelegate: AudioControllerDelegate
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
//        audioSession.setCategory(.PlayAndRecord)
//        audioSession.setActive(true, error: nil)
        try! audioSession.setActive(true)
        try! audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.None)
        //    Activates the audio session
//        status = AudioSessionSetActive(true)
        try! audioSession.setActive(true)
        checkStatus(status)
        //    Initialise the audio unit
        status = AudioUnitInitialize(audioUnit)
        checkStatus(status)
        //    Starts the Audio Unit
        status = AudioOutputUnitStart(audioUnit)
        checkStatus(status)
        if !self.isRecordDataPullingThreadRunning {
            recorderThread = NSThread(target: self, selector: #selector(AudioHandler.recordDataPullingMethod), object: nil)
            self.isRecordDataPullingThreadRunning = true
            recorderThread.start()
            //        [recorderThread setThreadPriority:1.0];
        }
        isAudioUnitRunning = true
    }

    func stop() {
        if !isAudioUnitRunning {
            return
        }
            //    This will disable the proximity monitoring.
        let device: UIDevice = UIDevice.currentDevice()
        device.proximityMonitoringEnabled = false
            var status: OSStatus
        //    Stops the Audio Unit
        status = AudioOutputUnitStop(audioUnit)
        checkStatus(status)
        //    Deactivates the audio session
//        status = AudioSessionSetActive(false)
        try! AVAudioSession.sharedInstance().setActive(false)
//        AVAudioSession.sharedInstance().setActive(false, withOptions: .NotifyOthersOnDeactivation, error: nil)
        checkStatus(status)
        //    Uninitialise the Audio Unit
        status = AudioUnitUninitialize(audioUnit)
        checkStatus(status)
        isRecordDataPullingThreadRunning = false
        isAudioUnitRunning = false
        g729EncoderDecoder.close()
    }

    func processAudio(bufferList: AudioBufferList) {
        var isRecordedBufferProduceBytes: CBool = false
        
//        let pTPB:TPCircularBuffer = UnsafeMutablePointer<TPCircularBuffer>(recordedPCMBuffer).memory
        
        isRecordedBufferProduceBytes = TPCircularBufferProduceBytes(recordedPCMBuffer, bufferList.mBuffers[0].mData, bufferList.mBuffers[0].mDataByteSize)
        if !isRecordedBufferProduceBytes {

        }
    }

    func receiverAudio(audio: Byte, WithLen len: CInt) {
        var isBufferProduceBytes: CBool = false
                do {
            var numberOfDecodedShorts: CInt = try g729EncoderDecoder.decodeWithG729(audio, andSize: len, andEncodedPCM: receivedShort)
            isBufferProduceBytes = TPCircularBufferProduceBytes(receivedPCMBuffer, receivedShort, (numberOfDecodedShorts * 2))
        } catch let exception {
        }
        if !isBufferProduceBytes {

        }
    }

    func recordDataPullingMethod() {
            var availableBytes: CInt
        while self.isRecordDataPullingThreadRunning {
            var buffer: Int16 = TPCircularBufferTail(recordedPCMBuffer, availableBytes)
            if availableBytes > 159 {
                var g729EncodedBytes: Byte
                var encodedLength: CInt = g729EncoderDecoder.encodeWithPCM(shortArray, andSize: 80, andEncodedG729: g729EncodedBytes)
                // Here encodedLength will be 10 if g729EncodedBytes size is 80.
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
    /**
     Initialize the audioUnit and allocate our own temporary buffer.
     The temporary buffer will hold the latest data coming in from the microphone,
     and will be copied to the output when this is requested.
     */

    required init?(coder aDecoder: NSCoder) {
        
    }
    
    convenience override init() {
        self.init()
        
        self.audioUnit = AudioUnit()
        var status: OSStatus
        pcmRcordedData = BufferQueue()
        g729EncoderDecoder = G729Wrapper()
        TPCircularBufferInit(recordedPCMBuffer, 100000)
        TPCircularBufferInit(receivedPCMBuffer, 100000)
            // Describe audio component
        var desc: AudioComponentDescription = AudioComponentDescription()
        desc.componentType = kAudioUnitType_Output
        desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO
        desc.componentFlags = 0
        desc.componentFlagsMask = 0
        desc.componentManufacturer = kAudioUnitManufacturer_Apple
            // Get component
        var inputComponent: AudioComponent = AudioComponentFindNext(nil, &desc)
        // Get audio units
        status = AudioComponentInstanceNew(inputComponent, &audioUnit)
        checkStatus(status)
            // Enable IO for recording
        var flag = UInt32(1)
        status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputBus, &flag, UInt32(sizeof(UInt32)))
        
//        var flag = UInt32(1)
//        assert(AudioUnitSetProperty(audioUnit, AudioUnitPropertyID(kAudioOutputUnitProperty_EnableIO), AudioUnitScope(kAudioUnitScope_Input), inputBus, &flag, UInt32(sizeof(UInt32))) == noErr)
//        assert(AudioUnitSetProperty(audioUnit, AudioUnitPropertyID(kAudioOutputUnitProperty_EnableIO), AudioUnitScope(kAudioUnitScope_Output), outputBus, &flag, UInt32(sizeof(UInt32))) == noErr)
        
        checkStatus(status)
        // Enable IO for playback
        status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, kOutputBus, &flag, UInt32(sizeof(UInt32)))
        checkStatus(status)
            // Describe format
            var audioFormat: AudioStreamBasicDescription
        audioFormat.mSampleRate = 8000
        audioFormat.mFormatID = kAudioFormatLinearPCM
        audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        audioFormat.mFramesPerPacket = 1
        audioFormat.mChannelsPerFrame = 1
        audioFormat.mBitsPerChannel = 16
        audioFormat.mBytesPerPacket = 2
        audioFormat.mBytesPerFrame = 2
        // Apply format
        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kInputBus, &audioFormat, UInt32(sizeof(UInt32)))
        checkStatus(status)
            /* Make sure that your application can receive remote control
                 * events by adding the code:
                 *     [[UIApplication sharedApplication]
                 *      beginReceivingRemoteControlEvents];
                 * Otherwise audio unit will fail to restart while your
                 * application is in the background mode.
                 */
            /* Make sure we set the correct audio category before restarting */
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
        // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
        flag = 0
        status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, kInputBus, flag, sizeof())
        // Allocate our own buffers (1 channel, 16 bits per sample, thus 16 bits per frame, thus 2 bytes per frame).
        // Practice learns the buffers used contain 512 frames, if this changes it will be fixed in processAudio.
        tempBuffer.mNumberChannels = 1
        tempBuffer.mDataByteSize = 1024 * 2
        tempBuffer.mData = malloc(1024 * 2)
        isAudioUnitRunning = false
        isBufferClean = false
    }
    /**
     Start the audioUnit. This means data will be provided from
     the microphone, and requested for feeding to the speakers, by
     use of the provided callbacks.
     */
    /**
     Stop the audioUnit
     */
    /**
     Change this funtion to decide what is done with incoming
     audio data from the microphone.
     Right now we copy it to our own temporary buffer.
     */
    /**
     This callback is called when new audio data from the microphone is
     available.
     */
    func recordingCallback(ioData) -> OSStatus {
            // Because of the way our audio format (setup below) is chosen:
            // we only need 1 buffer, since it is mono
            // Samples are 16 bits = 2 bytes.
            // 1 frame includes only 1 sample
            var buffer: AudioBuffer
        buffer.mNumberChannels = 1
        buffer.mDataByteSize = inNumberFrames * 2
        buffer.mData = malloc(inNumberFrames * 2)
            // Put buffer in a AudioBufferList
            var bufferList: AudioBufferList
        bufferList.mNumberBuffers = 1
        bufferList.mBuffers[0] = buffer
            var status: OSStatus
        status = AudioUnitRender(sharedInstance!.audioUnit(), ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, bufferList)
        checkStatus(status)
        // Now, we have the samples we just read sitting in buffers in bufferList
        // Process the new data
        sharedInstance!.processAudio(bufferList)
        // release the malloc'ed data in the buffer we created earlier
        free(bufferList.mBuffers[0].mData)
        return noErr
    }
    /**
     This callback is called when the audioUnit needs new data to play through the
     speakers. If you don't have any, just don't write anything in the buffers
     */
    func playbackCallback(ioData) -> OSStatus {
            // Notes: ioData contains buffers (may be more than one!)
            // Fill them up as much as you can. Remember to set the size value in each buffer to match how
            // much data is in the buffer.
        var THIS: AudioHandler = sharedInstance!
        for var i = 0; i < ioData.mNumberBuffers; i++ {
                // in practice we will only ever have 1 buffer, since audio format is mono
            var buffer: AudioBuffer = ioData.mBuffers[i]
                var availabeBytes: CInt
                var size: UInt32
            var temp: SInt16? = nil
            availabeBytes = THIS.receivedPCMBuffer.fillCount
            size = min(buffer.mDataByteSize, availabeBytes)
            if size == 0 {
                return 1
            }
            temp = TPCircularBufferTail(THIS.receivedPCMBuffer, availabeBytes)
            if temp == nil {
                return 1
            }
            memcpy(buffer.mData, temp!, size)
            buffer.mDataByteSize = size
            TPCircularBufferConsume(THIS.receivedPCMBuffer, size)
        }
        return noErr
    }

}



let kOutputBus:UInt32 = 0
let kInputBus:UInt32 = 1
//var g729EncoderDecoder: G729Wrapper

//var sharedInstance: AudioHandler? = nil
private let sharedAudioHandler = AudioHandler()

func checkStatus(status :CInt) {
    if status<0 {
        print("Status not 0! %d\n", status);
    }
}
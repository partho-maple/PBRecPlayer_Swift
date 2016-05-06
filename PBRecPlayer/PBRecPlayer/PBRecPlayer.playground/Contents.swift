//: Playground - noun: a place where people can play

import UIKit
import Foundation
import AudioToolbox
import CoreAudio
import AVFoundation
import Swift
import AudioUnit




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
    
    //    let abl: AudioBufferList = UnsafeMutableAudioBufferListPointer(ioData) as AudioBufferList
    
    var THIS: AudioHandler = AudioHandler.sharedInstance
    for i in 0 ..< Int(inBufNumber) {
        var buffer: AudioBuffer = ioData.mBuffers[i]
        var availabeBytes: CInt
        var size: UInt32
        var temp: UnsafeMutablePointer<Void> = nil
        availabeBytes = THIS.receivedPCMBuffer!.fillCount
        size = min(buffer.mDataByteSize, availabeBytes)
        if size == 0 {
            return 1
        }
        temp = TPCircularBufferTail(&THIS.receivedPCMBuffer!, &availabeBytes)
        if temp == nil {
            return 1
        }
        memcpy(buffer.mData, &temp, Int(size))
        buffer.mDataByteSize = size
        TPCircularBufferConsume(&THIS.receivedPCMBuffer!, Int32(size))
    }
    
    
    return noErr
}






func checkStatus(status :CInt) {
    if status<0 {
        print("Status not 0! %d\n", status);
    }
}








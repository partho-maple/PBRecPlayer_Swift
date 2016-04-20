//
//  BufferQueue.h
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//
import Foundation
class BufferQueue: NSObject {

    //@property (readwrite) short *buffer;
    var front: Int
    var rear: Int

    convenience override init() {
        self.init()
        //buffer = alloca(514);
        front = rear = 0
    }

    func pushData(data: Byte, datalength datalen: Int) -> Boolean {
        var totalDataLength: Int = datalen
        //    NSLog(@"pushData stat rear %d - front %d", rear, front);
        if rear + totalDataLength < kBufferSize {
                //        NSLog(@"rear+ totalDataLength , rear: %d, %d", rear+ totalDataLength, rear);
            rear += totalDataLength
            //        NSLog(@"coppied");
        }
        else {
            var availableLength: Int = kBufferSize - rear
                //        NSLog(@"available length , rear: %d, %d", availableLength, rear);
            rear = totalDataLength - availableLength
            if rear >= front {
                front = rear + 1
            }
            //        NSLog(@"coppied");
        }
        //    rear++;
        if rear == kBufferSize {
            rear = 0
        }
        //    NSLog(@"pushData end rear %d - front %d", rear, front);
        return true
    }

    func popData(data: Byte, datalength datalen: Int) -> Boolean {
        if rear == front {
            return false
        }
            //    NSLog(@"pop start rear %d - front %d", rear, front);
        var totalDataToPop: Int = datalen
        if rear > front {
            if (rear - front) >= totalDataToPop {
                front += totalDataToPop
            }
            else {
                return false
            }
        }
        else {
            var availableDataSize: Int = (kBufferSize - front) + rear
            if availableDataSize >= totalDataToPop {
                if (kBufferSize - front) >= totalDataToPop {
                    front += totalDataToPop
                }
                else {
                    var len: Int = kBufferSize - front
                        //                NSLog(@"available: %d totalDataToPop: %d front: %d len: %d", availableDataSize, totalDataToPop, front, len);
                    front = totalDataToPop - len
                    //                NSLog(@"Complete pop. front: %d", front);
                }
            }
            else {
                return false
            }
        }
        if front == kBufferSize {
            front = 0
        }
        //    NSLog(@"pop end rear %d - front %d", rear, front);
        return true
    }

    func getAvailableSize() -> Int {
        var size: Int = 0
        if rear > front {
            size = rear - front
        }
        else if rear < front {
            size = (kBufferSize - front) + rear
        }

        return size
    }

    var bufferq: Int8
}
//
//  BufferQueue.m
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//

let kBufferSize = 1024
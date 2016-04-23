//
//  BufferQueue.h
//  PBRecPlayer
//
//  Created by Partho Biswas on 21/04/16.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//

import Foundation
class BufferQueue: NSObject {

    //@property (readwrite) short *buffer;
    var front: CInt
    var rear: CInt

    convenience override init() {
        self.init()
        //buffer = alloca(514);
        front = 0
        rear = 0
    }

    func pushData(data: Byte, CIntdatalength datalen: CInt) -> CBool {
        var totalDataLength: CInt = datalen
        //    NSLog(@"pushData stat rear %d - front %d", rear, front);
        if rear + totalDataLength < kBufferSize {
                //        NSLog(@"rear+ totalDataLength , rear: %d, %d", rear+ totalDataLength, rear);
            rear += totalDataLength
            //        NSLog(@"coppied");
        }
        else {
            var availableLength: CInt = kBufferSize - rear
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

    func popData(data: Byte, datalength datalen: CInt) -> CBool {
        if rear == front {
            return false
        }
            //    NSLog(@"pop start rear %d - front %d", rear, front);
        var totalDataToPop: CInt = datalen
        if rear > front {
            if (rear - front) >= totalDataToPop {
                front += totalDataToPop
            }
            else {
                return false
            }
        }
        else {
            var availableDataSize: CInt = (kBufferSize - front) + rear
            if availableDataSize >= totalDataToPop {
                if (kBufferSize - front) >= totalDataToPop {
                    front += totalDataToPop
                }
                else {
                    var len: CInt = kBufferSize - front
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

    func getAvailableSize() -> CInt {
        var size: CInt = 0
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


let kBufferSize: CInt = 1024
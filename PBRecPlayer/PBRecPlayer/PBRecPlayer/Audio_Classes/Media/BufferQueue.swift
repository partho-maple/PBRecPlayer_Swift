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
    var front: CInt = 0
    var rear: CInt = 0
    var bufferq: Int8?


    
    convenience override init() {
        self.init()
        //buffer = alloca(514);
        front = 0
        rear = 0
    }

    func pushData(data: Byte, CIntdatalength datalen: CInt) -> CBool {
        let totalDataLength: CInt = datalen
        if rear + totalDataLength < kBufferSize {
            rear += totalDataLength
        }
        else {
            let availableLength: CInt = kBufferSize - rear
            rear = totalDataLength - availableLength
            if rear >= front {
                front = rear + 1
            }
        }
        //    rear++;
        if rear == kBufferSize {
            rear = 0
        }
        return true
    }

    func popData(data: Byte, datalength datalen: CInt) -> CBool {
        if rear == front {
            return false
        }
        let totalDataToPop: CInt = datalen
        if rear > front {
            if (rear - front) >= totalDataToPop {
                front += totalDataToPop
            }
            else {
                return false
            }
        }
        else {
            let availableDataSize: CInt = (kBufferSize - front) + rear
            if availableDataSize >= totalDataToPop {
                if (kBufferSize - front) >= totalDataToPop {
                    front += totalDataToPop
                }
                else {
                    let len: CInt = kBufferSize - front
                    front = totalDataToPop - len
                }
            }
            else {
                return false
            }
        }
        if front == kBufferSize {
            front = 0
        }
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

}


let kBufferSize: CInt = 1024


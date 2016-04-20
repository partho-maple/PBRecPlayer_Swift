//
//  G729Wrapper.h
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//
import Foundation
class G729Wrapper: NSObject {
    convenience override init() {
        self.init()
        g729 = newG729CodecNative()
        m_bCodecOpened = false
    }

    func open() -> Boolean {
        if !m_bCodecOpened {
            m_bCodecOpened = g729.Open()
        }
        return m_bCodecOpened
    }

    func close() -> Boolean {
        if m_bCodecOpened {
            g729.Close()
            m_bCodecOpened = false
        }
        return true
    }

    func encodeWithPCM(shortArray: Int8, andSize size: Int, andEncodedG729 byteArray: Byte) -> Int {
        if m_bCodecOpened {
            return g729.Encode(shortArray, size, byteArray)
        }
        else {
            return 0
        }
    }

    func decodeWithG729(byteArray: Byte, andSize size: Int, andEncodedPCM shortArray: Int8) -> Int {
        if m_bCodecOpened {
            return g729.Decode(byteArray, size, shortArray)
        }
        else {
            return 0
        }
    }

    var m_bCodecOpened: Bool
    var g729: G729CodecNative

    func dealloc() {
        //    delete g729;
        //    g729 = NULL;
    }
}
//
//  G729Wrapper.m
//  PBRecPlayer
//
//  Created by Partho Biswas on 10/13/14.
//  Copyright (c) 2014 Partho Biswas All rights reserved.
//
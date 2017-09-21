//
//  SecretStream.swift
//  Sodium_iOS
//
//  Created by Frank Denis on 9/21/17.
//  Copyright © 2017 Frank Denis. All rights reserved.
//

import Foundation
import libsodium

public class SecretStream {
    public let xchacha20poly1305 = XChaCha20Poly1305()
    
    public class XChaCha20Poly1305 {
        public static let ABytes = Int(crypto_secretstream_xchacha20poly1305_abytes())
        public static let HeaderBytes = Int(crypto_secretstream_xchacha20poly1305_headerbytes())
        public static let KeyBytes = Int(crypto_secretstream_xchacha20poly1305_keybytes())
        public enum Tag: UInt8 {
            case MESSAGE = 0x00
            case PUSH = 0x01
            case REKEY = 0x02
            case FINAL = 0x03
        }
        public typealias Key = Data
        public typealias Header = Data
        
        /**
         Generates a secret key.
         
         - Returns: The generated key.
         */
        public func key() -> Key? {
            var secretKey = Data(count: XChaCha20Poly1305.KeyBytes)
            secretKey.withUnsafeMutableBytes { secretKeyPtr in
                crypto_secretstream_xchacha20poly1305_keygen(secretKeyPtr)
            }
            return secretKey
        }
        
        public func initPush(secretKey: Key) -> PushStream? {
            guard let stream = PushStream(secretKey: secretKey) else {
                return nil
            }
            return stream
        }
        
        public func initPull(secretKey: Key, header: Header) -> PullStream? {
            guard let stream = PullStream(secretKey: secretKey, header: header) else {
                return nil
            }
            return stream
        }
        
        public class PushStream {
            private var state: UnsafeMutablePointer<crypto_secretstream_xchacha20poly1305_state>?
            private var _header: Header
            
            init?(secretKey: Key) {
                if secretKey.count != KeyBytes {
                    return nil
                }
                let rawState = UnsafeMutablePointer<UInt8>.allocate(capacity: crypto_secretstream_xchacha20poly1305_statebytes())
                state = UnsafeMutableRawPointer(rawState).bindMemory(to: crypto_secretstream_xchacha20poly1305_state.self, capacity: 1)
                guard let state = state else {
                    return nil
                }
                _header = Data(count: HeaderBytes)
                let result = secretKey.withUnsafeBytes { secretKeyPtr in
                    _header.withUnsafeMutableBytes { headerPtr in
                        crypto_secretstream_xchacha20poly1305_init_push(state, headerPtr, secretKeyPtr)
                    }
                }
                if result != 0 {
                    return nil
                }
            }
            
            public func header() -> Header {
                return _header
            }
            
            public func push(message: Data, tag: Tag = Tag.MESSAGE, ad: Data? = nil) -> Data? {
                var _ad = Data(count: 0)
                if ad != nil {
                    _ad = ad!
                }
                let adx = Data(count:0)
                var cipherText = Data(count: message.count + ABytes)
                let result = cipherText.withUnsafeMutableBytes { cipherTextPtr in
                    adx.withUnsafeBytes { adPtr in
                        message.withUnsafeBytes { messagePtr in
                            crypto_secretstream_xchacha20poly1305_push(self.state!, cipherTextPtr, nil, messagePtr, CUnsignedLongLong(message.count), adPtr, CUnsignedLongLong(_ad.count), tag.rawValue)
                        }
                    }
                }
                if result != 0 {
                    return nil
                }
                return cipherText
            }
            
            public func rekey() {
                crypto_secretstream_xchacha20poly1305_rekey(state)
            }
            
            deinit {
                guard let state = state else {
                    return
                }
                let rawState = UnsafeMutableRawPointer(state).bindMemory(to: UInt8.self, capacity: crypto_secretstream_xchacha20poly1305_statebytes())
                rawState.deallocate(capacity: 1)
            }
        }
        
        public class PullStream {
            private var state: UnsafeMutablePointer<crypto_secretstream_xchacha20poly1305_state>?
            
            init?(secretKey: Key, header: Header) {
                if header.count != HeaderBytes || secretKey.count != KeyBytes {
                    return nil
                }
                let rawState = UnsafeMutablePointer<UInt8>.allocate(capacity: crypto_secretstream_xchacha20poly1305_statebytes())
                state = UnsafeMutableRawPointer(rawState).bindMemory(to: crypto_secretstream_xchacha20poly1305_state.self, capacity: 1)
                guard let state = state else {
                    return nil
                }
                let result = secretKey.withUnsafeBytes { secretKeyPtr in
                    header.withUnsafeBytes { headerPtr in
                        crypto_secretstream_xchacha20poly1305_init_pull(state, headerPtr, secretKeyPtr)
                    }
                }
                if result != 0 {
                    return nil
                }
            }
            
            public func pull(cipherText: Data, ad: Data? = nil) -> (Data, Tag)? {
                if cipherText.count < ABytes {
                    return nil
                }
                var _ad = Data(count: 0)
                if ad != nil {
                    _ad = ad!
                }
                var message = Data(count: cipherText.count - ABytes)
                var _tag = Data(count: 1)
                let result = cipherText.withUnsafeBytes { cipherTextPtr in
                    _ad.withUnsafeBytes { adPtr in
                        message.withUnsafeMutableBytes { messagePtr in
                            _tag.withUnsafeMutableBytes { tagPtr in
                                crypto_secretstream_xchacha20poly1305_pull(state!, messagePtr, nil, tagPtr, cipherTextPtr, CUnsignedLongLong(cipherText.count), adPtr, CUnsignedLongLong(_ad.count))
                            }
                        }
                    }
                }
                if result != 0 {
                    return nil
                }
                guard let tag = Tag.init(rawValue: _tag[0]) else {
                    return nil
                }
                return (message, tag)
            }
            
            public func rekey() {
                crypto_secretstream_xchacha20poly1305_rekey(state)
            }
            
            deinit {
                guard let state = state else {
                    return
                }
                let rawState = UnsafeMutableRawPointer(state).bindMemory(to: UInt8.self, capacity: crypto_secretstream_xchacha20poly1305_statebytes())
                rawState.deallocate(capacity: 1)
            }
        }
    }
}
//
//  KeyDerivation.swift
//  Sodium
//
//  Created by Patrick Salami (https://www.github.com/psalami) on 7/7/17.
//  Copyright © 2017 Frank Denis. All rights reserved.
//

import Foundation
import libsodium

public class KeyDerivation {
    public typealias Key = Data

    /**
     Derives a subkey from the specified input key. Each index (from 0 to (2^64) - 1) yields a unique deterministic subkey.
     The sequence of subkeys is likely unique for a given context.

     - Parameter secretKey: the master key from which to derive the subkey (must be between 16 and 64 bytes in length, inclusive)
     - Parameter index: the index of the subkey to generate (allowed range: 0 to (2^64) - 1)
     - Parameter length: the desired length of the subkey in bytes (allowed range: 16 to 64; default: 32)
     - Parameter context: a String that identifies the context; use a different value for different types of keys (should be exactly 8 characters long but must be no longer than 8 characters)
     - Returns: the derived key

     - Throws: NSError describing either an input value whose length does not fall within the specified bounds, or an error generated by the underlying libsodium function

     - Note: Input and output keys must have a length between 16 and 64 bytes (inclusive), otherwise an error is thrown. Context must be at most 8 characters long. If the specified context is shorter than 8 characters, it will be padded to 8 characters.

     */
    public func derive(secretKey: Key, index: UInt64, length: Int = crypto_kdf_keybytes(), context: String) throws -> Key {
        if length < crypto_kdf_bytes_min() {
            throw NSError(domain: "libsodium", code: -10,
                          userInfo: [NSLocalizedDescriptionKey: String(format:"the length of the derived key must be at least %d bytes", crypto_kdf_bytes_min())])
        }

        if length > crypto_kdf_bytes_max() {
            throw NSError(domain: "libsodium", code: -11,
                          userInfo: [NSLocalizedDescriptionKey: String(format:"the length of the derived key must be less than or equal to %d bytes", crypto_kdf_bytes_max())])
        }

        if secretKey.count < crypto_kdf_bytes_min() {
            throw NSError(domain: "libsodium", code: -12,
                          userInfo: [NSLocalizedDescriptionKey: String(format:"the length of the input key must be at least %d bytes", crypto_kdf_bytes_min())])
        }

        if secretKey.count > crypto_kdf_bytes_max() {
            throw NSError(domain: "libsodium", code: -13,
                          userInfo: [NSLocalizedDescriptionKey: String(format:"the length of the input key must be less than or equal to %d bytes", crypto_kdf_bytes_max())])
        }

        if context.lengthOfBytes(using: .utf8) > crypto_kdf_contextbytes() {
            throw NSError(domain: "libsodium", code: -14,
                          userInfo: [NSLocalizedDescriptionKey: String(format:"the length of the context String must be less than or equal to %d bytes", crypto_kdf_contextbytes())])
        }

        let contextPadded = context.padding(toLength: crypto_kdf_contextbytes(), withPad: " ", startingAt: 0)

        var subKey = Key(count: length)

        let result = subKey.withUnsafeMutableBytes { (subKeyPtr) -> Int32 in
            return secretKey.withUnsafeBytes { (secretKeyPtr) -> Int32 in
                return crypto_kdf_derive_from_key(subKeyPtr, length, index, contextPadded, secretKeyPtr)
            }
        }

        if result != 0 {
            print("Error during key derivation: ", result)
                throw NSError(domain: "libsodium", code: Int(result),
                              userInfo: [NSLocalizedDescriptionKey: "error in underlying libsodium function while trying to derive subkey from master key",
                                         "context": context,
                                         "index": index])
        }

        return subKey
    }
}

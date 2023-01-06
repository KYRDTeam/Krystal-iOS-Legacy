// Copyright SIX DAY LLC. All rights reserved.

import Foundation
@testable import Trust
import TrustKeystore
import TrustCore
import KeychainSwift
import Result

class FakeEtherKeystore: EtherKeystore {
    convenience init() {
        let uniqueString = NSUUID().uuidString
        let THIS_PRIVATE_KEY = """
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACDzS4BetL1liWXECr+QVoRYGuOS8BQryQWiPxwiSEScQgAAAJiX1jvsl9Y7
7AAAAAtzc2gtZWQyNTUxOQAAACDzS4BetL1liWXECr+QVoRYGuOS8BQryQWiPxwiSEScQg
AAAEC/il8dxQgkqu6don62xGlKgMN4VUmdlpOvdDH9ARv1zvNLgF60vWWJZcQKv5BWhFga
45LwFCvJBaI/HCJIRJxCAAAAFHR1bmdwdW5AcHVubWFjLmxvY2FsAQ==
-----END OPENSSH PRIVATE KEY-----
"""
        try! self.init(
            keychain: KeychainSwift(keyPrefix: "fake" + uniqueString),
            keysSubfolder: "/keys" + uniqueString,
            userDefaults: UserDefaults.test
        )
    }

    override func createAccount(with password: String, completion: @escaping (Result<Account, KeystoreError>) -> Void) {
        completion(.success(.make()))
    }
}

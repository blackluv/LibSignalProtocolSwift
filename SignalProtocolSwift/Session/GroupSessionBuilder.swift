//
//  GroupSessionBuilder.swift
//  libsignal-protocol-swift
//
//  Created by User on 01.11.17.
//  Copyright © 2017 User. All rights reserved.
//

import Foundation



struct GroupSessionBuilder {

    var store: SignalProtocolStoreContext

    init(store: SignalProtocolStoreContext) {
        self.store = store
    }

    func processSession(
        senderKeyName: SignalSenderKeyName,
        distributionMessage: SenderKeyDistributionMessage) throws {

        let senderKey = try store.loadSenderKey(for: senderKeyName) ?? SenderKeyRecord()

        senderKey.addState(
            id: distributionMessage.id,
            iteration: distributionMessage.iteration,
            chainKey: distributionMessage.chainKey,
            signaturePublicKey: distributionMessage.signatureKey,
            signaturePrivateKey: nil)

        try store.store(senderKey: senderKey, for: senderKeyName)
    }

    func createSession(senderKeyName: SignalSenderKeyName) throws -> SenderKeyDistributionMessage {

        let record = try store.loadSenderKey(for: senderKeyName) ?? SenderKeyRecord()

        if record.isEmpty {

            let senderKeyId = try SignalCrypto.generateSenderKeyId()
            let senderKey = try SignalCrypto.generateSenderKey()
            let senderSigningKey = try SignalCrypto.generateSenderSigningKey()
            record.setSenderKey(id: senderKeyId,
                                iteration: 0,
                                chainKey: senderKey,
                                signatureKeyPair: senderSigningKey)
            try store.store(senderKey: record, for: senderKeyName)
        }
        guard let state = record.state else {
            throw SignalError.unknown
        }

        let chainKey = state.chainKey
        let seed = chainKey.chainKey

        return SenderKeyDistributionMessage(
            id: state.keyId,
            iteration: chainKey.iteration,
            chainKey: seed,
            signatureKey: state.signaturePublicKey)

    }
}
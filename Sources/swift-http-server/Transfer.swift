//
// Transfer.swift
//

import Foundation

/**
 Transfer protocol
 */
public protocol Transfer {
    var status: TransferStatus { get }
    var remainingData: Data? { get }
    func read() throws -> Data?
}

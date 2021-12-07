//
// Transfer.swift
//

import Foundation

/**
 Transfer Status
 */
public enum TransferStatus {
    case idle, process, completed
}

/**
 Transfer protocol
 */
public protocol Transfer {
    /**
     Transfer Status
     */
    var status: TransferStatus { get }
    /**
     Remaining data after process done
     */
    var remainingData: Data? { get }
    /**
     Read
     */
    func read() throws -> Data?
}

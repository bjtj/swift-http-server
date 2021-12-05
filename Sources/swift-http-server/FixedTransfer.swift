//
// FixedTransfer.swift
// 

import Foundation
import Socket


/**
 FixedTransfer
 */
public class FixedTransfer : Transfer {

    /**
     Transfer status
     */
    public var status: TransferStatus = .idle
    let remoteSocket: Socket
    let contentLength: Int
    var startWithData: Data?
    var bodyBuffer: Data = Data()
    var bufferSize: Int
    var lastIndex: Int = 0

    /**
     Remaining data
     */
    public var remainingData: Data?

    init?(remoteSocket: Socket, contentLength: Int, startWithData: Data? = nil, bufferSize: Int = 4096) throws {
        guard contentLength >= 0 else {
            throw HttpServerError.custom(string: "Content Length must not be negative value but \(contentLength)")
        }
        self.remoteSocket = remoteSocket
        self.contentLength = contentLength
        self.startWithData = startWithData
        self.bufferSize = bufferSize

        if let startWithData = startWithData {
            bodyBuffer.append(startWithData)
        }

        status = .process
    }

    /**
     Read
     */
    public func read() throws -> Data? {
        guard bodyBuffer.count >= contentLength else {
            var readBuffer = Data(capacity: bufferSize)
            let bytesRead = try remoteSocket.read(into: &readBuffer)
            guard readBuffer.count == bytesRead else {
                throw HttpServerError.custom(
                  string: "insufficient read bytes \(bytesRead) / count: \(readBuffer.count)")
            }
            bodyBuffer.append(readBuffer)
            guard min(bodyBuffer.count , contentLength) - lastIndex > 0 else {
                return nil
            }
            let retdata = bodyBuffer.subdata(in: lastIndex..<min(bodyBuffer.count , contentLength))
            lastIndex = min(bodyBuffer.count , contentLength)
            return retdata
        }

        status = .completed
        remainingData = bodyBuffer.subdata(in: contentLength..<bodyBuffer.endIndex)
        bodyBuffer.removeSubrange(contentLength..<bodyBuffer.endIndex)

        if lastIndex < contentLength {
            return bodyBuffer.subdata(in: lastIndex..<contentLength)
        }
        return nil
    }
}

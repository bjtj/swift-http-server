//
// ChunkedTransfer.swift
// 

import Foundation
import Socket


/**
 ChunkedTransfer
 */
public class ChunkedTransfer: Transfer {

    let remoteSocket: Socket
    var startWithData: Data?
    var readBuffer: Data = Data()
    let separator: Data

    /**
     Status
     */
    public var status: TransferStatus = .idle

    /**
     Remaining Buffer
     */
    public var remainingData: Data? {
        return readBuffer
    }

    init?(remoteSocket: Socket, startWithData: Data? = nil) throws {
        self.remoteSocket = remoteSocket
        self.startWithData = startWithData

        guard let data = "\r\n".data(using: .utf8) else {
            throw HttpServerError.custom(string: "?? \"\\r\\n\".data(using: .utf8) failed")
        }
        separator = data

        if let startWithData = startWithData {
            readBuffer.append(startWithData)
        }

        status = .process
    }

    /**
     Process Read
     */
    public func read() throws -> Data? {
        let size = try readSize()

        return try readContent(size: size)
    }

    func readSize() throws -> Int {
        repeat {
            guard let range = readBuffer.range(of: separator) else {

                var buffer = Data()
                let bytesRead = try remoteSocket.read(into: &buffer)

                guard buffer.count == bytesRead else {
                    throw HttpServerError.custom(
                      string: "insufficient read bytes \(bytesRead) / count: \(buffer.count)")
                }

                readBuffer.append(buffer)
                buffer.count = 0
                
                continue
            }            
            let sizeData = readBuffer.subdata(in: 0..<range.lowerBound)
            guard let sizeString = String(data: sizeData, encoding: .utf8) else {
                throw HttpServerError.custom(string: "cannot convert data to string")
            }            
            readBuffer.removeSubrange(0..<range.upperBound)
            guard let size = Int(sizeString, radix: 16) else {
                throw HttpServerError.custom(string: "failed convert to number `\(sizeString)`")
            }
            return size
        } while true
    }

    func readContent(size: Int) throws -> Data? {
        guard size >= 0 else {
            throw HttpServerError.custom(string: "invalid content size `\(size)`")
        }
        repeat {
            guard readBuffer.count >= size + separator.count else {

                var buffer = Data()
                let bytesRead = try remoteSocket.read(into: &buffer)

                guard buffer.count == bytesRead else {
                    throw HttpServerError.custom(
                      string: "insufficient read bytes \(bytesRead) / count: \(buffer.count)")
                }

                readBuffer.append(buffer)
                buffer.count = 0
                
                continue
            }
            guard readBuffer[(readBuffer.endIndex - separator.count)..<readBuffer.count] == separator else {
                throw HttpServerError.custom(string: "insufficient chunked content format -- must ends with \(separator)")
            }
            let data = size == 0 ? nil : readBuffer.subdata(in: 0..<size)
            readBuffer.removeSubrange(0..<size+2)
            return data
        } while true
    }

}

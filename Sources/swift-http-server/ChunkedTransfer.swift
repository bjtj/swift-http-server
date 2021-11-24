import Foundation

public enum ChunkedTransferFormatError : Error {
    case insufficientChunkSize
    case insufficientChunkData
}

/**
 ChunkedTransfer
 */
public class ChunkedTransfer {

    var inputStream: InputStream

    public init(inputStream: InputStream, bufferSize: Int = 1024) {
        self.inputStream = inputStream
    }

    func readChunkSize() throws -> Int {
        let bufferSize = 1
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        var data = Data()
        while inputStream.hasBytesAvailable {
            let readSize = inputStream.read(buffer, maxLength: bufferSize)
            guard readSize > 0 else {
                continue
            }
            data.append(buffer, count: bufferSize)
            if let range = data.range(of: "\r\n".data(using: .utf8)!) {
                return Int(String(data: data.subdata(in: 0..<range.lowerBound), encoding: .utf8)!)!
            }
        }
        throw ChunkedTransferFormatError.insufficientChunkSize
    }

    func readChunkData(chunkSize: Int) throws -> Data {
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        var data = Data()
        while inputStream.hasBytesAvailable {
            let count = chunkSize - data.count
            let readSize = inputStream.read(buffer, maxLength: count)
            guard readSize > 0 else {
                continue
            }
            data.append(buffer, count: count)
            if data.count == chunkSize {
                return data
            }
        }
        throw ChunkedTransferFormatError.insufficientChunkData
    }

    public func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
        do {
            let size = try readChunkSize()
            let data = try readChunkData(chunkSize: size)
            data.copyBytes(to: buffer, count: data.count)
            return size
        } catch {
            return 0
        }
    }

    public var hasBytesAvailable: Bool {
        return inputStream.hasBytesAvailable == false
    }
}

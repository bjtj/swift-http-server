import Foundation

public class ChunkedTransfer {
    var chunkSize = 0
    var data = Data()
    var inputStream: InputStream
    let bufferSize = 1024
    var buffer: UnsafeMutablePointer<UInt8>
    var readIndex = 0
    public init(inputStream: InputStream) {
        self.inputStream = inputStream
        self.buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    }

    func readFromStream() {
        let size = inputStream.read(buffer, maxLength: bufferSize)
        data.append(buffer, count: size)
        if chunkSize < data.count {
            chunkSize = 0
        } else if let range = data.range(of: "\r\n".data(using: .utf8)!) {
            data = data.subdata(in: 0..<range.lowerBound) +
              data.subdata(in: range.upperBound..<data.count)
        }
    }

    public func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
        let size = min(data.count - readIndex, maxLength)
        guard size > 0 else {
            return 0
        }

        data.copyBytes(to: buffer, from: readIndex..<readIndex + size)

        return size
    }

    public var hasBytesAvailable: Bool {
        return inputStream.hasBytesAvailable == false && readIndex == data.count
    }
}

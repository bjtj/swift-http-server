import Foundation

public class ChunkedTransfer {
    let data = Data()
    var inputStream: InputStream
    init(inputStream: InputStream) {
        self.inputStream = inputStream
    }

    func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
        return 0
    }

    public var hasBytesAvailable: Bool {
        return data.count > 0
    }
}

import Foundation

protocol Transfer {
    func read() -> Data?
    func write(data: Data?)
}

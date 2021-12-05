import XCTest
@testable import SwiftHttpServer

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class ReadTests: XCTestCase {


    func testReadHeader() -> Void {

        let headerString = "HTTP/1.1 200 OK\r\n\r\n"
        let packet = headerString.data(using: .utf8)

        let reader = HttpPacketReader {
            (context, type, data) in

            switch type {
            case .readHeader:
                break
            case .readHeaderCompleted:
                guard let data = data else {
                    return
                }
                do {
                    let header = try HttpHeader.read(text: String(data: data, encoding: .utf8)!)
                    XCTAssertEqual(headerString, header.description)
                } catch {
                    XCTFail("error - \(error)")
                }
                
                break
            case .readBody:
                break
            case .readBodyCompleted:
                break
            default:
                break
            }
        }

        do {
            try reader.process(data: packet)
        } catch let err {
            print("error - \(err)")
        }
    }

    func testReadHeaderWithFields() -> Void {

        let headerString = "HTTP/1.1 200 OK\r\nEXT: \r\n\r\n"
        let packet = headerString.data(using: .utf8)

        let reader = HttpPacketReader {
            (context, type, data) in

            switch type {
            case .readHeader:
                break
            case .readHeaderCompleted:
                guard let data = data else {
                    return
                }
                do {
                    let header = try HttpHeader.read(text: String(data: data, encoding: .utf8)!)
                                    XCTAssertEqual(headerString, header.description)
                } catch {
                    XCTFail("error - \(error)")
                }
                break
            case .readBody:
                break
            case .readBodyCompleted:
                break
            default:
                break
            }
        }

        do {
            try reader.process(data: packet)
        } catch let err {
            print("error - \(err)")
        }
    }

    public static var allTests = [
      ("testReadHeader", testReadHeader),
      ("testReadHeaderWithFields", testReadHeaderWithFields),
    ]
}

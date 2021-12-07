//
// HttpHeader.swift
// 

/**
 Http Header
 */
public class HttpHeader {

    /**
     HTTP Protocol Version
     */
    public var specVersion: HttpSpecVersion?
    /**
     First line
     */
    public var firstLine = FirstLine()
    var fields: [KeyValuePair] = []

    /**
     Check header fields contains the key (ignore case)
     */
    public func contains(key: String?) -> Bool {
        for field in fields {
            if field.key?.caseInsensitiveCompare(key!) == .orderedSame {
                return true
            }
        }
        return false
    }

    /**
     Get `Content-Length` field value
     */
    public var contentLength: Int? {
        get {
            guard let length = self["Content-Length"] else {
                return nil
            }
            return Int(length)
        }
        set(value) {
            self["Content-Length"] = "\(value!)"
        }
    }

    /**
     Get `Content-Type` field value
     */
    public var contentType: String? {
        get {
            guard let type = self["Content-Type"] else {
                return nil
            }
            return type
        }
        set(value) {
            self["Content-Type"] = value
        }
    }

    /**
     Get `Connection` field value
     */
    public var connectionType: HttpConnectionType? {
        get {
            guard let connection = self["Connection"] else {
                return nil
            }
            if connection.caseInsensitiveCompare("close") == .orderedSame {
                return .close
            }
            if connection.caseInsensitiveCompare("keep-alive") == .orderedSame {
                return .keep_alive
            }
            return nil
        }
        set(value) {
            guard let type = value else {
                self["Connection"] = nil
                return
            }
            self["Connection"] = type.rawValue
        }
    }

    /**
     Get `Transfer-Encoding` field value
     */
    public var transferEncoding: TransferEncoding? {
        get {
            guard let encoding = self["Transfer-Encoding"] else {
                return nil
            }
            return TransferEncoding(rawValue: encoding)
        }
        set (value) {
            guard let encoding = value else {
                self["Transfer-Encoding"] = nil
                return
            }
            self["Transfer-Encoding"] = encoding.rawValue
        }
    }

    /**
     Get `Expect` field value
     */
    public var expect: String? {
        get {
            return self["Expect"]
        }
        set(value) {
            self["Expect"] = value
        }
    }

    /**
     Check if `Expect` is 100-*
     */
    public var isExpect100: Bool {
        guard let expect = self["Expect"] else {
            return false
        }
        return expect.hasPrefix("100-")
    }

    /**
     Get header field subscript way (ignore case)
     */
    public subscript (key: String) -> String? {
        get {
            for field in fields {
                if field.key?.caseInsensitiveCompare(key) == .orderedSame {
                    return field.value
                }
            }
            return nil
        }
        set (value) {
            for field in fields {
                if field.key?.caseInsensitiveCompare(key) == .orderedSame {
                    field.value = value
                }
            }
            fields.append(KeyValuePair(key: key, value: value))
        }
    }

    /**
     To Header String
     */
    public var description: String {
        let fieldsString = fields.map {
            "\($0.key ?? ""): \($0.value ?? "")\r\n"
        }.joined(separator: "")
        return "\(firstLine.description)\r\n\(fieldsString)\r\n"
    }

    /**
     Read Http Header from string
     */
    public static func read(text: String) throws -> HttpHeader {
        let header = HttpHeader()
        let lines = text.components(separatedBy: "\r\n")
        var first = true
        for line in lines {
            if line.isEmpty {
                break
            }
            if first {
                header.firstLine = try FirstLine.read(text: line)
                first = false
            } else {
                let tokens = line.split(separator: ":", maxSplits: 1)
                guard tokens.count > 0 else {
                    continue
                }
                header[tokens[0].trimmingCharacters(in: .whitespaces)] =
                  (tokens.count == 1 ? "" : "\(tokens[1])").trimmingCharacters(in: .whitespaces)
            }
        }
        return header
    }
}

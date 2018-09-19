
class KeyValuePair {
    public var key: String?
    public var value: String?

    public init(key: String?, value: String?) {
        self.key = key
        self.value = value
    }
}

public class FirstLine {
    private var parts = ["", "", ""]
    public var first: String {
        get {return parts[0]}
        set(value) { parts[0] = value }
    }
    public var second: String {
        get {return parts[1]}
        set(value) { parts[1] = value }
    }
    public var third: String {
        get {return parts[2]}
        set(value) { parts[2] = value }
    }

    public var description: String {
        return parts.joined(separator: " ")
    }

    public static func read(text: String) -> FirstLine {
        let firstLine = FirstLine()
        let tokens = text.split(separator: " ", maxSplits: 2)
        firstLine.first = String(tokens[0])
        firstLine.second = String(tokens[1])
        firstLine.third = String(tokens[2])
        return firstLine
    }
}

public class HttpHeader {

    public var firstLine = FirstLine()
    var fields: [KeyValuePair] = []

    public func contains(key: String?) -> Bool {
        for field in fields {
            if field.key?.caseInsensitiveCompare(key!) == .orderedSame {
                return true
            }
        }
        return false
    }

    subscript (key: String) -> String? {
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

    public var description: String {
        let fieldsString = fields.map { "\($0.key!): \($0.value!)" }.joined(separator: "\r\n")
        return "\(firstLine.description)\r\n\(fieldsString)\r\n\r\n"
    }

    public static func read(text: String) -> HttpHeader {
        let header = HttpHeader()
        let lines = text.components(separatedBy: "\r\n")
        var first = true
        for line in lines {
            if line.isEmpty {
                break
            }
            if first {
                header.firstLine = FirstLine.read(text: line)
                first = false
            } else {
                let tokens = line.split(separator: ":", maxSplits: 1)
                header[tokens[0].trimmingCharacters(in: .whitespaces)] =
                  (tokens.count == 1 ? "" : "\(tokens[1])").trimmingCharacters(in: .whitespaces)
            }
        }
        return header
    }
}

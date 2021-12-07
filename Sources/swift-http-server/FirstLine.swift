//
// FirstLine.swift
// 

/**
 HttpHeader FirstLine
 */
public class FirstLine {

    private var parts = ["", "", ""]

    /**
     First Part
     */
    public var first: String {
        get {return parts[0]}
        set(value) { parts[0] = value }
    }

    /**
     Second Part
     */
    public var second: String {
        get {return parts[1]}
        set(value) { parts[1] = value }
    }

    /**
     Third Part
     */
    public var third: String {
        get {return parts[2]}
        set(value) { parts[2] = value }
    }

    /**
     To String
     */
    public var description: String {
        return parts.joined(separator: " ")
    }

    /**
     Read from string
     */
    public static func read(text: String) throws -> FirstLine {
        let firstLine = FirstLine()
        let tokens = text.split(separator: " ", maxSplits: 2)
        guard tokens.count == 3 else {
            throw HttpServerError.custom(string: "wrong firstline format `\(text)`")
        }
        firstLine.first = String(tokens[0])
        firstLine.second = String(tokens[1])
        firstLine.third = String(tokens[2])
        return firstLine
    }
}

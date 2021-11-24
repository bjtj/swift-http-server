
/**
 FirstLine
 */
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

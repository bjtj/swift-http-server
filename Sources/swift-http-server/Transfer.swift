import Socket

public class Transfer {
    public var remoteSocket: Socket?
    public init(remoteSocket: Socket?) {
        self.remoteSocket = remoteSocket
    }
}

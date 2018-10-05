import Foundation

public enum InetAddressError : Error {
    case unknown_inet_version
}

public enum InetVersion {
    case any
    case ipv4
    case ipv6
}

public class InetAddress {
    public var version: InetVersion
    public var hostname: String
    public var port: Int32

    public var description: String {
        return "(\(version))\(hostname) \(port)"
    }

    public init(version: InetVersion, hostname: String, port: Int32) {
        self.version = version
        self.hostname = hostname
        self.port = port
    }

    public init?(addr: UnsafeMutablePointer<sockaddr>?) throws {
        if addr!.pointee.sa_family == AF_INET {
            var addr_in = sockaddr_in()
			memcpy(&addr_in, &(addr!.pointee), Int(MemoryLayout<sockaddr_in>.size))
			let bufLen = Int(INET_ADDRSTRLEN)
			var buf = [CChar](repeating: 0, count: bufLen)
			inet_ntop(Int32(addr_in.sin_family), &addr_in.sin_addr, &buf, socklen_t(bufLen))
            version = .ipv4
            hostname = String(cString: buf)
            port = 0
        } else if addr!.pointee.sa_family == AF_INET6 {
            var addr_in = sockaddr_in6()
			memcpy(&addr_in, &(addr!.pointee), Int(MemoryLayout<sockaddr_in6>.size))
			let bufLen = Int(INET6_ADDRSTRLEN)
			var buf = [CChar](repeating: 0, count: bufLen)
			inet_ntop(Int32(addr_in.sin6_family), &addr_in.sin6_addr, &buf, socklen_t(bufLen))
            version = .ipv6
            hostname = String(cString: buf)
            port = 0
        } else {
            throw InetAddressError.unknown_inet_version
        }
    }
}

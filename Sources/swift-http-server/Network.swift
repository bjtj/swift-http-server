import Foundation

public class Network {

    public static func getInetAddress(targetVersion: InetVersion = .ipv4) -> InetAddress? {
        let addrs = getInetAddresses()
        for addr in addrs {
            if targetVersion != .any {
                guard addr.version == targetVersion else {
                    continue
                }
            }
            if addr.hostname != "::1" && addr.hostname != "127.0.0.1" {
                return addr
            }
            
        }
        return nil
    }

    public static func getInetAddresses() -> [InetAddress] {

        var result = [InetAddress]()
        var addrs: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&addrs) == 0 else {
            print("getifaddrs() failed")
            return result
        }

        var ptr = addrs
        while ptr != nil {
            let addr = ptr!.pointee.ifa_addr
            do {
                result.append(try InetAddress(addr: addr)!)
            } catch {
            }
            ptr = ptr!.pointee.ifa_next
        }

        freeifaddrs(addrs)
        return result
    }

}

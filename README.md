# SwiftHttpServer

This is a swift http server (library) mainly depends on IBM BlueSocket (<https://github.com/IBM-Swift/BlueSocket>).


## Swift version

```shell
$ swift --version
Swift version 4.2.3 (swift-4.2.3-RELEASE)
Target: x86_64-unknown-linux-gnu
```

```shell
$ swift --version
Swift version 5.5 (swift-5.5-RELEASE)
Target: x86_64-unknown-linux-gnu
```

## Dependencies

* BlueSocket: <https://github.com/IBM-Swift/BlueSocket>

## Build, Test

```shell
swift build
```

```shell
swift test
```

## How to use it?

Add it to dependency (package.swift)

```swift
dependencies: [
    .package(url: "https://github.com/bjtj/swift-http-server.git", from: "0.1.8"),
  ],
```

Import package into your code

```swift
import SwiftHttpServer
```

## Example

```swift
let server = HttpServer(port: 0)
try server.route(pattern: "/") {
    (request) in
    let response = HttpResponse(code: 200, reason: HttpStatusCode.shared[200])
    response.data = "Hello".data(using: .utf8)
    return response
}
let queue = DispatchQueue.global(qos: .default)
queue.async {
    do {
        try server.run()
    } catch let error {
        print(error)
    }
}
```

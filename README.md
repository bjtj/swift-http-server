# SwiftHttpServer

This is a swift http server (library) mainly depends on IBM BlueSocket (<https://github.com/IBM-Swift/BlueSocket>).

![Github Build Status](https://github.com/bjtj/swift-http-server/actions/workflows/swift.yml/badge.svg)
[![Build Status](https://app.travis-ci.com/bjtj/swift-http-server.svg?branch=master)](https://app.travis-ci.com/bjtj/swift-http-server)


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
    .package(url: "https://github.com/bjtj/swift-http-server.git", from: "0.1.13"),
  ],
```

Import package into your code

```swift
import SwiftHttpServer
```

## Example

```swift
let server = HttpServer(port: 0)

class GetHandler: HttpRequestHandler {
    func onHeaderCompleted(header: HttpHeader, request: HttpRequest,  response: HttpResponse) throws {
        
    }
    
    func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
        response.code = 200
        response.data = "Hello".data(using: .utf8)
    }
}

try server.route(pattern: "/", handler: GetHandler())
let queue = DispatchQueue.global(qos: .default)
queue.async {
    do {
        try server.run()
    } catch let error {
        print(error)
    }
}
```

[Skip Navigation](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient#app-main)

Framework

# AsyncHTTPClient

This package provides simple HTTP Client library built on top of SwiftNIO.

## [Overview](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Overview)

This library provides the following:

- First class support for Swift Concurrency (since version 1.9.0)

- Asynchronous and non-blocking request methods

- Simple follow-redirects (cookie headers are dropped)

- Streaming body download

- TLS support

- Automatic HTTP/2 over HTTPS (since version 1.7.0)

- Cookie parsing (but not storage)


### [Getting Started](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Getting-Started)

#### [Adding the dependency](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Adding-the-dependency)

Add the following entry in your Package.swift to start using HTTPClient:

```
.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0")

```

and `AsyncHTTPClient` dependency to your target:

```
.target(name: "MyApp", dependencies: [.product(name: "AsyncHTTPClient", package: "async-http-client")]),

```

#### [Request-Response API](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Request-Response-API)

The code snippet below illustrates how to make a simple GET request to a remote server.

```
import AsyncHTTPClient

/// MARK: - Using Swift Concurrency
let request = HTTPClientRequest(url: "https://apple.com/")
let response = try await httpClient.execute(request, timeout: .seconds(30))
print("HTTP head", response)
if response.status == .ok {
    let body = try await response.body.collect(upTo: 1024 * 1024) // 1 MB
    // handle body
} else {
    // handle remote error
}

/// MARK: - Using SwiftNIO EventLoopFuture
HTTPClient.shared.get(url: "https://apple.com/").whenComplete { result in
    switch result {
    case .failure(let error):
        // process error
    case .success(let response):
        if response.status == .ok {
            // handle response
        } else {
            // handle remote error
        }
    }
}

```

You should always shut down [`HTTPClient`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclient) instances you created using [`shutdown()`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclient/shutdown()-9gcpw). Please note that you must not call [`shutdown()`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclient/shutdown()-9gcpw) before all requests of the HTTP client have finished, or else the in-flight requests will likely fail because their network connections are interrupted.

#### [async/await examples](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#asyncawait-examples)

Examples for the async/await API can be found in the [`Examples` folder](https://github.com/swift-server/async-http-client/tree/main/Examples) in the repository.

### [Usage guide](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Usage-guide)

The default HTTP Method is `GET`. In case you need to have more control over the method, or you want to add headers or body, use the [`HTTPClientRequest`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclientrequest) struct:

#### [Using Swift Concurrency](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Using-Swift-Concurrency)

```
import AsyncHTTPClient

do {
    var request = HTTPClientRequest(url: "https://apple.com/")
    request.method = .POST
    request.headers.add(name: "User-Agent", value: "Swift HTTPClient")
    request.body = .bytes(ByteBuffer(string: "some data"))

    let response = try await HTTPClient.shared.execute(request, timeout: .seconds(30))
    if response.status == .ok {
        // handle response
    } else {
        // handle remote error
    }
} catch {
    // handle error
}

```

#### [Using SwiftNIO EventLoopFuture](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Using-SwiftNIO-EventLoopFuture)

```
import AsyncHTTPClient

var request = try HTTPClient.Request(url: "https://apple.com/", method: .POST)
request.headers.add(name: "User-Agent", value: "Swift HTTPClient")
request.body = .string("some-body")

HTTPClient.shared.execute(request: request).whenComplete { result in
    switch result {
    case .failure(let error):
        // process error
    case .success(let response):
        if response.status == .ok {
            // handle response
        } else {
            // handle remote error
        }
    }
}

```

#### [Redirects following](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Redirects-following)

Enable follow-redirects behavior using the client configuration:

```
let httpClient = HTTPClient(eventLoopGroupProvider: .singleton,
                            configuration: HTTPClient.Configuration(followRedirects: true))

```

#### [Timeouts](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Timeouts)

Timeouts (connect and read) can also be set using the client configuration:

```
let timeout = HTTPClient.Configuration.Timeout(connect: .seconds(1), read: .seconds(1))
let httpClient = HTTPClient(eventLoopGroupProvider: .singleton,
                            configuration: HTTPClient.Configuration(timeout: timeout))

```

or on a per-request basis:

```
httpClient.execute(request: request, deadline: .now() + .milliseconds(1))

```

#### [Streaming](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Streaming)

When dealing with larger amount of data, it’s critical to stream the response body instead of aggregating in-memory. The following example demonstrates how to count the number of bytes in a streaming response body:

##### [Using Swift Concurrency](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Using-Swift-Concurrency)

```
do {
    let request = HTTPClientRequest(url: "https://apple.com/")
    let response = try await HTTPClient.shared.execute(request, timeout: .seconds(30))
    print("HTTP head", response)

    // if defined, the content-length headers announces the size of the body
    let expectedBytes = response.headers.first(name: "content-length").flatMap(Int.init)

    var receivedBytes = 0
    // asynchronously iterates over all body fragments
    // this loop will automatically propagate backpressure correctly
    for try await buffer in response.body {
        // for this example, we are just interested in the size of the fragment
        receivedBytes += buffer.readableBytes

        if let expectedBytes = expectedBytes {
            // if the body size is known, we calculate a progress indicator
            let progress = Double(receivedBytes) / Double(expectedBytes)
            print("progress: \(Int(progress * 100))%")
        }
    }
    print("did receive \(receivedBytes) bytes")
} catch {
    print("request failed:", error)
}

```

##### [Using HTTPClientResponseDelegate and SwiftNIO EventLoopFuture](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Using-HTTPClientResponseDelegate-and-SwiftNIO-EventLoopFuture)

```
import NIOCore
import NIOHTTP1

class CountingDelegate: HTTPClientResponseDelegate {
    typealias Response = Int

    var count = 0

    func didSendRequestHead(task: HTTPClient.Task<Response>, _ head: HTTPRequestHead) {
        // this is executed right after request head was sent, called once
    }

    func didSendRequestPart(task: HTTPClient.Task<Response>, _ part: IOData) {
        // this is executed when request body part is sent, could be called zero or more times
    }

    func didSendRequest(task: HTTPClient.Task<Response>) {
        // this is executed when request is fully sent, called once
    }

    func didReceiveHead(
        task: HTTPClient.Task<Response>,
        _ head: HTTPResponseHead
    ) -> EventLoopFuture<Void> {
        // this is executed when we receive HTTP response head part of the request
        // (it contains response code and headers), called once in case backpressure
        // is needed, all reads will be paused until returned future is resolved
        return task.eventLoop.makeSucceededFuture(())
    }

    func didReceiveBodyPart(
        task: HTTPClient.Task<Response>,
        _ buffer: ByteBuffer
    ) -> EventLoopFuture<Void> {
        // this is executed when we receive parts of the response body, could be called zero or more times
        count += buffer.readableBytes
        // in case backpressure is needed, all reads will be paused until returned future is resolved
        return task.eventLoop.makeSucceededFuture(())
    }

    func didFinishRequest(task: HTTPClient.Task<Response>) throws -> Int {
        // this is called when the request is fully read, called once
        // this is where you return a result or throw any errors you require to propagate to the client
        return count
    }

    func didReceiveError(task: HTTPClient.Task<Response>, _ error: Error) {
        // this is called when we receive any network-related error, called once
    }
}

let request = try HTTPClient.Request(url: "https://apple.com/")
let delegate = CountingDelegate()

httpClient.execute(request: request, delegate: delegate).futureResult.whenSuccess { count in
    print(count)
}

```

#### [File downloads](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#File-downloads)

Based on the `HTTPClientResponseDelegate` example above you can build more complex delegates, the built-in `FileDownloadDelegate` is one of them. It allows streaming the downloaded data asynchronously, while reporting the download progress at the same time, like in the following example:

```
let request = try HTTPClient.Request(
    url: "https://swift.org/builds/development/ubuntu1804/latest-build.yml"
)

let delegate = try FileDownloadDelegate(path: "/tmp/latest-build.yml", reportProgress: {
    if let totalBytes = $0.totalBytes {
        print("Total bytes count: \(totalBytes)")
    }
    print("Downloaded \($0.receivedBytes) bytes so far")
})

HTTPClient.shared.execute(request: request, delegate: delegate).futureResult
    .whenSuccess { progress in
        if let totalBytes = progress.totalBytes {
            print("Final total bytes count: \(totalBytes)")
        }
        print("Downloaded finished with \(progress.receivedBytes) bytes downloaded")
    }

```

#### [Unix Domain Socket Paths](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Unix-Domain-Socket-Paths)

Connecting to servers bound to socket paths is easy:

```
HTTPClient.shared.execute(
    .GET,
    socketPath: "/tmp/myServer.socket",
    urlPath: "/path/to/resource"
).whenComplete (...)

```

Connecting over TLS to a unix domain socket path is possible as well:

```
HTTPClient.shared.execute(
    .POST,
    secureSocketPath: "/tmp/myServer.socket",
    urlPath: "/path/to/resource",
    body: .string("hello")
).whenComplete (...)

```

Direct URLs can easily be constructed to be executed in other scenarios:

```
let socketPathBasedURL = URL(
    httpURLWithSocketPath: "/tmp/myServer.socket",
    uri: "/path/to/resource"
)
let secureSocketPathBasedURL = URL(
    httpsURLWithSocketPath: "/tmp/myServer.socket",
    uri: "/path/to/resource"
)

```

#### [Disabling HTTP/2](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Disabling-HTTP2)

The exclusive use of HTTP/1 is possible by setting [`httpVersion`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclient/configuration/httpversion-swift.property) to [`http1Only`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclient/configuration/httpversion-swift.struct/http1only) on the [`HTTPClient.Configuration`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclient/configuration):

```
var configuration = HTTPClient.Configuration()
configuration.httpVersion = .http1Only
let client = HTTPClient(
    eventLoopGroupProvider: .singleton,
    configuration: configuration
)

```

### [Security](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Security)

AsyncHTTPClient’s security process is documented on [GitHub](https://github.com/swift-server/async-http-client/blob/main/SECURITY.md).

## [Topics](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#topics)

### [HTTPClient](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#HTTPClient)

[`class HTTPClient`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclient)

HTTPClient class provides API for request execution.

[`struct HTTPClientRequest`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclientrequest)

A representation of an HTTP request for the Swift Concurrency HTTPClient API.

[`struct HTTPClientResponse`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclientresponse)

A representation of an HTTP response for the Swift Concurrency HTTPClient API.

### [HTTP Client Delegates](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#HTTP-Client-Delegates)

[`protocol HTTPClientResponseDelegate`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclientresponsedelegate)

[`HTTPClientResponseDelegate`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclientresponsedelegate) allows an implementation to receive notifications about request processing and to control how response parts are processed.

[`class ResponseAccumulator`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/responseaccumulator)

The default [`HTTPClientResponseDelegate`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclientresponsedelegate).

[`class FileDownloadDelegate`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/filedownloaddelegate)

Handles a streaming download to a given file path, allowing headers and progress to be reported.

[`class HTTPClientCopyingDelegate`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclientcopyingdelegate)

An [`HTTPClientResponseDelegate`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclientresponsedelegate) that wraps a callback.

### [Errors](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Errors)

[`struct HTTPClientError`](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/httpclienterror)

Possible client errors.

### [Extended Modules](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient\#Extended-Modules)

[Foundation](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient/foundation)

- [AsyncHTTPClient](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient#app-top)
- [Overview](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient#Overview)
- [Getting Started](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient#Getting-Started)
- [Usage guide](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient#Usage-guide)
- [Security](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient#Security)
- [Topics](https://swiftpackageindex.com/swift-server/async-http-client/main/documentation/asynchttpclient#topics)

Current page is AsyncHTTPClient

|
|
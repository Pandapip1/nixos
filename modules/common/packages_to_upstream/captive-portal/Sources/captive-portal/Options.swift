// Command line and environment shared by both platforms.
//
//   captive-portal [URL]
//
// PROXY is the "host:port" of the SOCKS5 proxy captive-browser sets up. With
// no PROXY the window refuses to start: loading through the normal resolver
// is exactly what this tool exists to avoid.
//
// No Foundation here: on Linux it carries its own ICU, which clashes with
// WebKitGTK's when both load into one process. The standard library and libc
// are enough.

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

struct Options {
    var proxyHost: String
    var proxyPort: UInt16
    var startURL: String

    static let defaultURL = "http://neverssl.com/"

    static func parse() -> Options {
        let arguments = CommandLine.arguments.dropFirst()
        if arguments.contains("-h") || arguments.contains("--help") {
            print("usage: captive-portal [URL]   (with PROXY=host:port set)")
            exit(0)
        }
        guard let raw = getenv("PROXY"), case let proxy = String(cString: raw), !proxy.isEmpty
        else {
            fail("PROXY is not set; run this through captive-browser")
        }
        guard let (host, port) = splitHostPort(proxy) else {
            fail("PROXY must be host:port, got \"\(proxy)\"")
        }
        return Options(
            proxyHost: host, proxyPort: port,
            startURL: normalize(arguments.first ?? defaultURL))
    }

    /// Accepts "host:port", "[v6]:port" and "localhost:port".
    static func splitHostPort(_ value: String) -> (String, UInt16)? {
        guard let colon = value.lastIndex(of: ":"),
            let port = UInt16(value[value.index(after: colon)...]), port != 0
        else { return nil }
        var host = String(value[..<colon])
        if host.hasPrefix("[") && host.hasSuffix("]") {
            host = String(host.dropFirst().dropLast())
        }
        return host.isEmpty ? nil : (host, port)
    }

    /// What the user typed into the address bar, made into something loadable.
    /// Portals are usually reached over plain HTTP, so that is the default.
    static func normalize(_ typed: String) -> String {
        let trimmed = String(
            typed.drop(while: \.isWhitespace).reversed().drop(while: \.isWhitespace).reversed())
        if trimmed.isEmpty { return defaultURL }
        if trimmed.contains("://") { return trimmed }
        return "http://" + trimmed
    }

    static func fail(_ message: String) -> Never {
        fputs("captive-portal: \(message)\n", stderr)
        exit(2)
    }
}

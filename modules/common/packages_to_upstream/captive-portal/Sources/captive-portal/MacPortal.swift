#if os(macOS)
import AppKit
import Network
import WebKit

/// A single window: an address bar over a WKWebView. The web view keeps nothing
/// on disk (non-persistent data store) and sends every connection, name lookup
/// included, through the SOCKS proxy.
final class MacPortal: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    private let options: Options
    private var window: NSWindow!
    private var webView: WKWebView!
    private var addressField: NSTextField!
    private var observations: [NSKeyValueObservation] = []

    init(options: Options) {
        self.options = options
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = WKWebsiteDataStore.nonPersistent()
        guard let port = NWEndpoint.Port(rawValue: options.proxyPort) else {
            Options.fail("bad proxy port \(options.proxyPort)")
        }
        store.proxyConfigurations = [
            ProxyConfiguration(
                socksv5Proxy: .hostPort(host: NWEndpoint.Host(options.proxyHost), port: port))
        ]

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = store
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        addressField = NSTextField(string: options.startURL)
        addressField.placeholderString = "Address"
        addressField.target = self
        addressField.action = #selector(addressEntered)
        addressField.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(addressField)
        content.addSubview(webView)
        NSLayoutConstraint.activate([
            addressField.topAnchor.constraint(equalTo: content.topAnchor, constant: 8),
            addressField.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 8),
            addressField.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -8),
            webView.topAnchor.constraint(equalTo: addressField.bottomAnchor, constant: 8),
            webView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: content.bottomAnchor),
        ])

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 750),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = "Captive portal"
        window.contentView = content
        window.center()
        window.makeKeyAndOrderFront(nil)

        observations = [
            webView.observe(\.url) { [weak self] webView, _ in
                if let url = webView.url?.absoluteString { self?.addressField.stringValue = url }
            },
            webView.observe(\.title) { [weak self] webView, _ in
                let title = webView.title ?? ""
                self?.window.title = title.isEmpty ? "Captive portal" : "Captive portal — \(title)"
            },
        ]

        load(options.startURL)
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @objc private func addressEntered() {
        load(Options.normalize(addressField.stringValue))
    }

    private func load(_ address: String) {
        guard let url = URL(string: address) else { return }
        webView.load(URLRequest(url: url))
    }

    func webView(
        _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        showError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(error)
    }

    private func showError(_ error: Error) {
        let nsError = error as NSError
        // A redirect or a new navigation cancelling the old one is not an error.
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return }
        let message = nsError.localizedDescription
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
        webView.loadHTMLString(
            "<p style=\"font: 14px -apple-system; margin: 2em\">Could not load the page: \(message)</p>",
            baseURL: nil)
    }
}

func runPortal(_ options: Options) -> Never {
    let app = NSApplication.shared
    app.setActivationPolicy(.regular)
    let portal = MacPortal(options: options)
    app.delegate = portal
    app.run()
    exit(0)
}
#endif

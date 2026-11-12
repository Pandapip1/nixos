#if os(Linux)
import CWebKitGTK
import Glibc

/// A single window: an address bar over a WebKitGTK web view. The GTK and
/// WebKit calls live in CWebKitGTK/shim.h; this side only holds the objects
/// and reacts to signals.
final class LinuxPortal {
    let options: Options
    var window: portal_object?
    var entry: portal_object?
    var webView: portal_object?

    init(options: Options) {
        self.options = options
    }

    var context: UnsafeMutableRawPointer { Unmanaged.passUnretained(self).toOpaque() }

    static func from(_ pointer: UnsafeMutableRawPointer?) -> LinuxPortal {
        Unmanaged<LinuxPortal>.fromOpaque(pointer!).takeUnretainedValue()
    }

    func activate(_ app: portal_object) {
        let window = portal_window_new(app)
        portal_window_set_title(window, "Captive portal")

        let box = portal_box_new()
        let entry = portal_entry_new()
        portal_entry_set_text(entry, options.startURL)
        portal_connect(entry, "activate", unsafeBitCast(onEntryActivate, to: GCallback.self), context)
        portal_box_append(box, entry)

        let webView = portal_web_view_new("socks5://\(proxyAuthority())")
        portal_connect(webView, "notify::uri", unsafeBitCast(onURINotify, to: GCallback.self), context)
        portal_connect(webView, "notify::title", unsafeBitCast(onTitleNotify, to: GCallback.self), context)
        portal_box_append(box, webView)

        self.window = window
        self.entry = entry
        self.webView = webView
        portal_web_view_load(webView, options.startURL)
        portal_window_show(window, box)
    }

    private func proxyAuthority() -> String {
        let host = options.proxyHost.contains(":") ? "[\(options.proxyHost)]" : options.proxyHost
        return "\(host):\(options.proxyPort)"
    }

    func addressEntered() {
        guard let entry, let webView, let text = portal_entry_text(entry) else { return }
        portal_web_view_load(webView, Options.normalize(String(cString: text)))
    }

    func uriChanged() {
        guard let entry, let webView, let uri = portal_web_view_uri(webView) else { return }
        let text = String(cString: uri)
        if !text.hasPrefix("about:") { portal_entry_set_text(entry, text) }
    }

    func titleChanged() {
        guard let window, let webView else { return }
        let title = portal_web_view_title(webView).map { String(cString: $0) } ?? ""
        portal_window_set_title(window, title.isEmpty ? "Captive portal" : "Captive portal — \(title)")
    }
}

// Signal handlers. GTK calls them with the emitting object first and our
// context pointer last; "notify::" handlers also get the GParamSpec.
private typealias Handler = @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Void
private typealias NotifyHandler =
    @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Void

private let onAppActivate: Handler = { app, data in LinuxPortal.from(data).activate(app!) }
private let onEntryActivate: Handler = { _, data in LinuxPortal.from(data).addressEntered() }
private let onURINotify: NotifyHandler = { _, _, data in LinuxPortal.from(data).uriChanged() }
private let onTitleNotify: NotifyHandler = { _, _, data in LinuxPortal.from(data).titleChanged() }

func runPortal(_ options: Options) -> Never {
    let portal = LinuxPortal(options: options)
    let app = portal_app_new("com.pandapip1.CaptivePortal")
    portal_connect(app, "activate", unsafeBitCast(onAppActivate, to: GCallback.self), portal.context)
    let status = portal_app_run(app)
    portal_unref(app)
    withExtendedLifetime(portal) {}
    exit(status)
}
#endif

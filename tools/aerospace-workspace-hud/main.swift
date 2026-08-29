import Cocoa
import Darwin

private let hudPort: in_port_t = 17371

final class WorkspaceHUD: NSObject, NSApplicationDelegate {
    private var socketFD: Int32 = -1
    private var readSource: DispatchSourceRead?
    private var window: NSWindow?
    private var label: NSTextField?
    private var hideWorkItem: DispatchWorkItem?
    private var displayGeneration = 0

    private let oneShotText: String?

    init(oneShotText: String? = nil) {
        self.oneShotText = oneShotText
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let oneShotText {
            show(oneShotText)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                NSApp.terminate(nil)
            }
        } else {
            startServer()
        }
    }

    private func startServer() {
        socketFD = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socketFD >= 0 else {
            NSLog("aerospace-workspace-hud: socket() failed")
            NSApp.terminate(nil)
            return
        }

        var reuse: Int32 = 1
        setsockopt(socketFD, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = hudPort.bigEndian
        address.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))

        let bindResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                Darwin.bind(socketFD, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult == 0 else {
            NSLog("aerospace-workspace-hud: bind() failed")
            close(socketFD)
            NSApp.terminate(nil)
            return
        }

        let source = DispatchSource.makeReadSource(fileDescriptor: socketFD, queue: .main)
        source.setEventHandler { [weak self] in
            self?.receive()
        }
        source.setCancelHandler { [socketFD] in
            close(socketFD)
        }
        source.resume()
        readSource = source
    }

    private func receive() {
        var buffer = [UInt8](repeating: 0, count: 32)
        let count = buffer.withUnsafeMutableBytes { rawBuffer in
            recv(socketFD, rawBuffer.baseAddress, rawBuffer.count, 0)
        }

        guard count > 0 else {
            return
        }

        let data = Data(buffer.prefix(count))
        guard let rawText = String(data: data, encoding: .utf8) else {
            return
        }

        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        show(text.isEmpty ? "?" : text)
    }

    private func show(_ text: String) {
        let window = ensureWindow()
        displayGeneration += 1
        let generation = displayGeneration

        label?.attributedStringValue = attributedText(text)
        hideWorkItem?.cancel()
        hideWorkItem = nil

        window.animations.removeAll()
        window.alphaValue = 1
        window.orderFrontRegardless()

        let hide = DispatchWorkItem { [weak self, weak window] in
            guard let self, let window else {
                return
            }
            guard self.displayGeneration == generation else {
                return
            }

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.38
                window.animator().alphaValue = 0
            } completionHandler: {
                guard self.displayGeneration == generation else {
                    return
                }
                window.orderOut(nil)
            }

            if self.displayGeneration == generation {
                self.hideWorkItem = nil
            }
        }

        hideWorkItem = hide
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: hide)
    }

    private func ensureWindow() -> NSWindow {
        if let window {
            return window
        }

        let screen = screenContainingMouse() ?? NSScreen.main
        let frame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = NSSize(width: 44, height: 44)
        let margin: CGFloat = 26
        let rect = NSRect(
            x: frame.maxX - size.width - margin,
            y: frame.maxY - size.height - margin,
            width: size.width,
            height: size.height
        )

        let window = NSWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.alphaValue = 0

        let label = NSTextField(labelWithString: "?")
        label.frame = NSRect(origin: .zero, size: size)
        label.alignment = .center
        label.attributedStringValue = attributedText("?")

        window.contentView = label
        self.window = window
        self.label = label

        return window
    }

    private func attributedText(_ text: String) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.55)
        shadow.shadowBlurRadius = 6
        shadow.shadowOffset = NSSize(width: 0, height: -1)

        return NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 32, weight: .semibold),
                .foregroundColor: NSColor(calibratedWhite: 1, alpha: 0.92),
                .paragraphStyle: paragraph,
                .shadow: shadow
            ]
        )
    }

    private func screenContainingMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        }
    }
}

let app = NSApplication.shared
let args = Array(CommandLine.arguments.dropFirst())
let delegate: WorkspaceHUD

if args.first == "--server" {
    delegate = WorkspaceHUD()
} else {
    let text = args.first?.trimmingCharacters(in: .whitespacesAndNewlines)
    delegate = WorkspaceHUD(oneShotText: (text?.isEmpty == false) ? text : "?")
}

app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()

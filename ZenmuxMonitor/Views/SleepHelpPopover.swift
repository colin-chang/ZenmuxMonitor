import AppKit
import SwiftUI

// MARK: - Sleep Help Popover

/// Uses AppKit NSPopover to avoid SwiftUI popover nesting issues
/// when rendered inside the parent NSPopover.
struct SleepHelpPopover: NSViewRepresentable {
    @Binding var isPresented: Bool
    let text: String

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let existing = context.coordinator.popover

        if isPresented && existing == nil {
            let popover = NSPopover()
            popover.behavior = .transient
            popover.delegate = context.coordinator
            popover.contentViewController = NSHostingController(rootView:
                Text(text)
                    .font(.callout)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(width: 250)
            )
            popover.show(relativeTo: nsView.bounds, of: nsView, preferredEdge: .maxY)
            // Separate content from vibrant view hierarchy so text renders
            // without vibrancy compositing artifacts.
            DispatchQueue.main.async {
                separatePopoverContent(popover)
            }
            context.coordinator.popover = popover
        } else if !isPresented && existing != nil {
            existing?.close()
            context.coordinator.popover = nil
        }
    }

    /// Move the popover's content subtree out from under its internal
    /// NSVisualEffectView so the vibrant background stays but the content
    /// does not participate in vibrancy compositing.
    private func separatePopoverContent(_ popover: NSPopover) {
        guard let hostingView = popover.contentViewController?.view else { return }

        var vev: NSVisualEffectView?
        var current: NSView? = hostingView
        while current != nil {
            if let v = current as? NSVisualEffectView {
                vev = v
                break
            }
            current = current?.superview
        }
        guard let vev = vev, let vevSuperview = vev.superview else { return }

        var directChild: NSView = hostingView
        while let parent = directChild.superview, parent != vev {
            directChild = parent
        }
        guard directChild.superview === vev else { return }

        directChild.removeFromSuperview()
        vevSuperview.addSubview(directChild)
        directChild.translatesAutoresizingMaskIntoConstraints = true
        directChild.frame = vev.bounds
        directChild.autoresizingMask = [.width, .height]
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    final class Coordinator: NSObject, NSPopoverDelegate {
        var popover: NSPopover?
        var isPresented: Binding<Bool>

        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }

        func popoverDidClose(_ notification: Notification) {
            popover = nil
            if isPresented.wrappedValue {
                isPresented.wrappedValue = false
            }
        }
    }
}

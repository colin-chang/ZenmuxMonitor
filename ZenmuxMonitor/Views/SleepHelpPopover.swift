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
            Task { @MainActor in
                PopoverVibrancyFix.separateContent(popover)
            }
            context.coordinator.popover = popover
        } else if !isPresented && existing != nil {
            existing?.close()
            context.coordinator.popover = nil
        }
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

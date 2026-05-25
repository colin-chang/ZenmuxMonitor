import AppKit

/// Moves the popover's content subtree out from under its internal
/// NSVisualEffectView so the vibrant background stays but the content
/// does not participate in vibrancy compositing — preventing the white
/// halo on colored text in light mode.
enum PopoverVibrancyFix {
    @MainActor static func separateContent(_ popover: NSPopover) {
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
}

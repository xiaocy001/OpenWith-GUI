import AppKit
import SwiftUI

struct TableScrollResetView: NSViewRepresentable {
    let token: Int

    func makeCoordinator() -> TableScrollResetCoordinator {
        TableScrollResetCoordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.isHidden = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let scrollView = TableScrollResetCoordinator.findScrollView(near: nsView) else {
                return
            }

            context.coordinator.resetIfNeeded(token: token, scrollView: scrollView)
        }
    }
}

@MainActor
final class TableScrollResetCoordinator {
    private var lastAppliedToken: Int?

    func resetIfNeeded(token: Int, scrollView: NSScrollView) {
        guard lastAppliedToken != token else {
            return
        }

        lastAppliedToken = token
        Self.scrollToTop(scrollView)
    }

    @MainActor
    static func findScrollView(near view: NSView) -> NSScrollView? {
        var currentView: NSView? = view

        while let candidate = currentView {
            if let scrollView = firstScrollView(in: candidate, excluding: view) {
                return scrollView
            }

            currentView = candidate.superview
        }

        return nil
    }

    @MainActor
    static func scrollToTop(_ scrollView: NSScrollView) {
        guard let documentView = scrollView.documentView else {
            return
        }

        let originY: CGFloat
        if documentView.isFlipped {
            originY = 0
        } else {
            originY = max(0, documentView.bounds.height - scrollView.contentView.bounds.height)
        }

        let topPoint = NSPoint(x: scrollView.contentView.bounds.origin.x, y: originY)
        scrollView.contentView.scroll(to: topPoint)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    @MainActor
    private static func firstScrollView(in root: NSView, excluding excludedView: NSView) -> NSScrollView? {
        for subview in root.subviews where subview !== excludedView {
            if let scrollView = subview as? NSScrollView {
                return scrollView
            }

            if let nestedScrollView = firstScrollView(in: subview, excluding: excludedView) {
                return nestedScrollView
            }
        }

        return nil
    }
}

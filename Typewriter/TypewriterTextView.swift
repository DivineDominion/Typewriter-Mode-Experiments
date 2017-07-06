//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

class TypewriterTextView: NSTextView {

    var isDrawingTypingHighlight = true
    var highlight: NSRect {
        set { highlightWithOffset = newValue.offsetBy(dx: 0, dy: verticalOffset) }
        get { return highlightWithOffset.offsetBy(dx: 0, dy: -verticalOffset) }
    }
    var highlightWithOffset: NSRect = NSRect.zero

    override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)

        guard isDrawingTypingHighlight else { return }

        // TODO: highlight is not production-ready: resizing the container does not move the highlight and pasting strings spanning multiple line fragments, then typing a character shows 2 highlighters
        NSColor(calibratedRed: 1, green: 1, blue: 0, alpha: 1).set()
        NSRectFill(highlightWithOffset)
    }

    func hideHighlight() {
        highlight = NSRect.zero
    }

    func moveHighlight(rect: NSRect) {
        guard isDrawingTypingHighlight else { return }
        highlight = rect
    }

    func moveHighlight(by distance: CGFloat) {
        moveHighlight(rect: highlight.offsetBy(dx: 0, dy: distance))
    }

    var verticalOffset: CGFloat = 0

    func lockTypewriterDistance() {

        let screenInsertionPointRect = firstRect(forCharacterRange: selectedRange(), actualRange: nil)
        guard let windowInsertionPointRect = window?.convertFromScreen(screenInsertionPointRect) else { return }
        guard let enclosingScrollView = self.enclosingScrollView else { return }

        let insertionPointRect = enclosingScrollView.convert(windowInsertionPointRect, from: nil)
        let distance = insertionPointRect.origin.y - enclosingScrollView.frame.origin.y - enclosingScrollView.contentView.frame.origin.y
        let newOffset = ceil(-(enclosingScrollView.bounds.height / 2) + distance)
        let oldOffset = verticalOffset
        let difference = newOffset - oldOffset
        self.verticalOffset = newOffset
        self.scroll(by: difference)
        self.moveHighlight(by: difference)
        fixInsertionPointPosition()
    }

    func unlockTypewriterDistance() {

        let oldOffset = verticalOffset
        verticalOffset = 0
        self.scroll(by: -oldOffset)

        fixInsertionPointPosition()
    }

    /// After changing the `textContainerOrigin`, the insertion point sometimes
    /// remains where it was, not moving with the text.
    private func fixInsertionPointPosition() {
        self.setSelectedRange(selectedRange())
        self.needsDisplay = true
    }

    override var textContainerOrigin: NSPoint {
        let origin = super.textContainerOrigin
        return origin.applying(.init(translationX: 0, y: verticalOffset))
    }

    func scrollViewDidResize(_ scrollView: NSScrollView) {

        let halfScreen = scrollView.bounds.height / 2
        textContainerInset = NSSize(width: 0, height: halfScreen)
    }

    func scroll(by offset: CGFloat) {

        guard let visibleRect = enclosingScrollView?.contentView.documentVisibleRect else { return }
        let point = visibleRect.origin
            .applying(.init(translationX: 0, y: offset))
        scroll(point)
    }
}

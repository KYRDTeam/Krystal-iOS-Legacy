//
//  GrowingTextView.swift
//  https://gist.github.com/Bogidon/cc0c9ae6f041413c39fb0ff146ad1b18
//
//  Created by Bogdan Vitoc on 02/22/2017.
//  Distributed under the MIT License: https://gist.github.com/Bogidon/cc0c9ae6f041413c39fb0ff146ad1b18#file-license
//

import UIKit

/**
 A subclass of `UITextView` that grows with its text without completely disabling scrolling. It does this by updating
 `intrinsicContentSize`. This means you can set inequality constraints so the text is only scrollable under certain
 conditions. (e.g. you can set a maximum with a ≤ constraint).

 - Note:
 See [this gist](https://gist.github.com/Bogidon/632e265b784ef978d5d8c0b86858c2ee) for an alternate version that can animate.
 */
@IBDesignable
public class GrowingTextView: UITextView {
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
      NotificationCenter.default.addObserver(self, selector: #selector(scrollToBottom), name: UITextView.textDidChangeNotification, object: nil)
    }

    public override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()

            // This eliminates a weird UI glitch where inserting a new line sometimes causes there to be a
            // content offset when self.bounds == self.contentSize causing the text at the top to be snipped
            // and a gap at the bottom.
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    public override var intrinsicContentSize: CGSize {
        let width = super.intrinsicContentSize.width
        return CGSize(width: width, height: contentSize.height)
    }
  
    @objc func scrollToBottom() {
        // This needs to happen so the superview updates the bounds of this text view from its new intrinsicContentSize
        // If not called, the bounds will be smaller than the contentSize at this moment, causing the guard to not be triggered.
        superview?.layoutIfNeeded()

        // Prevent scrolling if the textview is large enough to show all its content. Otherwise there is a jump.
        guard contentSize.height > bounds.size.height else {
            return
        }

        let offsetY = (contentSize.height + contentInset.top) - bounds.size.height
        UIView.animate(withDuration: 0.125) {
            self.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
        }
    }
}

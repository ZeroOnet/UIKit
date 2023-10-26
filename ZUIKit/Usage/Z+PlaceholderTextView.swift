//
//  Z+PlaceholderTextView.swift
//  ZUIKit
//
//  Created by 李文康 on 2023/10/26.
//

extension Z {
    /// A text view with placeholder.
    ///
    /// - Important: Expect color, text attributes of text view should be equal to placeholder.
    final class PlaceholderTextView: UITextView {
        var onTextDidChange: ((String) -> Void)?

        override init(frame: CGRect, textContainer: NSTextContainer?) {
            super.init(frame: frame, textContainer: textContainer)
            _init()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            _init()
        }

        override var textContainerInset: UIEdgeInsets {
            didSet { _updatePlaceholderLabelConstraints() }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            let maxWidth = textContainer.size.width - textContainer.lineFragmentPadding * 2
            _placeholderLabel.preferredMaxLayoutWidth = maxWidth
        }

        func setPlaceholder(_ attributedText: NSAttributedString) {
            _placeholderLabel.attributedText = attributedText
        }

        private lazy var _placeholderLabel: UILabel = {
            let result = UILabel()
            result.numberOfLines = 0
            result.translatesAutoresizingMaskIntoConstraints = false
            return result
        }()
    }
}

// MARK: - Private
extension Z.PlaceholderTextView {
    private func _init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_textDidChange),
            name: UITextView.textDidChangeNotification,
            object: self
        )
        _configureSubviews()
    }

    private func _configureSubviews() {
        addSubview(_placeholderLabel)
        _addPlaceholderLabelConstraints()
    }

    private func _addPlaceholderLabelConstraints() {
        NSLayoutConstraint.activate([
            _placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: textContainerInset.top),
            _placeholderLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: textContainerInset.left + textContainer.lineFragmentPadding
            ),
            _placeholderLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func _updatePlaceholderLabelConstraints() {
        NSLayoutConstraint.deactivate(_placeholderLabel.constraints)
        _addPlaceholderLabelConstraints()
    }
}

// MARK: - Target action
extension Z.PlaceholderTextView {
    @objc
    private func _textDidChange() {
        _placeholderLabel.isHidden = !text.isEmpty
        onTextDidChange?(text)
    }
}

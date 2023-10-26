//
//  Z+IntensityVisualEffectView.swift
//  ZUIKit
//
//  Created by 李文康 on 2023/10/26.
//

extension Z {
    /// A subclass of UIVisualEffectView, supports custom blur value.
    /// - Reference: https://gist.github.com/darrarski/29a2a4515508e385c90b3ffe6f975df7
    /// - Important: call as follows if use it in UICollectionViewCell or UITableViewCell:
    /// ```swift
    ///     override func prepareForReuse() {
    ///         super.prepareForReuse()
    ///         DispatchQueue.main.async {
    ///             effectView.apply()
    ///         }
    ///     }
    /// ```
    final class IntensityVisualEffectView: UIVisualEffectView {
        private let _effect: UIVisualEffect
        private let _intensity: CGFloat
        /// intensity ∈ [0, 1] ≈ blur ∈ [0, 40]
        init(effect: UIVisualEffect, intensity: CGFloat) {
            _effect = effect
            _intensity = min(max(0, intensity), 1)
            super.init(effect: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        deinit { _animator?.stopAnimation(true) }

        override func layoutSubviews() {
            super.layoutSubviews()
            apply()
        }

        override func draw(_ rect: CGRect) {
            super.draw(rect)
            apply()
        }

        func apply() {
            effect = nil
            _animator?.stopAnimation(true)
            _animator = UIViewPropertyAnimator(duration: 0, curve: .linear) { [weak self] in
                self?.effect = self?._effect
            }
            _animator?.fractionComplete = _intensity
        }

        private var _animator: UIViewPropertyAnimator?
    }
}

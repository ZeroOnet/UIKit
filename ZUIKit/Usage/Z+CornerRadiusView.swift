//
//  Z+CornerRadiusView.swift
//  ZUIKit
//
//  Created by 李文康 on 2023/10/26.
//

extension Z {
    /// A subclass of UIView, supports custom corner radius with different value.
    ///
    /// - Important: Use `layer.lineWidth` and `layer.strokeColor` to set view's border.
    /// We cannot make `layer.borderWidth` and `layer.lineWidth` have same effect like this:
    /// ```swift
    /// extension Z.CornerRadiusView {
    ///     fileprivate class _ZCShapeLayer: CAShapeLayer {
    ///         override var borderWidth: CGFloat {
    ///             get { lineWidth }
    ///             set { super.borderWidth = 0; lineWidth = newValue; }
    ///         }
    ///     }
    /// }
    /// ```
    /// This code snippet will add border for bounds with `layer.cornerRadius`.
    final class CornerRadiusView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            _init()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            _init()
        }

        var radius: Radius = .init() {
            didSet { setNeedsDisplay() }
        }

        override class var layerClass: AnyClass { CAShapeLayer.self }

        override func layoutSubviews() {
            super.layoutSubviews()
            _applyShapePath()
        }

        // swiftlint:disable:next force_cast
        override var layer: CAShapeLayer { super.layer as! CAShapeLayer }

        override var backgroundColor: UIColor? {
            get {
                guard let color = layer.fillColor else { return nil }
                return UIColor(cgColor: color)
            }

            set { layer.fillColor = newValue?.cgColor }
        }
    }
}

extension Z.CornerRadiusView {
    struct Radius {
        let topLeft: CGFloat
        let topRight: CGFloat
        let bottomLeft: CGFloat
        let bottomRight: CGFloat

        init(
            topLeft: CGFloat = 0,
            topRight: CGFloat = 0,
            bottomLeft: CGFloat = 0,
            bottomRight: CGFloat = 0
        ) {
            self.topLeft = topLeft
            self.topRight = topRight
            self.bottomLeft = bottomLeft
            self.bottomRight = bottomRight
        }

        static func all(radius: CGFloat) -> Radius {
            .init(topLeft: radius, topRight: radius, bottomLeft: radius, bottomRight: radius)
        }
    }
}

// MARK: - Private
extension Z.CornerRadiusView {
    private func _init() {
        // Clean default value.
        backgroundColor = nil
        layer.borderWidth = 0
    }

    private func _applyShapePath() {
        let rect = bounds
        let minX = rect.minX
        let minY = rect.minY
        let maxX = rect.maxX
        let maxY = rect.maxY
        let topLeftCenter = CGPoint(x: minX + radius.topLeft, y: minY + radius.topLeft)
        let topRightCenter = CGPoint(x: maxX - radius.topRight, y: minY + radius.topRight)
        let bottomLeftCenter = CGPoint(x: minX + radius.bottomLeft, y: maxY - radius.bottomLeft)
        let bottomRightCenter = CGPoint(x: maxX - radius.bottomRight, y: maxY - radius.bottomRight)
        let path = CGMutablePath()
        path.addArc(
            center: topLeftCenter,
            radius: radius.topLeft,
            startAngle: .pi,
            endAngle: .pi * 3 / 2,
            clockwise: false
        )
        path.addArc(
            center: topRightCenter,
            radius: radius.topRight,
            startAngle: .pi * 3 / 2,
            endAngle: 0,
            clockwise: false
        )
        path.addArc(
            center: bottomRightCenter,
            radius: radius.bottomRight,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: false
        )
        path.addArc(
            center: bottomLeftCenter,
            radius: radius.bottomLeft,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: false
        )
        path.closeSubpath()
        layer.path = path
    }
}

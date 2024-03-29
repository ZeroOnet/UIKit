//
//  Z+CarouselView.swift
//  ZUIKit
//
//  Created by 李文康 on 2023/10/31.
//

// MARK: - Protocol
typealias ZCarouselable = ZCarouselGettable & ZCarouselControllable & UIView

protocol ZCarouselGettable {
    var currentPage: Int { get }
}

protocol ZCarouselControllable {
    func suspend()
    func resume()
    func refresh()
}

protocol ZCarouselSettable<T> {
    associatedtype T: ZCarouselable

    /// The time interval for scrolling automatically.
    var duration: TimeInterval { get }
    var numberOfItems: (() -> Int)? { get nonmutating set }
    var item: (() -> UIView)? { get nonmutating set }
    var tap: ((Int) -> Void)? { get nonmutating set }
    var pageDidChange: ((Int) -> Void)? { get nonmutating set }
    var updateItem: ((UIView, Int) -> Void)? { get nonmutating set }

    func activate() -> T
}

extension ZCarouselSettable {
    @discardableResult
    func numberOfItems(_ numberOfItems: @escaping () -> Int) -> Self {
        self.numberOfItems = numberOfItems
        return self
    }

    @discardableResult
    func item(_ item: @escaping () -> UIView) -> Self {
        self.item = item
        return self
    }

    @discardableResult
    func onTap(_ tap: @escaping (Int) -> Void) -> Self {
        self.tap = tap
        return self
    }

    @discardableResult
    func onPageDidChange(_ pageDidChange: @escaping (Int) -> Void) -> Self {
        self.pageDidChange = pageDidChange
        return self
    }

    @discardableResult
    func onUpdateItem(_ updateItem: @escaping (UIView, Int) -> Void) -> Self {
        self.updateItem = updateItem
        return self
    }
}

// MARK: - Usage
extension Z {
    /// A carousel view base on UIScrollView.
    ///
    /// - Usage:
    /// ```swift
    ///     let view = Carousel.view(duration: 1)
    ///         .numberOfItems { 0 }
    ///         .item { UIView() } // Important: Item view must be the same type.
    ///         .onTap { idx in }
    ///         .onPageDidChange { idx in }
    ///         .onUpdateItem { view, idx in }
    ///         .activate()
    ///
    ///     // Refresh data.
    ///     view.refresh()
    ///     // get current page.
    ///     view.currentPage
    ///     // Stop scrolling.
    ///     view.suspend()
    ///     // Resume scrolling.
    ///     view.resume()
    /// ```
    enum Carousel {
        static func view(duration: TimeInterval = 3) -> some ZCarouselSettable {
            View(duration: duration)
        }
    }
}

// MARK: - Private
extension Z.Carousel {
    fileprivate final class View: UIView, ZCarouselSettable, ZCarouselGettable {
        fileprivate let duration: TimeInterval
        fileprivate init(duration: TimeInterval) {
            self.duration = duration
            super.init(frame: .zero)
        }

        fileprivate func activate() -> View {
            assert(numberOfItems != nil)
            assert(item != nil)
            _configureSubviews()
            return self
        }

        fileprivate var currentPage: Int = 0

        fileprivate var numberOfItems: (() -> Int)?
        fileprivate var item: (() -> UIView)?
        fileprivate var tap: ((Int) -> Void)?
        fileprivate var pageDidChange: ((Int) -> Void)?
        fileprivate var updateItem: ((UIView, Int) -> Void)?

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        deinit { _timer.invalidate() }

        override func didMoveToWindow() { refresh() }

        private lazy var _scrollView: UIScrollView = {
            let result = UIScrollView()
            result.translatesAutoresizingMaskIntoConstraints = false
            result.isPagingEnabled = true
            result.delegate = self
            result.showsVerticalScrollIndicator = false
            result.showsHorizontalScrollIndicator = false
            result.scrollsToTop = false
            let tapGR = UITapGestureRecognizer(target: self, action: #selector(_tapAction))
            result.addGestureRecognizer(tapGR)
            let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(_longPressAction))
            result.addGestureRecognizer(longPressGR)
            return result
        }()

        private lazy var _timer: Timer = {
            let result = Timer(timeInterval: duration, repeats: true) { [weak self] _ in
                self?._timerAction()
            }
            RunLoop.current.add(result, forMode: .common)
            return result
        }()

        private let _internalItemsCount = 3
        private var _itemsPool: [UIView] = []
        private var itemsCount: Int { numberOfItems?() ?? 0 }
    }
}

extension Z.Carousel.View: ZCarouselControllable {
    func refresh() {
        _scrollView.isHidden = itemsCount == 0
        _scrollView.isScrollEnabled = itemsCount > 1
        guard !_scrollView.isHidden else { return }
        _change(page: 0)
        _reloadItems()
        if _scrollView.isScrollEnabled { resume() } else { suspend() }
    }

    func suspend() {
        _timer.fireDate = .distantFuture
    }

    func resume() {
        guard _scrollView.isScrollEnabled else { return }
        _timer.fireDate = Date(timeIntervalSinceNow: duration)
    }
}

extension Z.Carousel.View: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x >= 2 * scrollView.frame.width {
            _pageIn()
        } else if scrollView.contentOffset.x <= 0 {
            _pageOut()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        suspend()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        resume()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard _scrollView.contentOffset.x != 0 else { return }
        if _scrollView.contentOffset.x / _scrollView.frame.width != 1 {
            _scrollView.setContentOffset(CGPoint(x: _scrollView.frame.width, y: 0), animated: true)
        }
    }
}

extension Z.Carousel.View {
    private func _reloadItems() {
        layoutIfNeeded()

        _scrollView.contentOffset = CGPoint(x: _scrollView.frame.width, y: 0)

        let itemsCount = self.itemsCount
        var initLeftIndex: Int
        var initRightIndex: Int

        if currentPage == 0 {
            initLeftIndex = itemsCount - 1
            initRightIndex = 1 < itemsCount ? 1 : itemsCount - 1
        } else if currentPage == itemsCount - 1 {
            initLeftIndex = currentPage - 1
            initRightIndex = 0
        } else {
            let prepareLeftIndex = currentPage - 1
            initLeftIndex = prepareLeftIndex >= 0 && prepareLeftIndex < itemsCount ? prepareLeftIndex : currentPage
            let prepareRightIndex = currentPage + 1
            initRightIndex = prepareRightIndex >= 0 && prepareRightIndex < itemsCount ? prepareRightIndex : currentPage
        }

        [(initLeftIndex, _itemsPool[0]), (currentPage, _itemsPool[1]), (initRightIndex, _itemsPool[2])].forEach {
            updateItem?($0.1, $0.0)
        }
    }

    private func _pageIn() {
        guard itemsCount != 0 else { return }
        let pageIdx = currentPage == itemsCount - 1 ? 0 : currentPage + 1
        _change(page: pageIdx)
        _reloadItems()
    }

    private func _pageOut() {
        guard itemsCount != 0 else { return }
        let pageIdx = currentPage == 0 ? itemsCount - 1 : currentPage - 1
        _change(page: pageIdx)
        _reloadItems()
    }
}

extension Z.Carousel.View {
    private func _configureSubviews() {
        addSubview(_scrollView)
        NSLayoutConstraint.activate([
            _scrollView.topAnchor.constraint(equalTo: topAnchor),
            _scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            _scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            _scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        for idx in 0..<_internalItemsCount {
            guard let view = item?() else { return }
            view.translatesAutoresizingMaskIntoConstraints = false
            _itemsPool.append(view)
            _scrollView.addSubview(view)

            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: _scrollView.topAnchor),
                view.widthAnchor.constraint(equalTo: _scrollView.widthAnchor),
                view.bottomAnchor.constraint(equalTo: _scrollView.bottomAnchor),
                view.heightAnchor.constraint(equalTo: _scrollView.heightAnchor),
                NSLayoutConstraint(
                    item: view,
                    attribute: .centerX,
                    relatedBy: .equal,
                    toItem: _scrollView,
                    attribute: .centerX,
                    multiplier: CGFloat(2 * idx + 1),
                    constant: 0
                ),
            ])

            if idx == 0 {
                NSLayoutConstraint.activate([
                    view.leadingAnchor.constraint(equalTo: _scrollView.leadingAnchor)
                ])
            }

            if idx == _internalItemsCount - 1 {
                NSLayoutConstraint.activate([
                    view.trailingAnchor.constraint(equalTo: _scrollView.trailingAnchor)
                ])
            }
        }
    }

    @objc
    private func _tapAction() {
        tap?(currentPage)
    }

    @objc
    private func _longPressAction(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            suspend()
        } else {
            resume()
        }
    }

    private func _timerAction() {
        let offsetX = _scrollView.contentOffset.x + _scrollView.frame.width
        _scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
    }

    private func _change(page: Int) {
        currentPage = page
        pageDidChange?(page)
    }
}

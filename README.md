# ZUIKit
A collection of UI from work experience.
- PlaceholderTextView: A text view with placeholder.
- IntensityVisualEffectView: A subclass of UIVisualEffectView, supports custom blur value.
- CornerRadiusView: A subclass of UIView, supports custom corner radius with different value.
- CarouselView: A carousel view base on UIScrollView with three view instances in total.
```swift
let view = Carousel.view(duration: 1)
    .numberOfItems { 0 }
    .item { UIView() } // Important: Item view must be the same type.
    .onTap { idx in }
    .onPageDidChange { idx in }
    .onUpdateItem { view, idx in }
    .activate()

// Refresh data.
view.refresh()

// Get current page.
view.currentPage
// Stop scrolling.
view.suspend()
// Resume scrolling.
view.resume()
```

# Changelog

## 0.2.0

- Rework: the slider is now overlaid directly on the webview at the bound
  element's rect, instead of being mounted inside WebKit's child scroll view.
  The scroll-view mount (borrowed from native-map overlays) kept stealing or
  scrolling away the `UISlider`'s drag — a map uses gesture recognizers, but a
  slider tracks touches directly and needs a clean, scroll-view-free touch path.
  As a plain top-level subview the drag works. The placeholder element no longer
  needs `overflow: scroll`; the API is unchanged. Position still tracks the
  element via the onScroll/onResize hooks.

## 0.1.2

- Fix: the slider no longer scrolls out of view and drags now register. The
  mount container is `overflow: scroll` only so WebKit will materialise it; it was
  left actually scrollable, so a vertical drag slid the native slider out of view
  ("it disappears") and the scroll gesture stole horizontal drags from the
  `UISlider`. Scrolling on the container is now disabled (and re-asserted on
  every layout sync). Supersedes the partial 0.1.1 touch-flag fix.

## 0.1.1

- Fix: dragging the slider now works. The slider is mounted inside the webview's
  scroll view, which by default delayed and cancelled the `UISlider`'s touch
  tracking (so drags were stolen as scrolls); its `delaysContentTouches` and
  `canCancelContentTouches` are now disabled. Hardware-button sync and styling
  were already working.

## 0.1.0

- Initial release. iOS-only.
- `VolumeSlider` — a native `MPVolumeView` overlaid on the webview, bound to a
  DOM element, so an on-screen volume slider and the hardware volume buttons stay
  in sync (which a custom web slider cannot do on iOS).
- Stylable track and thumb colours to match your app's accent.
- `getVolume()` and a `volumeChange` listener for reflecting system volume in your
  own UI.

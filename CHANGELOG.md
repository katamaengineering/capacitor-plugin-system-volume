# Changelog

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

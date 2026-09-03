# Changelog

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

# Changelog

## 0.1.0

- Initial release. iOS-only.
- `VolumeSlider` — a native `MPVolumeView` overlaid on the webview, bound to a
  DOM element, so an on-screen volume slider and the hardware volume buttons stay
  in sync (which a custom web slider cannot do on iOS).
- Stylable track and thumb colours to match your app's accent.
- `getVolume()` and a `volumeChange` listener for reflecting system volume in your
  own UI.

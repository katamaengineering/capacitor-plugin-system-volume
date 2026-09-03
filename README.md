# capacitor-plugin-system-volume

A Capacitor plugin that overlays a native, stylable **system-volume slider**
(`MPVolumeView`) on iOS. Because it is Apple's own control, dragging it sets the
operating-system output volume and the **hardware volume buttons move it** — the
two stay in sync, which a custom `<input type="range">` cannot do on iOS
(WKWebView cannot read or set system volume).

> **iOS only.** There is no web API for OS output volume, and Android exposes it
> differently (`AudioManager`), so on those platforms use a normal styled slider
> bound to your media element's own `volume`. Every method here rejects with
> `unavailable` off iOS.

## Why

On iOS, an HTML `<audio>`/`<video>` element's `volume` is a no-op inside
WKWebView, and there is no web API to touch the system volume. The only
Apple-sanctioned control that both reflects the hardware buttons and lets the
user set volume is `MPVolumeView` — a native UIKit view. This plugin mounts that
view into the webview at the position of a placeholder element and keeps it
aligned as the page scrolls and resizes (the same compositing technique
`@capacitor/google-maps` uses for a native map).

## Install

```bash
npm install capacitor-plugin-system-volume
npx cap sync
```

## Usage

Put a placeholder element in your layout where the slider should appear. Leave it
visually empty — the native control shows through it — and give it the width and
height you want.

```html
<div id="volume" style="width: 220px; height: 28px;"></div>
```

```ts
import { VolumeSlider } from 'capacitor-plugin-system-volume';

const slider = await VolumeSlider.create({
  id: 'main',
  element: document.getElementById('volume')!,
  style: {
    minimumTrackColor: '#B4FF39',
    maximumTrackColor: '#FFFFFF33',
    thumbColor: '#FFFFFF',
    thumbRadius: 16,
  },
});

// Reflect volume elsewhere in your UI, if you like.
await slider.setOnVolumeChangeListener((value) => {
  console.log('system volume is now', value); // 0..1
});

// Later, when the view is torn down:
await slider.destroy();
```

To read the volume without mounting a slider:

```ts
import { getVolume } from 'capacitor-plugin-system-volume';
const { value } = await getVolume(); // 0..1
```

### Host-app requirement

`MPVolumeView` reflects and controls the system output volume, which requires an
**active `AVAudioSession`**. Apps that play audio already have one. A silent app
may need to activate a `.playback` (or `.ambient`) session for the slider to
track real volume.

### Notes

- **The iOS Simulator does not render `MPVolumeView`** (there is no real audio
  route) — test on a device.
- Styling is limited to track colours and a thumb image, per what `MPVolumeView`
  exposes — not arbitrary CSS.

## API

- `VolumeSlider.create({ id, element, style? })` → `Promise<VolumeSlider>`
- `slider.setStyle(style)` — restyle in place
- `slider.getVolume()` → `Promise<number>` (0..1)
- `slider.setOnVolumeChangeListener(cb?)` — `cb(value: number)` on any change
- `slider.destroy()`
- `getVolume()` → `Promise<{ value: number }>` — read without a slider

## License

MIT

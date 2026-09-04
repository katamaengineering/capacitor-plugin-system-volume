# capacitor-plugin-system-volume

[![npm version](https://img.shields.io/npm/v/capacitor-plugin-system-volume.svg)](https://www.npmjs.com/package/capacitor-plugin-system-volume)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

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

The `VolumeSlider` wrapper (`create`, `setStyle`, `getVolume`,
`setOnVolumeChangeListener`, `destroy`) and the standalone `getVolume()` export
are the everyday surface. Below is the low-level `CapacitorSystemVolumePlugin`
bridge they are built on, generated from the source JSDoc by
[`@capacitor/docgen`](https://github.com/ionic-team/capacitor-docgen) — run
`npm run docgen` to regenerate it.

<docgen-index>

* [`create(...)`](#create)
* [`createRoutePicker(...)`](#createroutepicker)
* [`destroy(...)`](#destroy)
* [`setStyle(...)`](#setstyle)
* [`setRoutePickerStyle(...)`](#setroutepickerstyle)
* [`onResize(...)`](#onresize)
* [`onDisplay(...)`](#ondisplay)
* [`onScroll(...)`](#onscroll)
* [`getVolume()`](#getvolume)
* [`addListener('volumeChange', ...)`](#addlistenervolumechange-)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

Low-level bridge interface. Most callers use the {@link VolumeSlider} wrapper,
which binds these methods to a DOM element and keeps the native frame synced.

### create(...)

```typescript
create(options: { id: string; rect: VolumeSliderRect; style?: VolumeSliderStyle; devicePixelRatio?: number; }) => Promise<void>
```

Mount a native volume slider bound to the element at `rect`.

| Param         | Type                                                                                                                                                                        |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`options`** | <code>{ id: string; rect: <a href="#volumesliderrect">VolumeSliderRect</a>; style?: <a href="#volumesliderstyle">VolumeSliderStyle</a>; devicePixelRatio?: number; }</code> |

--------------------


### createRoutePicker(...)

```typescript
createRoutePicker(options: { id: string; rect: VolumeSliderRect; style?: RoutePickerStyle; }) => Promise<void>
```

Mount a native AirPlay route button bound to the element at `rect`.

| Param         | Type                                                                                                                                           |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **`options`** | <code>{ id: string; rect: <a href="#volumesliderrect">VolumeSliderRect</a>; style?: <a href="#routepickerstyle">RoutePickerStyle</a>; }</code> |

--------------------


### destroy(...)

```typescript
destroy(options: { id: string; }) => Promise<void>
```

Tear down the overlay (slider or route button) with this `id`.

| Param         | Type                         |
| ------------- | ---------------------------- |
| **`options`** | <code>{ id: string; }</code> |

--------------------


### setStyle(...)

```typescript
setStyle(options: { id: string; style: VolumeSliderStyle; }) => Promise<void>
```

Restyle an existing slider.

| Param         | Type                                                                                    |
| ------------- | --------------------------------------------------------------------------------------- |
| **`options`** | <code>{ id: string; style: <a href="#volumesliderstyle">VolumeSliderStyle</a>; }</code> |

--------------------


### setRoutePickerStyle(...)

```typescript
setRoutePickerStyle(options: { id: string; style: RoutePickerStyle; }) => Promise<void>
```

Restyle an existing route button.

| Param         | Type                                                                                  |
| ------------- | ------------------------------------------------------------------------------------- |
| **`options`** | <code>{ id: string; style: <a href="#routepickerstyle">RoutePickerStyle</a>; }</code> |

--------------------


### onResize(...)

```typescript
onResize(options: { id: string; rect: VolumeSliderRect; }) => Promise<void>
```

| Param         | Type                                                                                 |
| ------------- | ------------------------------------------------------------------------------------ |
| **`options`** | <code>{ id: string; rect: <a href="#volumesliderrect">VolumeSliderRect</a>; }</code> |

--------------------


### onDisplay(...)

```typescript
onDisplay(options: { id: string; rect: VolumeSliderRect; }) => Promise<void>
```

| Param         | Type                                                                                 |
| ------------- | ------------------------------------------------------------------------------------ |
| **`options`** | <code>{ id: string; rect: <a href="#volumesliderrect">VolumeSliderRect</a>; }</code> |

--------------------


### onScroll(...)

```typescript
onScroll(options: { id: string; rect: VolumeSliderRect; }) => Promise<void>
```

| Param         | Type                                                                                 |
| ------------- | ------------------------------------------------------------------------------------ |
| **`options`** | <code>{ id: string; rect: <a href="#volumesliderrect">VolumeSliderRect</a>; }</code> |

--------------------


### getVolume()

```typescript
getVolume() => Promise<{ value: number; }>
```

Read the current system output volume, `0`–`1`.

**Returns:** <code>Promise&lt;{ value: number; }&gt;</code>

--------------------


### addListener('volumeChange', ...)

```typescript
addListener(eventName: 'volumeChange', listenerFunc: (data: { value: number; }) => void) => Promise<PluginListenerHandle>
```

Fires whenever the system output volume changes — the hardware buttons,
Control Center, or a drag on the native slider. Value is `0`–`1`.

| Param              | Type                                               |
| ------------------ | -------------------------------------------------- |
| **`eventName`**    | <code>'volumeChange'</code>                        |
| **`listenerFunc`** | <code>(data: { value: number; }) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### Interfaces


#### VolumeSliderRect

The rectangle a native overlay should occupy, in CSS pixels.

| Prop         | Type                |
| ------------ | ------------------- |
| **`x`**      | <code>number</code> |
| **`y`**      | <code>number</code> |
| **`width`**  | <code>number</code> |
| **`height`** | <code>number</code> |


#### VolumeSliderStyle

Appearance for the native volume slider. Colours are CSS hex strings
(`#RRGGBB` or `#RGB`). The native side renders the track and thumb from these,
so match them to your app's accent to blend the Apple control into your UI.

| Prop                    | Type                | Description                                                                         |
| ----------------------- | ------------------- | ----------------------------------------------------------------------------------- |
| **`minimumTrackColor`** | <code>string</code> | Filled portion of the track (left of the thumb). Defaults to the system tint.       |
| **`maximumTrackColor`** | <code>string</code> | Unfilled portion of the track (right of the thumb). Defaults to a translucent grey. |
| **`thumbColor`**        | <code>string</code> | The draggable thumb. Defaults to white.                                             |
| **`thumbRadius`**       | <code>number</code> | Thumb diameter in points. Defaults to `16`.                                         |


#### RoutePickerStyle

Appearance for the native AirPlay route button. Colours are CSS hex strings.

| Prop                  | Type                | Description                                                                          |
| --------------------- | ------------------- | ------------------------------------------------------------------------------------ |
| **`tintColor`**       | <code>string</code> | The AirPlay glyph when no external route is active. Defaults to the system tint.     |
| **`activeTintColor`** | <code>string</code> | The glyph when a route (AirPlay/Bluetooth) is active. Defaults to the system accent. |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |

</docgen-api>

## Maintainers

| Maintainer | GitHub                                    |
| ---------- | ----------------------------------------- |
| pjaudiomv  | [pjaudiomv](https://github.com/pjaudiomv) |

## Contributors

Thanks goes to these wonderful people
([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the
[all-contributors](https://github.com/all-contributors/all-contributors)
specification. Contributions of any kind welcome!

## License

MIT

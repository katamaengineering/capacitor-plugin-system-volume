import type { PluginListenerHandle } from '@capacitor/core';

/**
 * Appearance for the native volume slider. Colours are CSS hex strings
 * (`#RRGGBB` or `#RGB`). The native side renders the track and thumb from these,
 * so match them to your app's accent to blend the Apple control into your UI.
 */
export interface VolumeSliderStyle {
  /** Filled portion of the track (left of the thumb). Defaults to the system tint. */
  minimumTrackColor?: string;
  /** Unfilled portion of the track (right of the thumb). Defaults to a translucent grey. */
  maximumTrackColor?: string;
  /** The draggable thumb. Defaults to white. */
  thumbColor?: string;
  /** Thumb diameter in points. Defaults to `16`. */
  thumbRadius?: number;
}

/**
 * Appearance for the native AirPlay route button. Colours are CSS hex strings.
 */
export interface RoutePickerStyle {
  /** The AirPlay glyph when no external route is active. Defaults to the system tint. */
  tintColor?: string;
  /** The glyph when a route (AirPlay/Bluetooth) is active. Defaults to the system accent. */
  activeTintColor?: string;
}

/** The rectangle a native overlay should occupy, in CSS pixels. */
export interface VolumeSliderRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

/**
 * Low-level bridge interface. Most callers use the {@link VolumeSlider} wrapper,
 * which binds these methods to a DOM element and keeps the native frame synced.
 */
export interface CapacitorSystemVolumePlugin {
  /** Mount a native volume slider bound to the element at `rect`. */
  create(options: {
    id: string;
    rect: VolumeSliderRect;
    style?: VolumeSliderStyle;
    devicePixelRatio?: number;
  }): Promise<void>;

  /** Mount a native AirPlay route button bound to the element at `rect`. */
  createRoutePicker(options: { id: string; rect: VolumeSliderRect; style?: RoutePickerStyle }): Promise<void>;

  /** Tear down the overlay (slider or route button) with this `id`. */
  destroy(options: { id: string }): Promise<void>;

  /** Restyle an existing slider. */
  setStyle(options: { id: string; style: VolumeSliderStyle }): Promise<void>;

  /** Restyle an existing route button. */
  setRoutePickerStyle(options: { id: string; style: RoutePickerStyle }): Promise<void>;

  /** @internal Frame-sync hooks, driven by the {@link VolumeSlider} wrapper. */
  onResize(options: { id: string; rect: VolumeSliderRect }): Promise<void>;
  /** @internal */
  onDisplay(options: { id: string; rect: VolumeSliderRect }): Promise<void>;
  /** @internal */
  onScroll(options: { id: string; rect: VolumeSliderRect }): Promise<void>;

  /** Read the current system output volume, `0`–`1`. */
  getVolume(): Promise<{ value: number }>;

  /**
   * Fires whenever the system output volume changes — the hardware buttons,
   * Control Center, or a drag on the native slider. Value is `0`–`1`.
   */
  addListener(
    eventName: 'volumeChange',
    listenerFunc: (data: { value: number }) => void,
  ): Promise<PluginListenerHandle>;
}

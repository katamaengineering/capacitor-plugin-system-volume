import { Capacitor } from '@capacitor/core';
import type { PluginListenerHandle } from '@capacitor/core';

import type { VolumeSliderStyle } from './definitions';
import { CapacitorSystemVolume } from './implementation';

export interface CreateVolumeSliderArgs {
  /** Unique id for this slider instance. */
  id: string;
  /** The element the native slider is bound to and sized from. */
  element: HTMLElement;
  /** Appearance. Omitted fields fall back to sensible native defaults. */
  style?: VolumeSliderStyle;
}

/**
 * Placeholder element the native slider is positioned over. It only reserves
 * layout space and reports its rect — the native MPVolumeView is overlaid on top
 * of it as a webview subview (see the plugin's SystemVolume). Keep it visually
 * empty and give it the width and height you want the slider to occupy.
 */
class VolumeSliderElement extends HTMLElement {
  connectedCallback(): void {
    this.innerHTML = '';
  }
}

if (typeof customElements !== 'undefined' && !customElements.get('capacitor-volume-slider')) {
  customElements.define('capacitor-volume-slider', VolumeSliderElement);
}

/**
 * A native system-volume slider overlaid on the webview. Because it is Apple's
 * own `MPVolumeView`, dragging it sets the OS output volume and the hardware
 * volume buttons move it — the two stay in sync, which a custom web slider
 * cannot do on iOS.
 *
 * Create one with {@link VolumeSlider.create} bound to a placeholder element in
 * your layout; leave that element visually empty (the native control shows
 * through it) and give it the width and height you want the slider to take.
 */
export class VolumeSlider {
  private id: string;
  private element: HTMLElement | null = null;
  private resizeObserver: ResizeObserver | null = null;
  private handleScrollEvent = (): void => this.updateBounds();
  private onVolumeChangeListener?: PluginListenerHandle;
  private resyncTimers: ReturnType<typeof setTimeout>[] = [];

  private constructor(id: string) {
    this.id = id;
  }

  /** Re-measure the element and move the native overlay to match. */
  private syncPosition = (): void => {
    if (!this.element) return;
    const r = this.element.getBoundingClientRect();
    if (r.width === 0 && r.height === 0) return;
    void CapacitorSystemVolume.onScroll({ id: this.id, rect: VolumeSlider.rectFrom(r) });
  };

  // The rect passed to create() can be measured before layout has fully settled
  // (web fonts, dvh-sized boxes, late image reflow). Those shifts change the
  // element's POSITION but not its size, so the ResizeObserver misses them and
  // fire no scroll/resize event — the overlay would sit stale until the user
  // scrolled. Re-sync at a few beats after create so it corrects on its own.
  private scheduleResync(): void {
    requestAnimationFrame(this.syncPosition);
    for (const ms of [100, 300, 600, 1000]) {
      this.resyncTimers.push(setTimeout(this.syncPosition, ms));
    }
    window.addEventListener('load', this.syncPosition, { once: true });
    void document.fonts?.ready?.then(this.syncPosition).catch(() => undefined);
  }

  static async create(options: CreateVolumeSliderArgs): Promise<VolumeSlider> {
    if (!options.element) {
      throw new Error('container element is required');
    }
    const slider = new VolumeSlider(options.id);
    slider.element = options.element;
    slider.element.dataset.internalId = options.id;

    await VolumeSlider.settleLayout(options.element);
    const rect = VolumeSlider.rectOf(options.element);

    if (Capacitor.isNativePlatform()) {
      const lastState = { width: rect.width, height: rect.height, isHidden: false };
      slider.resizeObserver = new ResizeObserver(() => {
        if (slider.element == null) return;
        const r = slider.element.getBoundingClientRect();
        const isHidden = r.width === 0 && r.height === 0;
        if (!isHidden) {
          if (lastState.isHidden) {
            void CapacitorSystemVolume.onDisplay({ id: slider.id, rect: VolumeSlider.rectFrom(r) });
          } else if (lastState.width !== r.width || lastState.height !== r.height) {
            void CapacitorSystemVolume.onResize({ id: slider.id, rect: VolumeSlider.rectFrom(r) });
          }
        }
        lastState.width = r.width;
        lastState.height = r.height;
        lastState.isHidden = isHidden;
      });
      slider.resizeObserver.observe(slider.element);
      window.addEventListener('scroll', slider.handleScrollEvent, true);
      window.addEventListener('resize', slider.handleScrollEvent);
    }

    await CapacitorSystemVolume.create({
      id: options.id,
      rect,
      style: options.style,
      devicePixelRatio: window.devicePixelRatio,
    });

    // Correct the position after any late layout settling (see scheduleResync).
    if (Capacitor.isNativePlatform()) slider.scheduleResync();

    return slider;
  }

  /** Read the current system output volume, `0`–`1`. */
  async getVolume(): Promise<number> {
    const res = await CapacitorSystemVolume.getVolume();
    return res.value;
  }

  /** Restyle the slider in place. */
  async setStyle(style: VolumeSliderStyle): Promise<void> {
    return CapacitorSystemVolume.setStyle({ id: this.id, style });
  }

  /**
   * Observe system volume changes (hardware buttons, Control Center, or a drag
   * on this slider). Pass `undefined` to stop observing.
   */
  async setOnVolumeChangeListener(callback?: (value: number) => void): Promise<void> {
    if (this.onVolumeChangeListener) {
      await this.onVolumeChangeListener.remove();
      this.onVolumeChangeListener = undefined;
    }
    if (callback) {
      this.onVolumeChangeListener = await CapacitorSystemVolume.addListener('volumeChange', (data) =>
        callback(data.value),
      );
    }
  }

  async destroy(): Promise<void> {
    if (Capacitor.isNativePlatform()) {
      window.removeEventListener('scroll', this.handleScrollEvent, true);
      window.removeEventListener('resize', this.handleScrollEvent);
    }
    window.removeEventListener('load', this.syncPosition);
    for (const t of this.resyncTimers) clearTimeout(t);
    this.resyncTimers = [];
    this.resizeObserver?.disconnect();
    this.resizeObserver = null;
    await this.onVolumeChangeListener?.remove();
    this.onVolumeChangeListener = undefined;
    this.element = null;
    return CapacitorSystemVolume.destroy({ id: this.id });
  }

  private updateBounds(): void {
    if (!this.element) return;
    void CapacitorSystemVolume.onScroll({
      id: this.id,
      rect: VolumeSlider.rectFrom(this.element.getBoundingClientRect()),
    });
  }

  private static rectFrom(r: DOMRect): { x: number; y: number; width: number; height: number } {
    return { x: r.x, y: r.y, width: r.width, height: r.height };
  }

  private static rectOf(element: HTMLElement): { x: number; y: number; width: number; height: number } {
    return VolumeSlider.rectFrom(element.getBoundingClientRect());
  }

  private static nextFrame(): Promise<void> {
    return new Promise((resolve) => {
      if (typeof requestAnimationFrame === 'function') {
        requestAnimationFrame(() => resolve());
      } else {
        setTimeout(resolve, 16);
      }
    });
  }

  /**
   * Wait until the element's box is non-zero and unchanged across a few frames,
   * i.e. layout has settled — otherwise the native slider is placed against a
   * stale frame. Bounded so a genuinely zero-sized element resolves rather than
   * hanging.
   */
  private static async settleLayout(element: HTMLElement, maxFrames = 60): Promise<void> {
    let prev = element.getBoundingClientRect();
    let stable = 0;
    for (let i = 0; i < maxFrames; i++) {
      await VolumeSlider.nextFrame();
      const rect = element.getBoundingClientRect();
      const unchanged =
        rect.width === prev.width && rect.height === prev.height && rect.x === prev.x && rect.y === prev.y;
      if (rect.width > 0 && rect.height > 0 && unchanged) {
        if (++stable >= 3) return;
      } else {
        stable = 0;
      }
      prev = rect;
    }
  }
}

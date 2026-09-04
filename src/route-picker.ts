import { Capacitor } from '@capacitor/core';

import type { RoutePickerStyle } from './definitions';
import { CapacitorSystemVolume } from './implementation';

export interface CreateRoutePickerArgs {
  /** Unique id for this route button. */
  id: string;
  /** The element the native button is bound to and sized from. */
  element: HTMLElement;
  /** Appearance. Omitted fields fall back to the system tints. */
  style?: RoutePickerStyle;
}

/**
 * Placeholder element the native AirPlay button is positioned over. Keep it
 * visually empty and sized to the button you want (a square ~24–32px reads well).
 */
class RoutePickerElement extends HTMLElement {
  connectedCallback(): void {
    this.innerHTML = '';
  }
}

if (typeof customElements !== 'undefined' && !customElements.get('capacitor-airplay-button')) {
  customElements.define('capacitor-airplay-button', RoutePickerElement);
}

/**
 * A native AirPlay route button (`AVRoutePickerView`) overlaid on the webview.
 * Tapping it opens the system output-route picker (AirPlay, Bluetooth, etc.) —
 * Apple handles the picker, so there is nothing else to wire up.
 *
 * Overlay positioning mirrors {@link VolumeSlider}: it tracks the bound element
 * on scroll/resize and re-syncs after layout settles.
 */
export class RoutePicker {
  private id: string;
  private element: HTMLElement | null = null;
  private resizeObserver: ResizeObserver | null = null;
  private handleScrollEvent = (): void => this.syncPosition();
  private resyncTimers: ReturnType<typeof setTimeout>[] = [];

  private constructor(id: string) {
    this.id = id;
  }

  private syncPosition = (): void => {
    if (!this.element) return;
    const r = this.element.getBoundingClientRect();
    if (r.width === 0 && r.height === 0) return;
    void CapacitorSystemVolume.onScroll({ id: this.id, rect: RoutePicker.rectFrom(r) });
  };

  private scheduleResync(): void {
    requestAnimationFrame(this.syncPosition);
    for (const ms of [100, 300, 600, 1000]) {
      this.resyncTimers.push(setTimeout(this.syncPosition, ms));
    }
    window.addEventListener('load', this.syncPosition, { once: true });
    void document.fonts?.ready?.then(this.syncPosition).catch(() => undefined);
  }

  static async create(options: CreateRoutePickerArgs): Promise<RoutePicker> {
    if (!options.element) {
      throw new Error('container element is required');
    }
    const picker = new RoutePicker(options.id);
    picker.element = options.element;
    options.element.dataset.internalId = options.id;

    await RoutePicker.settleLayout(options.element);
    const rect = RoutePicker.rectFrom(options.element.getBoundingClientRect());

    if (Capacitor.isNativePlatform()) {
      picker.resizeObserver = new ResizeObserver(picker.syncPosition);
      picker.resizeObserver.observe(options.element);
      window.addEventListener('scroll', picker.handleScrollEvent, true);
      window.addEventListener('resize', picker.handleScrollEvent);
    }

    await CapacitorSystemVolume.createRoutePicker({ id: options.id, rect, style: options.style });

    if (Capacitor.isNativePlatform()) picker.scheduleResync();

    return picker;
  }

  async setStyle(style: RoutePickerStyle): Promise<void> {
    return CapacitorSystemVolume.setRoutePickerStyle({ id: this.id, style });
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
    this.element = null;
    return CapacitorSystemVolume.destroy({ id: this.id });
  }

  private static rectFrom(r: DOMRect): { x: number; y: number; width: number; height: number } {
    return { x: r.x, y: r.y, width: r.width, height: r.height };
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

  private static async settleLayout(element: HTMLElement, maxFrames = 60): Promise<void> {
    let prev = element.getBoundingClientRect();
    let stable = 0;
    for (let i = 0; i < maxFrames; i++) {
      await RoutePicker.nextFrame();
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

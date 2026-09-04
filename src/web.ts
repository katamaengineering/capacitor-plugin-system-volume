import { WebPlugin } from '@capacitor/core';

import type { CapacitorSystemVolumePlugin } from './definitions';

/**
 * Web fallback. There is no web API to read or set the operating-system output
 * volume (browsers reserve it for the user), so every method rejects with
 * `unavailable`. On the web, use a plain styled `<input type="range">` bound to
 * your media element's own `volume` instead of this plugin.
 */
export class CapacitorSystemVolumeWeb extends WebPlugin implements CapacitorSystemVolumePlugin {
  private notAvailable(): never {
    throw this.unavailable('The system volume slider is only available on iOS.');
  }

  async create(): Promise<void> {
    this.notAvailable();
  }

  async createRoutePicker(): Promise<void> {
    this.notAvailable();
  }

  async destroy(): Promise<void> {
    this.notAvailable();
  }

  async setStyle(): Promise<void> {
    this.notAvailable();
  }

  async setRoutePickerStyle(): Promise<void> {
    this.notAvailable();
  }

  async onResize(): Promise<void> {
    this.notAvailable();
  }

  async onDisplay(): Promise<void> {
    this.notAvailable();
  }

  async onScroll(): Promise<void> {
    this.notAvailable();
  }

  async getVolume(): Promise<{ value: number }> {
    this.notAvailable();
  }
}

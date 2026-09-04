import { CapacitorSystemVolume } from './implementation';

export * from './definitions';
export { CapacitorSystemVolume } from './implementation';
export { VolumeSlider } from './slider';
export type { CreateVolumeSliderArgs } from './slider';
export { RoutePicker } from './route-picker';
export type { CreateRoutePickerArgs } from './route-picker';

/**
 * Read the current system output volume, `0`–`1`, without mounting a slider.
 * Useful for reflecting volume in your own UI. iOS only.
 */
export function getVolume(): Promise<{ value: number }> {
  return CapacitorSystemVolume.getVolume();
}

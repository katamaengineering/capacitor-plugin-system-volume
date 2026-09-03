import { registerPlugin } from '@capacitor/core';

import type { CapacitorSystemVolumePlugin } from './definitions';

export const CapacitorSystemVolume = registerPlugin<CapacitorSystemVolumePlugin>('CapacitorSystemVolume', {
  web: () => import('./web').then((m) => new m.CapacitorSystemVolumeWeb()),
});

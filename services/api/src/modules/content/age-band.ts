export const ageBands = {
  '1-2': [12, 24],
  '2-3': [24, 36],
  '3-4': [36, 48],
  '4-5': [48, 60],
} as const;

export type AgeBand = keyof typeof ageBands;

export function monthsForBand(band: AgeBand): [number, number] {
  return [...ageBands[band]];
}

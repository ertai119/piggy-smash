import { loadSave, writeSave, type SaveData } from '../logic/save';

function storage(): Storage | null {
  try {
    return window.localStorage;
  } catch {
    return null;
  }
}

let current: SaveData = loadSave(storage());

export function getSave(): SaveData {
  return current;
}

export function setSave(next: SaveData): void {
  current = next;
  writeSave(storage(), next);
}

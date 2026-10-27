/// GPS oscillations and replayed notices should update a card without sounding.
bool proximityInterrupts(int? previous, int stage, {required bool promoted}) {
  if (previous == null) return !promoted && stage <= 50;
  if (stage >= previous) return false;
  return !promoted || stage <= 50;
}

int levelFromPoints(int points) {
  if (points <= 100) return 1;
  if (points <= 300) return 2;
  return 3;
}

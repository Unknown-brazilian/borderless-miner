/// Formata hashrate (H/s) de forma legível.
String formatHashrate(double hps) {
  if (hps <= 0) return '0 H/s';
  const units = ['H/s', 'kH/s', 'MH/s', 'GH/s', 'TH/s', 'PH/s'];
  var value = hps;
  var i = 0;
  while (value >= 1000 && i < units.length - 1) {
    value /= 1000;
    i++;
  }
  return '${value.toStringAsFixed(value >= 100 ? 0 : 2)} ${units[i]}';
}

/// Formata grandes dificuldades (ex.: 1.23M, 4.5G, 2.1T).
String formatDifficulty(double d) {
  if (d <= 0) return '0';
  const units = ['', 'K', 'M', 'G', 'T', 'P', 'E'];
  var value = d;
  var i = 0;
  while (value >= 1000 && i < units.length - 1) {
    value /= 1000;
    i++;
  }
  return '${value.toStringAsFixed(value >= 100 ? 0 : 2)}${units[i]}';
}

import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// Guarda o endereço de destino escolhido pelo usuário (via QR).
/// Se nada foi escolhido ainda, usa o padrão do MinerConfig.
class AddressStore {
  static const _key = 'destination_address';

  static Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved.isNotEmpty) return saved;
    return MinerConfig.bitcoinAddress;
  }

  static Future<void> save(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, address);
  }
}

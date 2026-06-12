import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings.dart';

/// Controla o idioma do app, persiste a escolha e detecta o idioma do aparelho
/// no primeiro uso. É um singleton global para facilitar o acesso às strings.
class LocaleController extends ChangeNotifier {
  static const _key = 'app_lang';
  AppLang lang = AppLang.pt;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_key);
    if (saved == 'en') {
      lang = AppLang.en;
    } else if (saved == 'pt') {
      lang = AppLang.pt;
    } else {
      // primeiro uso: segue o idioma do sistema (pt -> PT, senão EN)
      final code =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      lang = code == 'pt' ? AppLang.pt : AppLang.en;
    }
    notifyListeners();
  }

  Future<void> setLang(AppLang l) async {
    lang = l;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, l.name);
    notifyListeners();
  }

  void toggle() => setLang(lang == AppLang.pt ? AppLang.en : AppLang.pt);
}

/// Instância global do controlador de idioma.
final localeController = LocaleController();

/// Atalho para as strings do idioma atual: use `tr.startMining`, etc.
S get tr => S.of(localeController.lang);

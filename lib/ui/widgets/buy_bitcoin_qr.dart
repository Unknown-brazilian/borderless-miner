import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../l10n/l10n.dart';
import '../../theme.dart';

/// Card com QR code do link de afiliado da Binance.
/// A ideia: a pessoa escaneia com o celular DELA (de uso diário), não com o
/// celular velho que está minerando.
class BuyBitcoinQr extends StatelessWidget {
  const BuyBitcoinQr({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: AppColors.bitcoin, size: 18),
              const SizedBox(width: 8),
              Text(
                tr.buyBitcoinTitle,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Fundo branco: QR precisa de alto contraste para escanear bem.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: MinerConfig.binanceRefUrl,
              version: QrVersions.auto,
              size: 190,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF111111),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF111111),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tr.qrInstruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                      const ClipboardData(text: MinerConfig.binanceRefUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr.linkCopied)),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text(tr.copyLink),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted),
              ),
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(MinerConfig.binanceRefUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(tr.openBtn),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.bitcoin),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

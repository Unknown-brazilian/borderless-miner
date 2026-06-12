import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../config.dart';
import '../l10n/l10n.dart';
import '../mining/miner.dart';
import '../mining/stratum_client.dart';
import '../models/format.dart';
import '../services/pool_api.dart';
import '../theme.dart';
import 'scan_address_screen.dart';
import 'widgets/buy_bitcoin_qr.dart';
import 'widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Miner _miner = Miner();
  PoolStats? _poolStats;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _miner.addListener(_onUpdate);
    localeController.addListener(_onUpdate);
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => _refreshPool());
    _init();
  }

  Future<void> _init() async {
    await _miner.loadAddress();
    await _refreshPool();
  }

  void _onUpdate() => setState(() {});

  Future<void> _refreshPool() async {
    final stats = await PoolApi.fetchClient(_miner.address);
    if (mounted) setState(() => _poolStats = stats);
  }

  Future<void> _scanAddress() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanAddressScreen()),
    );
    if (result != null && result.isNotEmpty) {
      await _miner.setAddress(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.destinationUpdated)),
        );
      }
      await _refreshPool();
    }
  }

  Future<void> _toggle() async {
    if (_miner.running) {
      await WakelockPlus.disable();
      await _miner.stop();
    } else {
      await WakelockPlus.enable();
      await _miner.start();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _miner.removeListener(_onUpdate);
    localeController.removeListener(_onUpdate);
    _miner.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Color get _statusColor {
    switch (_miner.connection) {
      case StratumState.authorized:
        return AppColors.green;
      case StratumState.connected:
      case StratumState.connecting:
        return AppColors.bitcoin;
      case StratumState.disconnected:
        return AppColors.red;
    }
  }

  String get _statusLabel {
    if (!_miner.running) return tr.statusStopped;
    switch (_miner.connection) {
      case StratumState.authorized:
        return tr.statusMining;
      case StratumState.connected:
        return tr.statusConnected;
      case StratumState.connecting:
        return tr.statusConnecting;
      case StratumState.disconnected:
        return tr.statusDisconnected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.bitcoin,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('₿',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Borderless Miner',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => localeController.toggle(),
              child: Text(tr.langCode,
                  style: const TextStyle(
                      color: AppColors.bitcoin, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.bitcoin,
        onRefresh: _refreshPool,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statusBanner(),
            const SizedBox(height: 12),
            _destinationCard(),
            const SizedBox(height: 16),
            _hashrateHero(),
            const SizedBox(height: 12),
            _statGrid(),
            const SizedBox(height: 16),
            _controlButton(),
            const SizedBox(height: 24),
            _eduSection(),
            const SizedBox(height: 16),
            const BuyBitcoinQr(),
            const SizedBox(height: 24),
            _logSection(),
            const SizedBox(height: 24),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(_statusLabel,
              style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(Icons.bolt, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text('public-pool.io',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _destinationCard() {
    final isDefault = _miner.address == MinerConfig.bitcoinAddress;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDefault ? AppColors.red : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 16, color: AppColors.bitcoin),
              const SizedBox(width: 6),
              Text(tr.rewardDestination,
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _miner.address));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr.addressCopied)),
              );
            },
            child: Text(
              _miner.address,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: AppColors.textPrimary),
            ),
          ),
          if (isDefault) ...[
            const SizedBox(height: 6),
            Text(
              tr.exampleAddrWarning,
              style: const TextStyle(color: AppColors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _scanAddress,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.bitcoin,
                side: const BorderSide(color: AppColors.bitcoin),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(tr.scanDestinationBtn,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hashrateHero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surface2, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr.hashrateTitle,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(
            formatHashrate(_miner.hashrate),
            style: const TextStyle(
                color: AppColors.bitcoin,
                fontSize: 34,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            _miner.running
                ? tr.coresActive(_miner.activeThreads, _miner.coreCount)
                : tr.coresAvailable(_miner.coreCount),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Sparkline(data: _miner.hashrateHistory),
        ],
      ),
    );
  }

  Widget _statGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        StatCard(
          label: tr.bestDifficulty,
          value: formatDifficulty(_miner.bestDifficulty),
          icon: Icons.trending_up,
        ),
        StatCard(
          label: tr.acceptedShares,
          value: '${_miner.acceptedShares}',
          icon: Icons.check_circle_outline,
          accent: AppColors.green,
        ),
        StatCard(
          label: tr.blocksFound,
          value: '${_miner.blocksFound}',
          icon: Icons.emoji_events_outlined,
          accent: _miner.blocksFound > 0 ? AppColors.green : null,
        ),
        StatCard(
          label: tr.poolBestShare,
          value: _poolStats == null
              ? '—'
              : formatDifficulty(_poolStats!.bestDifficulty),
          icon: Icons.public,
        ),
      ],
    );
  }

  Widget _controlButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _toggle,
        style: ElevatedButton.styleFrom(
          backgroundColor: _miner.running ? AppColors.red : AppColors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(_miner.running ? Icons.stop : Icons.play_arrow),
        label: Text(
          _miner.running ? tr.stopMining : tr.startMining,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _eduSection() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        iconColor: AppColors.bitcoin,
        collapsedIconColor: AppColors.bitcoin,
        title: Text(tr.eduTitle,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.bitcoin)),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        children: [
          _EduItem(tr.edu1Title, tr.edu1Body),
          _EduItem(tr.edu2Title, tr.edu2Body),
          _EduItem(tr.edu3Title, tr.edu3Body),
          _EduItem(tr.edu4Title, tr.edu4Body),
        ],
      ),
    );
  }

  Widget _logSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr.logTitle,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 6),
          if (_miner.log.isEmpty)
            Text(tr.waiting,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12))
          else
            ..._miner.log.take(12).map((l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(l,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB8B8B8),
                          fontFamily: 'monospace')),
                )),
        ],
      ),
    );
  }

  Widget _footer() {
    return Center(
      child: TextButton(
        onPressed: () => launchUrl(
          Uri.parse('${MinerConfig.mempoolExplorer}${_miner.address}'),
          mode: LaunchMode.externalApplication,
        ),
        child: Text(tr.viewOnMempool,
            style: const TextStyle(color: AppColors.textMuted)),
      ),
    );
  }
}

class _EduItem extends StatelessWidget {
  final String title;
  final String body;
  const _EduItem(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(body,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

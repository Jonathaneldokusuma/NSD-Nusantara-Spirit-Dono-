import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/seed_data.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class TransparencyScreen extends StatefulWidget {
  const TransparencyScreen({required this.api, super.key});

  final ApiClient api;

  @override
  State<TransparencyScreen> createState() => _TransparencyScreenState();
}

class _TransparencyScreenState extends State<TransparencyScreen>
    with AutomaticKeepAliveClientMixin {
  PublicOverview? _overview;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final overview = PublicOverview.fromJson(
        await widget.api.get('/public/overview') as Json,
      );
      if (mounted) setState(() => _overview = overview);
    } on ApiException catch (error) {
      if (mounted) setState(() => _overview = seedOverview);
      // ignore: avoid_print
      print('Transparency API fallback: ${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_overview == null) {
      return _error == null
          ? const LoadingView()
          : EmptyState(
              icon: Icons.cloud_off,
              title: 'Data transparansi belum tersedia',
              message: _error!,
            );
    }
    final data = _overview!;
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: MaxWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                eyebrow: 'Laporan terbuka',
                title: 'Setiap rupiah dapat ditelusuri',
                description:
                    'Pantau dana masuk, penyaluran, dan bukti penggunaan dari seluruh campaign terverifikasi.',
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth >= 780
                      ? (constraints.maxWidth - 40) / 3
                      : constraints.maxWidth;
                  final cards = [
                    (
                      Icons.account_balance_wallet_outlined,
                      'Dana terkumpul',
                      formatRupiah(data.stats['totalRaised'] as num),
                      NsdColors.green,
                    ),
                    (
                      Icons.payments_outlined,
                      'Dana disalurkan',
                      formatRupiah(data.stats['totalDistributed'] as num),
                      NsdColors.gold,
                    ),
                    (
                      Icons.savings_outlined,
                      'Saldo untuk program',
                      formatRupiah(
                        (data.stats['totalRaised'] as num) -
                            (data.stats['totalDistributed'] as num),
                      ),
                      NsdColors.blue,
                    ),
                  ];
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: cards
                        .map(
                          (item) => SizedBox(
                            width: width,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: item.$4.withValues(
                                        alpha: .12,
                                      ),
                                      child: Icon(item.$1, color: item.$4),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item.$2),
                                          const SizedBox(height: 5),
                                          Text(
                                            item.$3,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktivitas donasi 14 hari',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text('Tren nilai donasi berhasil yang tercatat.'),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _DonationChart(data.dailyDonations),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 34),
              Text(
                'Penyaluran terbaru',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              ...data.disbursements.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      leading: const CircleAvatar(
                        backgroundColor: NsdColors.mint,
                        child: Icon(
                          Icons.verified_outlined,
                          color: NsdColors.green,
                        ),
                      ),
                      title: Text(
                        item.description,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${item.recipient} - ${item.date}\n${item.evidence}',
                      ),
                      trailing: Text(
                        formatRupiah(item.amount, compact: true),
                        style: const TextStyle(
                          color: NsdColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonationChart extends CustomPainter {
  const _DonationChart(this.values);

  final List<Json> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final amounts = values
        .map((item) => (item['amount'] as num).toDouble())
        .toList();
    final maxValue = amounts.reduce(math.max);
    final gridPaint = Paint()
      ..color = NsdColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final path = Path();
    for (var i = 0; i < amounts.length; i++) {
      final x = size.width * i / (amounts.length - 1);
      final y = size.height - (amounts[i] / maxValue * (size.height - 15));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = NsdColors.green
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < amounts.length; i++) {
      final x = size.width * i / (amounts.length - 1);
      final y = size.height - (amounts[i] / maxValue * (size.height - 15));
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = NsdColors.green);
    }
  }

  @override
  bool shouldRepaint(covariant _DonationChart oldDelegate) =>
      oldDelegate.values != values;
}

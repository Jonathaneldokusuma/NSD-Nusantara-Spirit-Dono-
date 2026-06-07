import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'campaign_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.api,
    required this.session,
    required this.showCampaigns,
    required this.applyForAid,
    super.key,
  });

  final ApiClient api;
  final AuthSession session;
  final VoidCallback showCampaigns;
  final VoidCallback applyForAid;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  PublicOverview? _overview;
  String? _error;
  io.Socket? _socket;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    _socket = io.io(
      ApiClient.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    )..connect();
    _socket!.on('campaign.updated', (_) => _load());
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final value = PublicOverview.fromJson(
        await widget.api.get('/public/overview') as Json,
      );
      if (mounted) setState(() => _overview = value);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  void _openCampaign(Campaign campaign) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CampaignDetailScreen(
          api: widget.api,
          session: widget.session,
          campaignId: campaign.slug,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_overview == null && _error == null) return const LoadingView();
    if (_overview == null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Data belum dapat dimuat',
        message: _error!,
      );
    }

    final overview = _overview!;
    final urgent = overview.campaigns
        .where((campaign) => campaign.status == 'darurat')
        .firstOrNull;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8F5ED), Color(0xFFE7F3EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: MaxWidth(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final desktop = constraints.maxWidth >= 850;
                    final heroCopy = _HeroCopy(
                      showCampaigns: widget.showCampaigns,
                      applyForAid: widget.applyForAid,
                    );
                    final urgentCard = urgent == null
                        ? const SizedBox.shrink()
                        : _UrgentCard(
                            campaign: urgent,
                            onTap: () => _openCampaign(urgent),
                          );
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: desktop ? 72 : 42,
                      ),
                      child: desktop
                          ? Row(
                              children: [
                                Expanded(child: heroCopy),
                                const SizedBox(width: 55),
                                SizedBox(width: 410, child: urgentCard),
                              ],
                            )
                          : Column(
                              children: [
                                heroCopy,
                                const SizedBox(height: 34),
                                urgentCard,
                              ],
                            ),
                    );
                  },
                ),
              ),
            ),
            Container(
              color: NsdColors.ink,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: MaxWidth(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final items = [
                      (
                        Icons.account_balance_wallet_outlined,
                        formatRupiah(
                          overview.stats['totalRaised'] as num,
                          compact: true,
                        ),
                        'Dana terkumpul',
                      ),
                      (
                        Icons.people_outline,
                        '${overview.stats['donors']}',
                        'Donatur bergerak',
                      ),
                      (
                        Icons.campaign_outlined,
                        '${overview.stats['activeCampaigns']}',
                        'Campaign aktif',
                      ),
                      (
                        Icons.verified_outlined,
                        formatRupiah(
                          overview.stats['totalDistributed'] as num,
                          compact: true,
                        ),
                        'Sudah disalurkan',
                      ),
                    ];
                    return Wrap(
                      spacing: 22,
                      runSpacing: 22,
                      alignment: WrapAlignment.spaceBetween,
                      children: items
                          .map(
                            (item) => SizedBox(
                              width: constraints.maxWidth >= 700
                                  ? (constraints.maxWidth - 70) / 4
                                  : (constraints.maxWidth - 24) / 2,
                              child: Row(
                                children: [
                                  Icon(item.$1, color: const Color(0xFF8CCDBB)),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.$2,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        item.$3,
                                        style: const TextStyle(
                                          color: Color(0xFFB9CBC5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 70),
              child: MaxWidth(
                child: Column(
                  children: [
                    SectionTitle(
                      eyebrow: 'Campaign terverifikasi',
                      title: 'Kepedulian Anda dibutuhkan hari ini',
                      description:
                          'Setiap campaign melewati pemeriksaan dokumen, komunikasi konselor, dan persetujuan pengelola.',
                      trailing: MediaQuery.sizeOf(context).width > 680
                          ? TextButton.icon(
                              onPressed: widget.showCampaigns,
                              label: const Text('Lihat semua'),
                              icon: const Icon(Icons.arrow_forward, size: 18),
                            )
                          : null,
                    ),
                    const SizedBox(height: 30),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900
                            ? 3
                            : constraints.maxWidth >= 580
                            ? 2
                            : 1;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 20) /
                            columns;
                        return Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: overview.campaigns
                              .take(3)
                              .map(
                                (campaign) => SizedBox(
                                  width: width,
                                  height: 425,
                                  child: CampaignCard(
                                    campaign: campaign,
                                    onTap: () => _openCampaign(campaign),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: NsdColors.cream,
              padding: const EdgeInsets.symmetric(vertical: 68),
              child: MaxWidth(
                child: Column(
                  children: [
                    const SectionTitle(
                      eyebrow: 'Cara kerja',
                      title: 'Bantuan yang aman dan manusiawi',
                      description:
                          'NSD menggabungkan verifikasi digital, pendampingan konselor, dan laporan penyaluran terbuka.',
                    ),
                    const SizedBox(height: 28),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth >= 760
                            ? (constraints.maxWidth - 40) / 3
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children:
                              const [
                                    (
                                      Icons.fact_check_outlined,
                                      'Verifikasi berlapis',
                                      'Identitas, dokumen, dan kebutuhan diperiksa sebelum dipublikasikan.',
                                    ),
                                    (
                                      Icons.forum_outlined,
                                      'Pendampingan konselor',
                                      'Pemohon memperoleh ruang aman untuk bercerita dan didampingi.',
                                    ),
                                    (
                                      Icons.insights_outlined,
                                      'Transparansi dana',
                                      'Donatur dapat melihat pengumpulan dan penyaluran secara terbuka.',
                                    ),
                                  ]
                                  .map(
                                    (item) => SizedBox(
                                      width: width,
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: NsdColors.mint,
                                                child: Icon(
                                                  item.$1,
                                                  color: NsdColors.green,
                                                ),
                                              ),
                                              const SizedBox(height: 18),
                                              Text(
                                                item.$2,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleLarge,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(item.$3),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.showCampaigns, required this.applyForAid});

  final VoidCallback showCampaigns;
  final VoidCallback applyForAid;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .78),
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 15, color: NsdColors.gold),
              SizedBox(width: 7),
              Text(
                'Gerakan bantuan terverifikasi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Bantuan cepat.\nDampak yang terlihat.',
          style: mobile
              ? Theme.of(context).textTheme.headlineLarge
              : Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 20),
        Text(
          'Hubungkan kepedulian dengan kebutuhan nyata melalui campaign terverifikasi, penyaluran transparan, dan pendampingan manusiawi.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: showCampaigns,
              label: const Text('Lihat Campaign'),
              icon: const Icon(Icons.arrow_forward, size: 18),
            ),
            OutlinedButton(
              onPressed: applyForAid,
              child: const Text('Ajukan Bantuan'),
            ),
          ],
        ),
        const SizedBox(height: 25),
        const Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _TrustItem(Icons.verified_user_outlined, 'Verifikasi berlapis'),
            _TrustItem(Icons.shield_outlined, 'Transparansi real-time'),
          ],
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: NsdColors.green),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _UrgentCard extends StatelessWidget {
  const _UrgentCard({required this.campaign, required this.onTap});

  final Campaign campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Container(
          height: 155,
          color: hexColor(campaign.accent),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.volunteer_activism_outlined,
                size: 92,
                color: Colors.white.withValues(alpha: .9),
              ),
              Positioned(
                left: 18,
                top: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'BUTUH BANTUAN SEGERA',
                    style: TextStyle(
                      color: NsdColors.coral,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                campaign.location.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: NsdColors.green,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                campaign.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                campaign.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 17),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatRupiah(campaign.raised, compact: true),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text('${(campaign.progress * 100).round()}%'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: campaign.progress,
                minHeight: 8,
                color: hexColor(campaign.accent),
                backgroundColor: NsdColors.mint,
                borderRadius: BorderRadius.circular(9),
              ),
              const SizedBox(height: 17),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(backgroundColor: NsdColors.ink),
                  child: const Text('Bantu Sekarang'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

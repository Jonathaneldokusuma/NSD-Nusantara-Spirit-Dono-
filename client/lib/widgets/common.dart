import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';

class NsdLogo extends StatelessWidget {
  const NsdLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: NsdColors.primary,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.volunteer_activism, color: Colors.white),
        ),
        if (!compact) ...[
          const SizedBox(width: 11),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NSD',
                style: TextStyle(
                  color: NsdColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  height: 1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Nusantara Spiritual Donation',
                style: TextStyle(
                  color: Color(0xFF73827D),
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class MaxWidth extends StatelessWidget {
  const MaxWidth({required this.child, super.key, this.width = 1180});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
        ),
        child: child,
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.eyebrow,
    required this.title,
    super.key,
    this.description,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                color: NsdColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            if (description != null) ...[
              const SizedBox(height: 9),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Text(
                  description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'darurat' || 'ditolak' || 'gagal' => NsdColors.coral,
      'aktif' || 'sukses' || 'disetujui' || 'dipublikasikan' => NsdColors.green,
      'pending' || 'verifikasi' || 'diajukan' || 'konseling' => NsdColors.gold,
      _ => NsdColors.blue,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CampaignCard extends StatelessWidget {
  const CampaignCard({required this.campaign, required this.onTap, super.key});

  final Campaign campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  hexColor(campaign.accent),
                  hexColor(campaign.accent).withValues(alpha: .68),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -25,
                  top: -25,
                  child: Icon(
                    Icons.volunteer_activism_outlined,
                    size: 155,
                    color: Colors.white.withValues(alpha: .15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusPill(campaign.status),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            campaign.location,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    campaign.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatRupiah(campaign.raised, compact: true),
                        style: const TextStyle(
                          color: NsdColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text('${(campaign.progress * 100).round()}%'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: LinearProgressIndicator(
                      value: campaign.progress,
                      minHeight: 8,
                      color: hexColor(campaign.accent),
                      backgroundColor: NsdColors.mint,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${campaign.donorCount} donatur'),
                      Text('${campaign.daysLeft} hari lagi'),
                    ],
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

Color hexColor(String value) {
  final normalized = value.replaceFirst('#', '');
  return Color(int.parse('FF$normalized', radix: 16));
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Memuat data NSD...'});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          Text(label),
        ],
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: NsdColors.green),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? NsdColors.coral : NsdColors.ink,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

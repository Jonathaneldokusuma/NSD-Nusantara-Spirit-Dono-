import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/seed_data.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';

class CampaignDetailScreen extends StatefulWidget {
  const CampaignDetailScreen({
    required this.api,
    required this.session,
    required this.campaignId,
    super.key,
  });

  final ApiClient api;
  final AuthSession session;
  final String campaignId;

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  Campaign? _campaign;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final campaign = Campaign.fromJson(
        await widget.api.get('/campaigns/${widget.campaignId}') as Json,
      );
      if (mounted) setState(() => _campaign = campaign);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _campaign = seedOverview.campaigns.first;
          _error = null;
        });
      }
      // ignore: avoid_print
      print('Campaign detail API fallback: ${error.message}');
    }
  }

  Future<void> _donate() async {
    if (!widget.session.isAuthenticated) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen(session: widget.session)),
      );
      if (!widget.session.isAuthenticated || !mounted) return;
    }
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DonationDialog(api: widget.api, campaign: _campaign!),
    );
    if (completed == true) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const NsdLogo(),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: NsdColors.border),
      ),
    ),
    body: _campaign == null
        ? _error == null
              ? const LoadingView()
              : EmptyState(
                  icon: Icons.error_outline,
                  title: 'Campaign tidak ditemukan',
                  message: _error!,
                )
        : RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _CampaignHero(campaign: _campaign!),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: MaxWidth(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final desktop = constraints.maxWidth >= 820;
                          final content = _CampaignContent(
                            campaign: _campaign!,
                          );
                          final donation = _DonationSummary(
                            campaign: _campaign!,
                            onDonate: _donate,
                          );
                          return desktop
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: content),
                                    const SizedBox(width: 32),
                                    SizedBox(width: 360, child: donation),
                                  ],
                                )
                              : Column(
                                  children: [
                                    donation,
                                    const SizedBox(height: 28),
                                    content,
                                  ],
                                );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}

class _CampaignHero extends StatelessWidget {
  const _CampaignHero({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 54),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          hexColor(campaign.accent),
          hexColor(campaign.accent).withValues(alpha: .75),
        ],
      ),
    ),
    child: MaxWidth(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(campaign.status),
                    const SizedBox(width: 10),
                    if (campaign.verified)
                      const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 18),
                          SizedBox(width: 5),
                          Text(
                            'Terverifikasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  campaign.title,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      campaign.location,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      campaign.category,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 760)
            Icon(
              Icons.volunteer_activism_outlined,
              size: 150,
              color: Colors.white.withValues(alpha: .2),
            ),
        ],
      ),
    ),
  );
}

class _DonationSummary extends StatelessWidget {
  const _DonationSummary({required this.campaign, required this.onDonate});

  final Campaign campaign;
  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatRupiah(campaign.raised),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text('terkumpul dari ${formatRupiah(campaign.target)}'),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: campaign.progress,
            minHeight: 11,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: NsdColors.mint,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat('${campaign.donorCount}', 'Donatur'),
              _MiniStat('${(campaign.progress * 100).round()}%', 'Tercapai'),
              _MiniStat('${campaign.daysLeft}', 'Hari lagi'),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onDonate,
              icon: const Icon(Icons.favorite),
              label: const Text('Donasi Sekarang'),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 15, color: NsdColors.green),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pembayaran aman dan tercatat transparan.',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: NsdColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}

class _CampaignContent extends StatelessWidget {
  const _CampaignContent({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Tentang campaign',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 16),
      Text(campaign.description, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 34),
      Text('Laporan penyaluran', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6),
      Text(
        '${formatRupiah(campaign.distributed)} telah disalurkan dari ${formatRupiah(campaign.raised)}.',
      ),
      const SizedBox(height: 18),
      if (campaign.disbursements.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Belum ada laporan penyaluran untuk campaign ini.'),
          ),
        )
      else
        ...campaign.disbursements.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(18),
                leading: const CircleAvatar(
                  backgroundColor: NsdColors.mint,
                  child: Icon(Icons.receipt_long, color: NsdColors.green),
                ),
                title: Text(
                  item.description,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${item.recipient}\n${item.date} - ${item.evidence}',
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
      if (campaign.recentDonations.isNotEmpty) ...[
        const SizedBox(height: 25),
        Text('Donasi terbaru', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        ...campaign.recentDonations
            .take(5)
            .map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.favorite_outline),
                ),
                title: Text(item['donorName'] as String),
                subtitle: Text(item['message'] as String? ?? ''),
                trailing: Text(
                  formatRupiah(item['amount'] as num),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
      ],
    ],
  );
}

class DonationDialog extends StatefulWidget {
  const DonationDialog({required this.api, required this.campaign, super.key});

  final ApiClient api;
  final Campaign campaign;

  @override
  State<DonationDialog> createState() => _DonationDialogState();
}

class _DonationDialogState extends State<DonationDialog> {
  final _customAmount = TextEditingController();
  final _message = TextEditingController();
  int _amount = 100000;
  String _method = 'qris';
  bool _anonymous = false;
  bool _loading = false;
  Donation? _donation;
  int _step = 0;

  @override
  void dispose() {
    _customAmount.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _createDonation() async {
    final custom = int.tryParse(
      _customAmount.text.replaceAll(RegExp(r'\D'), ''),
    );
    if (custom != null) _amount = custom;
    if (_amount < 10000) {
      showMessage(context, 'Nominal minimal Rp10.000.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final response =
          await widget.api.post('/donations', {
                'campaignId': widget.campaign.id,
                'amount': _amount,
                'method': _method,
                'anonymous': _anonymous,
                'message': _message.text,
              })
              as Json;
      setState(() {
        _donation = Donation.fromJson(response);
        _step = 1;
      });
    } on ApiException catch (error) {
      if (mounted) showMessage(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await widget.api.post('/donations/${_donation!.id}/confirm');
      setState(() => _step = 2);
    } on ApiException catch (error) {
      if (mounted) showMessage(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(18),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: switch (_step) {
          0 => _buildForm(),
          1 => _buildPayment(),
          _ => _buildSuccess(),
        },
      ),
    ),
  );

  Widget _header(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const NsdLogo(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 6),
      Text(subtitle),
      const SizedBox(height: 22),
    ],
  );

  Widget _buildForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header('Buat donasi', widget.campaign.title),
      const Text(
        'Pilih nominal',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [50000, 100000, 250000, 500000]
            .map(
              (amount) => ChoiceChip(
                label: Text(formatRupiah(amount)),
                selected: _amount == amount && _customAmount.text.isEmpty,
                onSelected: (_) => setState(() {
                  _amount = amount;
                  _customAmount.clear();
                }),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _customAmount,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Nominal lainnya',
          prefixText: 'Rp ',
        ),
      ),
      const SizedBox(height: 17),
      const Text(
        'Metode pembayaran',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        initialValue: _method,
        items: const [
          DropdownMenuItem(value: 'qris', child: Text('QRIS')),
          DropdownMenuItem(value: 'va_bca', child: Text('Virtual Account BCA')),
          DropdownMenuItem(value: 'va_bni', child: Text('Virtual Account BNI')),
          DropdownMenuItem(
            value: 'va_mandiri',
            child: Text('Virtual Account Mandiri'),
          ),
        ],
        onChanged: (value) => setState(() => _method = value!),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _message,
        maxLength: 300,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Pesan atau doa (opsional)',
        ),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _anonymous,
        onChanged: (value) => setState(() => _anonymous = value),
        title: const Text('Sembunyikan nama saya'),
      ),
      const SizedBox(height: 10),
      FilledButton(
        onPressed: _loading ? null : _createDonation,
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Lanjutkan Pembayaran'),
      ),
    ],
  );

  Widget _buildPayment() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header('Selesaikan pembayaran', _donation!.orderId),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: NsdColors.cream,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              _method == 'qris' ? Icons.qr_code_2 : Icons.account_balance,
              size: 110,
              color: NsdColors.ink,
            ),
            const SizedBox(height: 10),
            Text(
              _donation!.paymentCode,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              formatRupiah(_donation!.amount),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'Mode demo: tombol di bawah mensimulasikan callback pembayaran berhasil.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: _loading ? null : _confirm,
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Simulasikan Pembayaran Berhasil'),
      ),
    ],
  );

  Widget _buildSuccess() => Column(
    children: [
      const SizedBox(height: 12),
      const CircleAvatar(
        radius: 42,
        backgroundColor: NsdColors.mint,
        child: Icon(Icons.check, size: 46, color: NsdColors.green),
      ),
      const SizedBox(height: 20),
      Text('Terima kasih!', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text(
        'Donasi ${formatRupiah(_donation!.amount)} telah dikonfirmasi dan tercatat pada campaign.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Selesai'),
        ),
      ),
    ],
  );
}

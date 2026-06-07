import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'campaign_detail_screen.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({required this.api, required this.session, super.key});

  final ApiClient api;
  final AuthSession session;

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  List<Campaign> _campaigns = [];
  String _category = 'Semua';
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await widget.api.get('/campaigns') as List<dynamic>;
      if (mounted) {
        setState(() {
          _campaigns = response
              .map((item) => Campaign.fromJson(item as Json))
              .toList();
          _loading = false;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final categories = [
      'Semua',
      ...{for (final campaign in _campaigns) campaign.category},
    ];
    final query = _search.text.toLowerCase();
    final filtered = _campaigns.where((campaign) {
      final categoryMatch =
          _category == 'Semua' || campaign.category == _category;
      final searchMatch =
          query.isEmpty ||
          '${campaign.title} ${campaign.summary} ${campaign.location}'
              .toLowerCase()
              .contains(query);
      return categoryMatch && searchMatch;
    }).toList();

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
                eyebrow: 'Temukan gerakan kebaikan',
                title: 'Campaign bantuan terverifikasi',
                description:
                    'Pilih kebutuhan yang dekat dengan hati Anda. Setiap rupiah tercatat dan dilaporkan.',
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Cari campaign, lokasi, atau kategori...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories
                      .map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: _category == category,
                            onSelected: (_) =>
                                setState(() => _category = category),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 28),
              if (_loading)
                const LoadingView()
              else if (_error != null)
                EmptyState(
                  icon: Icons.cloud_off,
                  title: 'Gagal memuat campaign',
                  message: _error!,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 580
                        ? 2
                        : 1;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 20) / columns;
                    return Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: filtered
                          .map(
                            (campaign) => SizedBox(
                              width: width,
                              height: 425,
                              child: CampaignCard(
                                campaign: campaign,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CampaignDetailScreen(
                                      api: widget.api,
                                      session: widget.session,
                                      campaignId: campaign.slug,
                                    ),
                                  ),
                                ).then((_) => _load()),
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
    );
  }
}

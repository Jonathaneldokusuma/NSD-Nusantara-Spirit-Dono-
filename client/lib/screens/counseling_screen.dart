import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/seed_data.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class CounselingScreen extends StatefulWidget {
  const CounselingScreen({required this.api, required this.session, super.key});

  final ApiClient api;
  final AuthSession session;

  @override
  State<CounselingScreen> createState() => _CounselingScreenState();
}

class _CounselingScreenState extends State<CounselingScreen> {
  List<User> _counselors = [];
  List<CounselingSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final counselors = (await widget.api.get('/counselors') as List<dynamic>)
          .map((item) => User.fromJson(item as Json))
          .toList();
      final sessions = widget.session.isAuthenticated
          ? (await widget.api.get('/sessions') as List<dynamic>)
              .map((item) => CounselingSession.fromJson(item as Json))
              .toList()
          : <CounselingSession>[];
      if (mounted) {
        setState(() {
          _counselors = counselors;
          _sessions = sessions;
          _loading = false;
        });
      }
    } on ApiException {
      if (mounted) {
        setState(() {
          _counselors = seedCounselors;
          _sessions = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: MaxWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                eyebrow: 'Konseling aman',
                title: 'Ruang curhat dan pendampingan',
                description:
                    'Pilih konselor yang cocok, lalu lanjutkan percakapan dengan aman dan terarah.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _counselors
                    .map(
                      (c) => SizedBox(
                        width: 300,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  backgroundColor: NsdColors.blush,
                                  child: Icon(Icons.favorite, color: NsdColors.primary),
                                ),
                                const SizedBox(height: 14),
                                Text(c.name, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 6),
                                Text(c.specialization ?? 'Konselor pendamping'),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('Mulai chat'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),
              Text('Sesi aktif', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              ..._sessions.map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      title: Text(session.topic),
                      subtitle: Text('${session.user.name} • ${session.counselor.name}'),
                      trailing: StatusPill(session.status),
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

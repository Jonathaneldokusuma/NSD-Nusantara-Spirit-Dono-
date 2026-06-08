import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.api, required this.session, super.key});

  final ApiClient api;
  final AuthSession session;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _loading = true;
  String? _error;
  PublicOverview? _overview;
  List<Donation> _donations = [];
  List<AidApplication> _applications = [];
  List<CounselingSession> _sessions = [];
  List<User> _counselors = [];
  List<User> _users = [];
  List<Json> _notifications = [];
  Json? _adminOverview;
  io.Socket? _socket;

  User get user => widget.session.user!;
  bool get _isInternalAdmin =>
      ['operator', 'admin', 'super_admin'].contains(user.role);
  bool get _isCounselor => user.role == 'konselor';
  bool get _canReviewApplications => _isInternalAdmin || _isCounselor;

  List<_NavItem> get _navigation {
    final items = <_NavItem>[
      const _NavItem('Ringkasan', Icons.dashboard_outlined, 'summary'),
    ];
    if (['donatur', 'pemohon'].contains(user.role)) {
      items.add(
        const _NavItem(
          'Riwayat Donasi',
          Icons.receipt_long_outlined,
          'donations',
        ),
      );
    }
    items.add(
      const _NavItem(
        'Pengajuan Bantuan',
        Icons.fact_check_outlined,
        'applications',
      ),
    );
    if (['donatur', 'pemohon', 'konselor'].contains(user.role)) {
      items.add(
        const _NavItem('Ruang Konseling', Icons.forum_outlined, 'sessions'),
      );
    }
    if (_isInternalAdmin) {
      items.add(
        const _NavItem('Kelola Campaign', Icons.campaign_outlined, 'campaigns'),
      );
      items.add(
        const _NavItem('Audit Aktivitas', Icons.security_outlined, 'audit'),
      );
    }
    if (['admin', 'super_admin'].contains(user.role)) {
      items.add(const _NavItem('Pengguna', Icons.people_outline, 'users'));
    }
    items.addAll(const [
      _NavItem('Notifikasi', Icons.notifications_outlined, 'notifications'),
      _NavItem('Profil & Keamanan', Icons.settings_outlined, 'profile'),
    ]);
    return items;
  }

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
    for (final event in [
      'campaign.updated',
      'application.updated',
      'session.updated',
      'chat.message',
    ]) {
      _socket!.on(event, (_) => _load(silent: true));
    }
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final overview = PublicOverview.fromJson(
        await widget.api.get('/public/overview') as Json,
      );
      final notifications =
          (await widget.api.get('/notifications') as List<dynamic>)
              .cast<Json>();
      List<Donation> donations = [];
      List<AidApplication> applications = [];
      List<CounselingSession> sessions = [];
      List<User> counselors = [];
      List<User> users = [];
      Json? adminOverview;

      if (['donatur', 'pemohon'].contains(user.role)) {
        donations = (await widget.api.get('/donations/mine') as List<dynamic>)
            .map((item) => Donation.fromJson(item as Json))
            .toList();
        applications =
            (await widget.api.get('/applications/mine') as List<dynamic>)
                .map((item) => AidApplication.fromJson(item as Json))
                .toList();
      } else if (_canReviewApplications) {
        applications = (await widget.api.get('/applications') as List<dynamic>)
            .map((item) => AidApplication.fromJson(item as Json))
            .toList();
      }
      if (['donatur', 'pemohon', 'konselor'].contains(user.role)) {
        sessions = (await widget.api.get('/sessions') as List<dynamic>)
            .map((item) => CounselingSession.fromJson(item as Json))
            .toList();
      }
      if (_isInternalAdmin || ['donatur', 'pemohon'].contains(user.role)) {
        counselors = (await widget.api.get('/counselors') as List<dynamic>)
            .map((item) => User.fromJson(item as Json))
            .toList();
      }
      if (_isInternalAdmin) {
        adminOverview = await widget.api.get('/admin/overview') as Json;
      }
      if (['admin', 'super_admin'].contains(user.role)) {
        users = (await widget.api.get('/admin/users') as List<dynamic>)
            .map((item) => User.fromJson(item as Json))
            .toList();
      }
      if (mounted) {
        setState(() {
          _overview = overview;
          _notifications = notifications;
          _donations = donations;
          _applications = applications;
          _sessions = sessions;
          _counselors = counselors;
          _users = users;
          _adminOverview = adminOverview;
          _loading = false;
          _error = null;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await widget.session.logout();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 920;
    final navigation = _navigation;
    if (_selectedIndex >= navigation.length) _selectedIndex = 0;
    final current = navigation[_selectedIndex];
    final content = _loading
        ? const LoadingView()
        : _error != null
        ? EmptyState(
            icon: Icons.cloud_off,
            title: 'Dashboard belum dapat dimuat',
            message: _error!,
          )
        : _buildView(current.key);

    return Scaffold(
      drawer: desktop
          ? null
          : Drawer(child: _sidebar(navigation, mobile: true)),
      body: Row(
        children: [
          if (desktop)
            SizedBox(width: 270, child: _sidebar(navigation, mobile: false)),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                leading: desktop
                    ? null
                    : Builder(
                        builder: (context) => IconButton(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu),
                        ),
                      ),
                automaticallyImplyLeading: false,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${roleLabel(user.role)} - ${user.name}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Muat ulang',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(height: 1, color: NsdColors.border),
                ),
              ),
              body: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(desktop ? 30 : 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 500),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebar(
    List<_NavItem> navigation, {
    required bool mobile,
  }) => Container(
    color: NsdColors.ink,
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                const NsdLogo(compact: true),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NSD Workspace',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Nusantara Spiritual Donation',
                        style: TextStyle(color: Color(0xFFA9BBB5), fontSize: 9),
                      ),
                    ],
                  ),
                ),
                if (mobile)
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2B4A42), height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              itemCount: navigation.length,
              itemBuilder: (context, index) {
                final item = navigation[index];
                final selected = index == _selectedIndex;
                final unread =
                    item.key == 'notifications' &&
                    _notifications.any((item) => item['read'] == false);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: ListTile(
                    selected: selected,
                    selectedTileColor: const Color(0xFF2B574B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      item.icon,
                      color: selected ? Colors.white : const Color(0xFFA9BBB5),
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFFD3DEDA),
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: unread
                        ? const CircleAvatar(
                            radius: 4,
                            backgroundColor: NsdColors.coral,
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      if (mobile) Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF223F38),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: NsdColors.green,
                    child: Text(
                      user.name[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          roleLabel(user.role),
                          style: const TextStyle(
                            color: Color(0xFFA9BBB5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Keluar',
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Color(0xFFD3DEDA)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildView(String key) => switch (key) {
    'donations' => _donationsView(),
    'applications' => _applicationsView(),
    'sessions' => _sessionsView(),
    'campaigns' => _campaignsView(),
    'audit' => _auditView(),
    'users' => _usersView(),
    'notifications' => _notificationsView(),
    'profile' => _profileView(),
    _ => _summaryView(),
  };

  Widget _summaryView() {
    final stats = _overview!.stats;
    final managementTotals = _adminOverview?['totals'] as Json?;
    final cards = _isInternalAdmin
        ? [
            (
              'Total pengguna',
              '${managementTotals?['users'] ?? 0}',
              Icons.people_outline,
              NsdColors.blue,
            ),
            (
              'Total campaign',
              '${managementTotals?['campaigns'] ?? 0}',
              Icons.campaign_outlined,
              NsdColors.green,
            ),
            (
              'Pengajuan diproses',
              '${managementTotals?['pendingApplications'] ?? 0}',
              Icons.fact_check_outlined,
              NsdColors.gold,
            ),
            (
              'Dana berhasil',
              formatRupiah(
                managementTotals?['successfulAmount'] as num? ?? 0,
                compact: true,
              ),
              Icons.payments_outlined,
              NsdColors.coral,
            ),
          ]
        : _isCounselor
        ? [
            (
              'Pengajuan ditugaskan',
              '${_applications.length}',
              Icons.fact_check_outlined,
              NsdColors.green,
            ),
            (
              'Perlu tindak lanjut',
              '${_applications.where((item) => ['diajukan', 'konseling'].contains(item.status)).length}',
              Icons.assignment_late_outlined,
              NsdColors.gold,
            ),
            (
              'Direkomendasikan',
              '${_applications.where((item) => item.status == 'direkomendasikan').length}',
              Icons.verified_outlined,
              NsdColors.blue,
            ),
            (
              'Sesi aktif',
              '${_sessions.where((item) => item.status != 'selesai').length}',
              Icons.forum_outlined,
              NsdColors.coral,
            ),
          ]
        : [
            (
              'Dana terkumpul',
              formatRupiah(stats['totalRaised'] as num, compact: true),
              Icons.savings_outlined,
              NsdColors.green,
            ),
            (
              'Campaign aktif',
              '${stats['activeCampaigns']}',
              Icons.campaign_outlined,
              NsdColors.blue,
            ),
            (
              'Donatur',
              '${stats['donors']}',
              Icons.people_outline,
              NsdColors.gold,
            ),
            (
              'Donasi saya',
              formatRupiah(
                _donations
                    .where((item) => item.status == 'sukses')
                    .fold<int>(0, (sum, item) => sum + item.amount),
                compact: true,
              ),
              Icons.favorite_outline,
              NsdColors.coral,
            ),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, ${user.name.split(' ').first}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          _isInternalAdmin
              ? 'Berikut ringkasan operasional NSD hari ini.'
              : _isCounselor
              ? 'Berikut antrean pendampingan yang ditugaskan ke akun Anda.'
              : 'Terima kasih sudah menjadi bagian dari gerakan bantuan NSD.',
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: cards
                  .map(
                    (item) => SizedBox(
                      width: width,
                      child: _MetricCard(
                        label: item.$1,
                        value: item.$2,
                        icon: item.$3,
                        color: item.$4,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 26),
        LayoutBuilder(
          builder: (context, constraints) {
            final campaignList = Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campaign utama',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    ..._overview!.campaigns
                        .take(4)
                        .map(
                          (campaign) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: hexColor(
                                campaign.accent,
                              ).withValues(alpha: .13),
                              child: Icon(
                                Icons.volunteer_activism,
                                color: hexColor(campaign.accent),
                              ),
                            ),
                            title: Text(
                              campaign.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: LinearProgressIndicator(
                              value: campaign.progress,
                              minHeight: 5,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            trailing: Text(
                              '${(campaign.progress * 100).round()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            );
            final activity = Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isInternalAdmin
                          ? 'Aktivitas terbaru'
                          : 'Notifikasi terbaru',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (_isInternalAdmin)
                      ...((_adminOverview?['recentAudit'] as List<dynamic>? ??
                              [])
                          .take(5)
                          .cast<Json>()
                          .map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.shield_outlined,
                                color: NsdColors.green,
                              ),
                              title: Text(item['action'] as String),
                              subtitle: Text(
                                item['detail'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ))
                    else
                      ..._notifications
                          .take(5)
                          .map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                item['read'] == true
                                    ? Icons.notifications_none
                                    : Icons.notifications_active_outlined,
                                color: NsdColors.green,
                              ),
                              title: Text(item['title'] as String),
                              subtitle: Text(
                                item['message'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            );
            if (constraints.maxWidth >= 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: campaignList),
                  const SizedBox(width: 18),
                  Expanded(child: activity),
                ],
              );
            }
            return Column(
              children: [campaignList, const SizedBox(height: 18), activity],
            );
          },
        ),
      ],
    );
  }

  Widget _donationsView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _viewHeader(
        'Riwayat donasi',
        'Semua dukungan yang pernah dilakukan melalui akun ini.',
      ),
      const SizedBox(height: 22),
      if (_donations.isEmpty)
        const EmptyState(
          icon: Icons.favorite_outline,
          title: 'Belum ada donasi',
          message: 'Donasi Anda nantinya akan tampil di sini.',
        )
      else
        ..._donations.map(
          (donation) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(18),
                leading: const CircleAvatar(
                  backgroundColor: NsdColors.mint,
                  child: Icon(Icons.favorite, color: NsdColors.green),
                ),
                title: Text(
                  donation.campaign?.title ?? donation.orderId,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${donation.orderId}\n${statusLabel(donation.method)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatRupiah(donation.amount),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    StatusPill(donation.status),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _applicationsView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _viewHeader(
        'Pengajuan bantuan',
        _canReviewApplications
            ? 'Verifikasi kebutuhan, tugaskan konselor, dan kelola persetujuan.'
            : 'Ajukan kebutuhan dan pantau proses verifikasinya.',
        action: ['donatur', 'pemohon'].contains(user.role)
            ? FilledButton.icon(
                onPressed: _showApplicationForm,
                icon: const Icon(Icons.add),
                label: const Text('Ajukan Bantuan'),
              )
            : null,
      ),
      const SizedBox(height: 22),
      if (_applications.isEmpty)
        const EmptyState(
          icon: Icons.fact_check_outlined,
          title: 'Belum ada pengajuan',
          message: 'Pengajuan bantuan yang dikirim akan tampil di sini.',
        )
      else
        ..._applications.map(
          (application) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            application.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        StatusPill(application.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${application.category} - ${application.location}',
                      style: const TextStyle(
                        color: NsdColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      application.story,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.payments_outlined, size: 16),
                          label: Text(formatRupiah(application.amountNeeded)),
                        ),
                        ...application.documents.map(
                          (document) => Chip(
                            avatar: const Icon(Icons.check, size: 15),
                            label: Text(document),
                          ),
                        ),
                      ],
                    ),
                    if (application.counselor != null ||
                        application.counselorNotes != null) ...[
                      const Divider(height: 28),
                      Text(
                        'Konselor: ${application.counselor?.name ?? 'Ditugaskan'}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (application.counselorNotes != null)
                        Text(application.counselorNotes!),
                    ],
                    if (_canReviewApplications) ...[
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showApplicationManagement(application),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Proses Pengajuan'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _sessionsView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _viewHeader(
        'Ruang konseling',
        'Percakapan privat untuk pendampingan dan verifikasi kebutuhan.',
        action: ['donatur', 'pemohon'].contains(user.role)
            ? FilledButton.icon(
                onPressed: _showNewSession,
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('Mulai Konseling'),
              )
            : null,
      ),
      const SizedBox(height: 22),
      if (_sessions.isEmpty)
        const EmptyState(
          icon: Icons.forum_outlined,
          title: 'Belum ada sesi',
          message: 'Sesi konseling aktif akan tampil di sini.',
        )
      else
        ..._sessions.map(
          (session) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(18),
                leading: const CircleAvatar(
                  backgroundColor: NsdColors.mint,
                  child: Icon(Icons.forum, color: NsdColors.green),
                ),
                title: Text(
                  session.topic,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  user.role == 'konselor'
                      ? 'Dengan ${session.user.name}'
                      : 'Konselor ${session.counselor.name}',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => _showChat(session),
                  child: const Text('Buka Chat'),
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _campaignsView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _viewHeader(
        'Kelola campaign',
        'Perbarui status publikasi dan pantau dana setiap campaign.',
        action: ['admin', 'super_admin'].contains(user.role)
            ? FilledButton.icon(
                onPressed: _showCampaignForm,
                icon: const Icon(Icons.add),
                label: const Text('Campaign Baru'),
              )
            : null,
      ),
      const SizedBox(height: 22),
      ..._overview!.campaigns.map(
        (campaign) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: CircleAvatar(
                backgroundColor: hexColor(
                  campaign.accent,
                ).withValues(alpha: .13),
                child: Icon(Icons.campaign, color: hexColor(campaign.accent)),
              ),
              title: Text(
                campaign.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${campaign.location}\n${formatRupiah(campaign.raised)} / ${formatRupiah(campaign.target)}',
              ),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: [
                  StatusPill(campaign.status),
                  PopupMenuButton<String>(
                    tooltip: 'Ubah status',
                    onSelected: (status) =>
                        _updateCampaignStatus(campaign, status),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'verifikasi',
                        child: Text('Verifikasi'),
                      ),
                      PopupMenuItem(value: 'aktif', child: Text('Aktif')),
                      PopupMenuItem(value: 'darurat', child: Text('Darurat')),
                      PopupMenuItem(value: 'selesai', child: Text('Selesai')),
                      PopupMenuItem(value: 'ditutup', child: Text('Ditutup')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _auditView() {
    final audit = (_adminOverview?['recentAudit'] as List<dynamic>? ?? [])
        .cast<Json>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _viewHeader(
          'Audit aktivitas',
          'Jejak perubahan penting untuk keamanan dan akuntabilitas.',
        ),
        const SizedBox(height: 22),
        if (audit.isEmpty)
          const EmptyState(
            icon: Icons.security_outlined,
            title: 'Belum ada aktivitas',
            message: 'Log audit akan tampil setelah ada aktivitas sistem.',
          )
        else
          Card(
            child: Column(
              children: audit
                  .map(
                    (item) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: NsdColors.mint,
                        child: Icon(
                          Icons.shield_outlined,
                          color: NsdColors.green,
                        ),
                      ),
                      title: Text(
                        item['action'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('${item['detail']}\nIP ${item['ip']}'),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _usersView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _viewHeader(
        'Kelola pengguna',
        'Daftar akun, peran, dan status verifikasi pengguna NSD.',
      ),
      const SizedBox(height: 22),
      Card(
        child: Column(
          children: _users
              .map(
                (account) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 7,
                  ),
                  leading: CircleAvatar(child: Text(account.name[0])),
                  title: Text(
                    account.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${account.email}\n${roleLabel(account.role)}',
                  ),
                  trailing: account.verified
                      ? const Icon(Icons.verified, color: NsdColors.green)
                      : const Icon(
                          Icons.pending_outlined,
                          color: NsdColors.gold,
                        ),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );

  Widget _notificationsView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _viewHeader(
        'Notifikasi',
        'Pembaruan donasi, pengajuan, dan aktivitas akun.',
        action: TextButton.icon(
          onPressed: _markNotificationsRead,
          icon: const Icon(Icons.done_all),
          label: const Text('Tandai Dibaca'),
        ),
      ),
      const SizedBox(height: 22),
      if (_notifications.isEmpty)
        const EmptyState(
          icon: Icons.notifications_none,
          title: 'Tidak ada notifikasi',
          message: 'Informasi terbaru akan tampil di sini.',
        )
      else
        ..._notifications.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              color: item['read'] == true ? Colors.white : NsdColors.mint,
              child: ListTile(
                contentPadding: const EdgeInsets.all(18),
                leading: Icon(
                  item['read'] == true
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: NsdColors.green,
                ),
                title: Text(
                  item['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(item['message'] as String),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _profileView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _viewHeader(
        'Profil & keamanan',
        'Informasi akun dan pengaturan kredensial.',
      ),
      const SizedBox(height: 22),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: NsdColors.green,
                  child: Text(
                    user.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                Text(roleLabel(user.role)),
                const Divider(height: 36),
                _ProfileRow(Icons.mail_outline, 'Email', user.email),
                _ProfileRow(Icons.phone_outlined, 'Telepon', user.phone),
                _ProfileRow(
                  Icons.verified_user_outlined,
                  'Status',
                  user.verified ? 'Terverifikasi' : 'Belum terverifikasi',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showPasswordForm,
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Ganti Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _viewHeader(String title, String subtitle, {Widget? action}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(subtitle),
          ],
        ),
      ),
      ?action,
    ],
  );

  Future<void> _showApplicationForm() async {
    final title = TextEditingController();
    final category = TextEditingController(text: 'Bencana Alam');
    final location = TextEditingController();
    final amount = TextEditingController();
    final story = TextEditingController();
    final documents = TextEditingController(
      text: 'KTP, Foto kondisi, Surat keterangan',
    );
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajukan bantuan'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Judul kebutuhan',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: location,
                  decoration: const InputDecoration(labelText: 'Lokasi'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dana dibutuhkan',
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: story,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Ceritakan kondisi (minimal 50 karakter)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: documents,
                  decoration: const InputDecoration(
                    labelText: 'Dokumen, pisahkan dengan koma',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await widget.api.post('/applications', {
                  'title': title.text,
                  'category': category.text,
                  'location': location.text,
                  'amountNeeded':
                      int.tryParse(amount.text.replaceAll(RegExp(r'\D'), '')) ??
                      0,
                  'story': story.text,
                  'documents': documents.text
                      .split(',')
                      .map((item) => item.trim())
                      .where((item) => item.isNotEmpty)
                      .toList(),
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } on ApiException catch (error) {
                if (dialogContext.mounted) {
                  showMessage(dialogContext, error.message, error: true);
                }
              }
            },
            child: const Text('Kirim Pengajuan'),
          ),
        ],
      ),
    );
    title.dispose();
    category.dispose();
    location.dispose();
    amount.dispose();
    story.dispose();
    documents.dispose();
    if (created == true) {
      await _load();
      if (mounted) showMessage(context, 'Pengajuan berhasil dikirim.');
    }
  }

  Future<void> _showApplicationManagement(AidApplication application) async {
    var status = application.status;
    String? counselorId = application.counselorId;
    final statusOptions = _isCounselor
        ? const ['konseling', 'direkomendasikan']
        : const [
            'diajukan',
            'konseling',
            'direkomendasikan',
            'disetujui',
            'ditolak',
            'dipublikasikan',
          ];
    if (!statusOptions.contains(status)) status = statusOptions.first;
    final notes = TextEditingController(
      text: application.counselorNotes ?? application.adminNotes ?? '',
    );
    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Proses pengajuan'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: statusOptions
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(statusLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => status = value!),
                ),
                if (_isInternalAdmin) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: counselorId,
                    decoration: const InputDecoration(labelText: 'Konselor'),
                    items: _counselors
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => counselorId = value),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Catatan'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final body = <String, dynamic>{'status': status};
                  if (_isInternalAdmin && counselorId != null) {
                    body['counselorId'] = counselorId;
                  }
                  if (_isCounselor) {
                    body['counselorNotes'] = notes.text;
                  } else {
                    body['adminNotes'] = notes.text;
                  }
                  await widget.api.patch(
                    '/applications/${application.id}',
                    body,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } on ApiException catch (error) {
                  if (dialogContext.mounted) {
                    showMessage(dialogContext, error.message, error: true);
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    notes.dispose();
    if (updated == true) {
      await _load();
      if (mounted) showMessage(context, 'Pengajuan berhasil diperbarui.');
    }
  }

  Future<void> _showNewSession() async {
    if (_counselors.isEmpty) {
      showMessage(context, 'Belum ada konselor tersedia.', error: true);
      return;
    }
    String counselorId = _counselors.first.id;
    final topic = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Mulai konseling'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: counselorId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih konselor',
                  ),
                  items: _counselors
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => counselorId = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topic,
                  decoration: const InputDecoration(
                    labelText: 'Topik konseling',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await widget.api.post('/sessions', {
                    'counselorId': counselorId,
                    'topic': topic.text,
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } on ApiException catch (error) {
                  if (dialogContext.mounted) {
                    showMessage(dialogContext, error.message, error: true);
                  }
                }
              },
              child: const Text('Mulai'),
            ),
          ],
        ),
      ),
    );
    topic.dispose();
    if (created == true) await _load();
  }

  Future<void> _showChat(CounselingSession initialSession) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ChatDialog(
        api: widget.api,
        session: initialSession,
        currentUser: user,
        refresh: _load,
      ),
    );
    await _load(silent: true);
  }

  Future<void> _showCampaignForm() async {
    final title = TextEditingController();
    final summary = TextEditingController();
    final description = TextEditingController();
    final category = TextEditingController();
    final location = TextEditingController();
    final target = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Campaign baru'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Judul'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: summary,
                  decoration: const InputDecoration(labelText: 'Ringkasan'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: location,
                  decoration: const InputDecoration(labelText: 'Lokasi'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: target,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target dana',
                    prefixText: 'Rp ',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await widget.api.post('/admin/campaigns', {
                  'title': title.text,
                  'summary': summary.text,
                  'description': description.text,
                  'category': category.text,
                  'location': location.text,
                  'target':
                      int.tryParse(target.text.replaceAll(RegExp(r'\D'), '')) ??
                      0,
                  'status': 'verifikasi',
                  'daysLeft': 30,
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } on ApiException catch (error) {
                if (dialogContext.mounted) {
                  showMessage(dialogContext, error.message, error: true);
                }
              }
            },
            child: const Text('Buat Campaign'),
          ),
        ],
      ),
    );
    for (final controller in [
      title,
      summary,
      description,
      category,
      location,
      target,
    ]) {
      controller.dispose();
    }
    if (created == true) await _load();
  }

  Future<void> _updateCampaignStatus(Campaign campaign, String status) async {
    try {
      await widget.api.patch('/admin/campaigns/${campaign.id}', {
        'status': status,
      });
      await _load();
      if (mounted) showMessage(context, 'Status campaign diperbarui.');
    } on ApiException catch (error) {
      if (mounted) showMessage(context, error.message, error: true);
    }
  }

  Future<void> _markNotificationsRead() async {
    await widget.api.post('/notifications/read-all');
    await _load();
  }

  Future<void> _showPasswordForm() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ganti password'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password saat ini',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password baru (minimal 8 karakter)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await widget.api.patch('/auth/password', {
                  'currentPassword': current.text,
                  'newPassword': next.text,
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } on ApiException catch (error) {
                if (dialogContext.mounted) {
                  showMessage(dialogContext, error.message, error: true);
                }
              }
            },
            child: const Text('Perbarui'),
          ),
        ],
      ),
    );
    current.dispose();
    next.dispose();
    if (changed == true && mounted) {
      showMessage(context, 'Password berhasil diperbarui.');
    }
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.key);
  final String label;
  final IconData icon;
  final String key;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, color: NsdColors.green),
        const SizedBox(width: 14),
        SizedBox(width: 90, child: Text(label)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: NsdColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ChatDialog extends StatefulWidget {
  const _ChatDialog({
    required this.api,
    required this.session,
    required this.currentUser,
    required this.refresh,
  });

  final ApiClient api;
  final CounselingSession session;
  final User currentUser;
  final Future<void> Function({bool silent}) refresh;

  @override
  State<_ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<_ChatDialog> {
  final _message = TextEditingController();
  final _scroll = ScrollController();
  late List<Json> _messages;
  io.Socket? _socket;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages = [...widget.session.messages];
    _socket = io.io(
      ApiClient.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    )..connect();
    _socket!.on('chat.message', (payload) {
      if (payload is Map &&
          payload['sessionId'] == widget.session.id &&
          payload['message'] is Map) {
        final incoming = Map<String, dynamic>.from(payload['message'] as Map);
        if (!_messages.any((item) => item['id'] == incoming['id'])) {
          setState(() => _messages.add(incoming));
          _scrollToBottom();
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _socket?.dispose();
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final response =
          await widget.api.post('/sessions/${widget.session.id}/messages', {
                'text': text,
              })
              as Json;
      setState(() {
        if (!_messages.any((item) => item['id'] == response['id'])) {
          _messages.add(response);
        }
        _message.clear();
      });
      _scrollToBottom();
    } on ApiException catch (error) {
      if (mounted) showMessage(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: SizedBox(
      width: 650,
      height: 680,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: NsdColors.mint,
                  child: Icon(Icons.forum, color: NsdColors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session.topic,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        widget.currentUser.role == 'konselor'
                            ? widget.session.user.name
                            : widget.session.counselor.name,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _messages.isEmpty
                ? const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'Mulai percakapan',
                    message: 'Kirim pesan pertama Anda dengan aman.',
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final item = _messages[index];
                      final mine = item['senderId'] == widget.currentUser.id;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 430),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: mine ? NsdColors.green : NsdColors.mint,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(mine ? 16 : 4),
                              bottomRight: Radius.circular(mine ? 4 : 16),
                            ),
                          ),
                          child: Text(
                            item['text'] as String,
                            style: TextStyle(
                              color: mine ? Colors.white : NsdColors.ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _message,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

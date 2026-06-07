typedef Json = Map<String, dynamic>;

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.verified,
    this.faith,
    this.specialization,
    this.available,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool verified;
  final String? faith;
  final String? specialization;
  final bool? available;

  factory User.fromJson(Json json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String? ?? '',
    role: json['role'] as String,
    verified: json['verified'] as bool? ?? false,
    faith: json['faith'] as String?,
    specialization: json['specialization'] as String?,
    available: json['available'] as bool?,
  );
}

class Campaign {
  const Campaign({
    required this.id,
    required this.slug,
    required this.title,
    required this.summary,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.target,
    required this.raised,
    required this.distributed,
    required this.donorCount,
    required this.daysLeft,
    required this.accent,
    required this.verified,
    this.disbursements = const [],
    this.recentDonations = const [],
  });

  final String id;
  final String slug;
  final String title;
  final String summary;
  final String description;
  final String category;
  final String location;
  final String status;
  final int target;
  final int raised;
  final int distributed;
  final int donorCount;
  final int daysLeft;
  final String accent;
  final bool verified;
  final List<Disbursement> disbursements;
  final List<Json> recentDonations;

  double get progress => target == 0 ? 0 : (raised / target).clamp(0, 1);
  int get availableFunds => raised - distributed;

  factory Campaign.fromJson(Json json) => Campaign(
    id: json['id'] as String,
    slug: json['slug'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String,
    description: json['description'] as String,
    category: json['category'] as String,
    location: json['location'] as String,
    status: json['status'] as String,
    target: (json['target'] as num).round(),
    raised: (json['raised'] as num).round(),
    distributed: (json['distributed'] as num).round(),
    donorCount: (json['donorCount'] as num).round(),
    daysLeft: (json['daysLeft'] as num).round(),
    accent: json['accent'] as String? ?? '#3D8A73',
    verified: json['verified'] as bool? ?? false,
    disbursements: (json['disbursements'] as List<dynamic>? ?? [])
        .map((item) => Disbursement.fromJson(item as Json))
        .toList(),
    recentDonations: (json['recentDonations'] as List<dynamic>? ?? [])
        .cast<Json>(),
  );
}

class Disbursement {
  const Disbursement({
    required this.id,
    required this.campaignId,
    required this.date,
    required this.recipient,
    required this.description,
    required this.amount,
    required this.evidence,
  });

  final String id;
  final String campaignId;
  final String date;
  final String recipient;
  final String description;
  final int amount;
  final String evidence;

  factory Disbursement.fromJson(Json json) => Disbursement(
    id: json['id'] as String,
    campaignId: json['campaignId'] as String,
    date: json['date'] as String,
    recipient: json['recipient'] as String,
    description: json['description'] as String,
    amount: (json['amount'] as num).round(),
    evidence: json['evidence'] as String,
  );
}

class PublicOverview {
  const PublicOverview({
    required this.stats,
    required this.campaigns,
    required this.disbursements,
    required this.news,
    required this.dailyDonations,
  });

  final Json stats;
  final List<Campaign> campaigns;
  final List<Disbursement> disbursements;
  final List<Json> news;
  final List<Json> dailyDonations;

  factory PublicOverview.fromJson(Json json) => PublicOverview(
    stats: json['stats'] as Json,
    campaigns: (json['campaigns'] as List<dynamic>)
        .map((item) => Campaign.fromJson(item as Json))
        .toList(),
    disbursements: (json['disbursements'] as List<dynamic>)
        .map((item) => Disbursement.fromJson(item as Json))
        .toList(),
    news: (json['news'] as List<dynamic>).cast<Json>(),
    dailyDonations: (json['dailyDonations'] as List<dynamic>).cast<Json>(),
  );
}

class Donation {
  const Donation({
    required this.id,
    required this.orderId,
    required this.campaignId,
    required this.amount,
    required this.method,
    required this.status,
    required this.anonymous,
    required this.paymentCode,
    required this.createdAt,
    this.campaign,
  });

  final String id;
  final String orderId;
  final String campaignId;
  final int amount;
  final String method;
  final String status;
  final bool anonymous;
  final String paymentCode;
  final String createdAt;
  final Campaign? campaign;

  factory Donation.fromJson(Json json) => Donation(
    id: json['id'] as String,
    orderId: json['orderId'] as String,
    campaignId: json['campaignId'] as String,
    amount: (json['amount'] as num).round(),
    method: json['method'] as String,
    status: json['status'] as String,
    anonymous: json['anonymous'] as bool? ?? false,
    paymentCode: json['paymentCode'] as String,
    createdAt: json['createdAt'] as String,
    campaign: json['campaign'] == null
        ? null
        : Campaign.fromJson(json['campaign'] as Json),
  );
}

class AidApplication {
  const AidApplication({
    required this.id,
    required this.applicantId,
    required this.title,
    required this.category,
    required this.location,
    required this.amountNeeded,
    required this.story,
    required this.documents,
    required this.status,
    required this.createdAt,
    this.counselorId,
    this.counselorNotes,
    this.adminNotes,
    this.applicant,
    this.counselor,
  });

  final String id;
  final String applicantId;
  final String title;
  final String category;
  final String location;
  final int amountNeeded;
  final String story;
  final List<String> documents;
  final String status;
  final String createdAt;
  final String? counselorId;
  final String? counselorNotes;
  final String? adminNotes;
  final User? applicant;
  final User? counselor;

  factory AidApplication.fromJson(Json json) => AidApplication(
    id: json['id'] as String,
    applicantId: json['applicantId'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    location: json['location'] as String,
    amountNeeded: (json['amountNeeded'] as num).round(),
    story: json['story'] as String,
    documents: (json['documents'] as List<dynamic>).cast<String>(),
    status: json['status'] as String,
    createdAt: json['createdAt'] as String,
    counselorId: json['counselorId'] as String?,
    counselorNotes: json['counselorNotes'] as String?,
    adminNotes: json['adminNotes'] as String?,
    applicant: json['applicant'] == null
        ? null
        : User.fromJson(json['applicant'] as Json),
    counselor: json['counselor'] == null
        ? null
        : User.fromJson(json['counselor'] as Json),
  );
}

class CounselingSession {
  const CounselingSession({
    required this.id,
    required this.userId,
    required this.counselorId,
    required this.topic,
    required this.status,
    required this.messages,
    required this.user,
    required this.counselor,
  });

  final String id;
  final String userId;
  final String counselorId;
  final String topic;
  final String status;
  final List<Json> messages;
  final User user;
  final User counselor;

  factory CounselingSession.fromJson(Json json) => CounselingSession(
    id: json['id'] as String,
    userId: json['userId'] as String,
    counselorId: json['counselorId'] as String,
    topic: json['topic'] as String,
    status: json['status'] as String,
    messages: (json['messages'] as List<dynamic>).cast<Json>(),
    user: User.fromJson(json['user'] as Json),
    counselor: User.fromJson(json['counselor'] as Json),
  );
}

String formatRupiah(num value, {bool compact = false}) {
  if (compact) {
    if (value >= 1000000000) {
      return 'Rp${(value / 1000000000).toStringAsFixed(1).replaceAll('.0', '')} M';
    }
    if (value >= 1000000) {
      return 'Rp${(value / 1000000).toStringAsFixed(1).replaceAll('.0', '')} jt';
    }
    if (value >= 1000) return 'Rp${(value / 1000).toStringAsFixed(0)} rb';
  }
  final digits = value.round().toString();
  final output = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) output.write('.');
    output.write(digits[i]);
  }
  return 'Rp$output';
}

String roleLabel(String role) => switch (role) {
  'donatur' => 'Donatur',
  'pemohon' => 'Pemohon Bantuan',
  'konselor' => 'Konselor',
  'operator' => 'Operator',
  'admin' => 'Administrator',
  'super_admin' => 'Super Admin',
  _ => role,
};

String statusLabel(String status) => status
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

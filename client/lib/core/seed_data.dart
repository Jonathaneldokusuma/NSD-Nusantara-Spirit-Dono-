import 'models.dart';

final seedOverview = PublicOverview.fromJson({
  'stats': {
    'totalRaised': 1023450000,
    'totalDistributed': 615000000,
    'activeCampaigns': 4,
    'donors': 9088,
    'verifiedApplications': 1,
  },
  'campaigns': [
    {
      'id': 'cmp-banjir',
      'slug': 'bantuan-banjir-bandang-sumatera',
      'title': 'Bantuan Banjir Bandang Sumatera',
      'summary':
          'Makanan, air bersih, dan layanan kesehatan untuk keluarga terdampak.',
      'description':
          'Ratusan keluarga membutuhkan bantuan darurat setelah banjir bandang merusak rumah dan akses jalan.',
      'category': 'Bencana Alam',
      'location': 'Sumatera Barat',
      'status': 'darurat',
      'target': 750000000,
      'raised': 512450000,
      'distributed': 286000000,
      'donorCount': 4231,
      'daysLeft': 9,
      'accent': '#E85D4A',
      'verified': true,
      'disbursements': [
        {
          'id': 'dis-1',
          'campaignId': 'cmp-banjir',
          'date': '2026-06-05',
          'recipient': 'Posko Sungai Limau',
          'description': '1.200 paket pangan dan air bersih',
          'amount': 146000000,
          'evidence': 'Dokumentasi penyaluran terverifikasi',
        },
      ],
      'recentDonations': [],
    },
  ],
  'disbursements': [],
  'news': [
    {
      'id': 'news-1',
      'title': 'Akses air bersih menjadi kebutuhan utama di Sumatera Barat',
      'excerpt':
          'Tim lapangan memprioritaskan distribusi air minum dan hygiene kit ke tiga kecamatan.',
      'location': 'Sumatera Barat',
      'severity': 'darurat',
      'publishedAt': '2026-06-07T06:30:00.000Z',
    },
  ],
  'dailyDonations': List.generate(14, (index) => {
        'date': DateTime.now()
            .subtract(Duration(days: 13 - index))
            .toIso8601String()
            .substring(0, 10),
        'amount': 18000000 + index * 3750000,
      }),
});

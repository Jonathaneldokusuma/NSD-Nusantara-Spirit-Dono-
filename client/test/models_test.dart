import 'package:flutter_test/flutter_test.dart';
import 'package:nsd_app/core/models.dart';

void main() {
  test('formatRupiah formats Indonesian currency', () {
    expect(formatRupiah(1250000), 'Rp1.250.000');
    expect(formatRupiah(1250000, compact: true), 'Rp1.3 jt');
  });

  test('Campaign calculates progress and available funds', () {
    final campaign = Campaign.fromJson({
      'id': 'cmp',
      'slug': 'campaign',
      'title': 'Campaign',
      'summary': 'Ringkasan',
      'description': 'Deskripsi',
      'category': 'Bencana',
      'location': 'Indonesia',
      'status': 'aktif',
      'target': 1000000,
      'raised': 600000,
      'distributed': 250000,
      'donorCount': 10,
      'daysLeft': 7,
      'accent': '#2F806A',
      'verified': true,
    });

    expect(campaign.progress, .6);
    expect(campaign.availableFunds, 350000);
  });
}

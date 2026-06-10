/// Model untuk akun pembayaran (bank & e-wallet) yang diambil dari API.
class PaymentAccountModel {
  final int id;
  final String type; // 'bank' | 'ewallet'
  final String providerName;
  final String providerCode;
  final String accountNumber;
  final String accountName;

  const PaymentAccountModel({
    required this.id,
    required this.type,
    required this.providerName,
    required this.providerCode,
    required this.accountNumber,
    required this.accountName,
  });

  factory PaymentAccountModel.fromJson(Map<String, dynamic> j) =>
      PaymentAccountModel(
        id: j['id'] as int,
        type: j['type'] as String,
        providerName: j['provider_name'] as String,
        providerCode: j['provider_code'] as String,
        accountNumber: j['account_number'] as String,
        accountName: j['account_name'] as String,
      );

  bool get isBank => type == 'bank';
  bool get isEwallet => type == 'ewallet';

  /// Warna background brand sesuai provider_code
  static const Map<String, int> _brandColors = {
    'bca':       0xFF005BAA,
    'bri':       0xFF003D7C,
    'mandiri':   0xFF003D7C,
    'bsi':       0xFF1FAD49,
    'bni':       0xFFE65100,
    'gopay':     0xFF00AED6,
    'ovo':       0xFF4C3494,
    'dana':      0xFF118EEA,
    'shopeepay': 0xFFEE4D2D,
  };

  /// Warna teks brand (untuk Mandiri pakai kuning)
  static const Map<String, int> _textColors = {
    'mandiri': 0xFFFFCB05,
  };

  int get brandColorValue => _brandColors[providerCode] ?? 0xFF64748B;
  int get brandTextColorValue => _textColors[providerCode] ?? 0xFFFFFFFF;
}

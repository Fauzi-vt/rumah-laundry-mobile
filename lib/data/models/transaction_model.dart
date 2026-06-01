import 'service_model.dart';

class TransactionDetailModel {
  final int id;
  final int serviceId;
  final ServiceModel service;
  final double quantity;
  final double price;
  final double subtotal;

  const TransactionDetailModel({
    required this.id,
    required this.serviceId,
    required this.service,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory TransactionDetailModel.fromJson(Map<String, dynamic> j) =>
      TransactionDetailModel(
        id: j['id'] as int,
        serviceId: j['service_id'] as int,
        service: ServiceModel.fromJson(j['service'] as Map<String, dynamic>),
        quantity: double.parse(j['quantity'].toString()),
        price: double.parse(j['price'].toString()),
        subtotal: double.parse(j['subtotal'].toString()),
      );
}

class TransactionModel {
  final int id;
  final String invoiceCode;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final String? address;
  final String? phone;
  final String? paymentMethod;
  final String? deliveryType;
  final List<TransactionDetailModel> details;

  const TransactionModel({
    required this.id,
    required this.invoiceCode,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.address,
    this.phone,
    this.paymentMethod,
    this.deliveryType,
    required this.details,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
    id: j['id'] as int,
    invoiceCode: j['invoice_code'] as String,
    totalPrice: double.parse(j['total_price'].toString()),
    status: j['status'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    address: j['address'] as String?,
    phone: j['phone'] as String?,
    paymentMethod: j['payment_method'] as String?,
    deliveryType: j['delivery_type'] as String?,
    details: (j['details'] as List? ?? [])
        .map((d) => TransactionDetailModel.fromJson(d as Map<String, dynamic>))
        .toList(),
  );

  String get formattedTotal {
    final s = totalPrice.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $s';
  }

  /// Short description of what was ordered
  String get itemSummary {
    if (details.isEmpty) return 'Tidak ada item';
    if (details.length == 1) return details.first.service.name;
    return '${details.first.service.name} +${details.length - 1} lainnya';
  }
}

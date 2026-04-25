class ServiceModel {
  final int    id;
  final String name;
  final String category;
  final double price;
  final String unit;
  final String? description;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    this.description,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> j) => ServiceModel(
        id:          j['id']          as int,
        name:        j['name']        as String,
        category:    j['category']    as String? ?? '',
        price:       (j['price'] as num).toDouble(),
        unit:        j['unit']        as String? ?? 'kg',
        description: j['description'] as String?,
      );

  /// Returns an emoji icon that mirrors the backend getIconAttribute()
  String get icon {
    final n = name.toLowerCase();
    final c = category.toLowerCase();
    if (n.contains('sepatu') || c.contains('sepatu'))             return '👟';
    if (n.contains('selimut') || n.contains('bedcover') || c.contains('linen')) return '🛏️';
    if (n.contains('kilat') || c.contains('kilat'))               return '⚡';
    if (n.contains('karpet') || c.contains('karpet'))             return '🪄';
    if (n.contains('setrika') || c.contains('setrika'))           return '👔';
    if (n.contains('tas') || c.contains('tas'))                   return '👜';
    return '👕';
  }

  String get formattedPrice {
    final p = price.toInt();
    final s = p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $s / $unit';
  }
}

import 'package:flutter/material.dart';
import '../../core/api_constants.dart';

class ServiceModel {
  final int    id;
  final String name;
  final String category;
  final double price;
  final String unit;
  final String? description;
  final String? imageUrl;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    this.description,
    this.imageUrl,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> j) => ServiceModel(
        id:          j['id']          as int,
        name:        j['name']        as String,
        category:    j['category']    as String? ?? '',
        price:       double.parse(j['price'].toString()),
        unit:        j['unit']        as String? ?? 'kg',
        description: j['description'] as String?,
        imageUrl:    ApiConstants.normalizeUrl(j['image_url'] as String?),
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

  IconData get materialIcon {
    final n = name.toLowerCase();
    final c = category.toLowerCase();
    if (n.contains('sepatu') || c.contains('sepatu'))             return Icons.roller_skating_outlined;
    if (n.contains('selimut') || n.contains('bedcover') || c.contains('linen')) return Icons.bed_outlined;
    if (n.contains('kilat') || c.contains('kilat'))               return Icons.bolt_rounded;
    if (n.contains('karpet') || c.contains('karpet'))             return Icons.texture_rounded;
    if (n.contains('setrika') || c.contains('setrika'))           return Icons.iron_outlined;
    if (n.contains('tas') || c.contains('tas'))                   return Icons.shopping_bag_outlined;
    return Icons.checkroom_outlined;
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

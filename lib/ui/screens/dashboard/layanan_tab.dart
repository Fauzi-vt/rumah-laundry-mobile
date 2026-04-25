import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../data/models/service_model.dart';
import '../../../providers/dashboard_provider.dart';

class LayananTab extends StatelessWidget {
  const LayananTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Layanan Kami'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () => context.read<DashboardProvider>().refresh(),
        child: _buildBody(dash),
      ),
    );
  }

  Widget _buildBody(DashboardProvider dash) {
    if (dash.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }
    if (dash.services.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 80),
        Center(
          child: Column(children: [
            const Text('🧺', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text('Belum ada layanan',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ]),
        ),
      ]);
    }

    // Group by category
    final Map<String, List<ServiceModel>> grouped = {};
    for (final s in dash.services) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryHeader(entry.key),
            const SizedBox(height: 8),
            ...entry.value.map((s) => _ServiceCard(service: s)),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCategoryHeader(String category) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(category,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14)),
            child: Center(
                child: Text(service.icon,
                    style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                if (service.description != null) ...[
                  const SizedBox(height: 2),
                  Text(service.description!,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(service.formattedPrice,
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen)),
            ],
          ),
        ],
      ),
    );
  }
}

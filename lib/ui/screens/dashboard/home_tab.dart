import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dash      = context.watch<DashboardProvider>();
    final user      = context.watch<AuthProvider>().user;
    final firstName = (user?.name ?? 'Pelanggan').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () => context.read<DashboardProvider>().refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, firstName)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildSummaryRow(dash),
              ),
            ),
            SliverToBoxAdapter(child: _buildSectionTitle('Layanan Kami')),
            SliverToBoxAdapter(child: _buildServicesGrid(dash)),
            SliverToBoxAdapter(child: _buildSectionTitle('Pesanan Terbaru')),
            _buildRecentOrders(dash),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String firstName) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/logo.png', width: 42, height: 42),
              const Spacer(),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Halo, $firstName 👋',
              style: GoogleFonts.poppins(
                  color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 2),
          Text('Selamat Datang!',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            height: 46,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text('Cari layanan laundry…',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Cards ────────────────────────────────────────────────────────
  Widget _buildSummaryRow(DashboardProvider dash) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(
          icon:  Icons.local_laundry_service_rounded,
          color: AppColors.statusCuci,
          label: 'Aktif',
          value: dash.isLoading ? '…' : '${dash.activeOrders.length}',
        )),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(
          icon:  Icons.check_circle_rounded,
          color: AppColors.statusSelesai,
          label: 'Selesai',
          value: dash.isLoading ? '…' : '${dash.completedOrders.length}',
        )),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(
          icon:  Icons.layers_rounded,
          color: AppColors.primaryMid,
          label: 'Layanan',
          value: dash.isLoading ? '…' : '${dash.services.length}',
        )),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(title,
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
    );
  }

  // ── Services ──────────────────────────────────────────────────────────────
  Widget _buildServicesGrid(DashboardProvider dash) {
    if (dash.isLoading) {
      return const SizedBox(
        height: 110,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }
    if (dash.services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('Belum ada layanan tersedia.',
            style: GoogleFonts.poppins(
                color: AppColors.textSecondary, fontSize: 13)),
      );
    }
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dash.services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _ServiceChip(service: dash.services[i]),
      ),
    );
  }

  // ── Recent Orders ─────────────────────────────────────────────────────────
  Widget _buildRecentOrders(DashboardProvider dash) {
    if (dash.isLoading) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 80,
          child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen)),
        ),
      );
    }
    final recent = dash.transactions.take(5).toList();
    if (recent.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _EmptyOrders(),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: _TransactionCard(trx: recent[i]),
        ),
        childCount: recent.length,
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final String   value;
  const _SummaryCard(
      {required this.icon, required this.color,
       required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Service Chip ──────────────────────────────────────────────────────────────
class _ServiceChip extends StatelessWidget {
  final ServiceModel service;
  const _ServiceChip({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(service.icon, style: const TextStyle(fontSize: 26)),
          const Spacer(),
          Text(service.name,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(service.formattedPrice,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 9, color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Transaction Card ──────────────────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final TransactionModel trx;
  const _TransactionCard({required this.trx});

  @override
  Widget build(BuildContext context) {
    final sc = AppColors.statusColor(trx.status);
    final sl = AppColors.statusLabel(trx.status);
    return Container(
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
            width: 46, height: 46,
            decoration: BoxDecoration(
                color: sc.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.receipt_long_rounded, color: sc, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trx.invoiceCode,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(trx.itemSummary,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(sl,
                    style: GoogleFonts.poppins(
                        fontSize: 9, fontWeight: FontWeight.w600, color: sc)),
              ),
              const SizedBox(height: 4),
              Text(trx.formattedTotal,
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

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        children: [
          const Text('🧺', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text('Belum ada pesanan',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Yuk mulai laundry pertamamu!',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/notification_provider.dart';
import 'dashboard_shell.dart';
import 'notifications_screen.dart';
import 'transaction_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final user = context.watch<AuthProvider>().user;
    final rawName = (user?.name ?? 'Pelanggan').trim();
    final firstName = rawName.isNotEmpty ? rawName.split(' ').first : 'Pelanggan';
    final capitalizedName = firstName.isNotEmpty 
        ? '${firstName[0].toUpperCase()}${firstName.substring(1)}'
        : 'Pelanggan';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () => context.read<DashboardProvider>().refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, capitalizedName)),

            // ── Error Banner ──────────────────────────────────────────
            if (dash.error != null)
              SliverToBoxAdapter(
                child: _buildErrorBanner(context, dash.error!),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildSummaryRow(dash),
              ),
            ),
            SliverToBoxAdapter(child: _buildSectionTitle('Layanan Kami')),
            _buildServicesGrid(dash),
            SliverToBoxAdapter(child: _buildSectionTitle('Pesanan Terbaru')),
            _buildRecentOrders(dash),
            // Extra bottom padding so last card clears the nav bar
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error) {
    final isAuthError = error.contains('Sesi telah berakhir');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isAuthError ? Icons.lock_clock_rounded : Icons.wifi_off_rounded,
            color: Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAuthError ? 'Sesi Berakhir' : 'Gagal memuat data',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(
                  error,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              if (isAuthError) {
                final nav = Navigator.of(context);
                context.read<AuthProvider>().logout().then((_) {
                  nav.pushNamedAndRemoveUntil('/login', (route) => false);
                });
              } else {
                context.read<DashboardProvider>().refresh();
              }
            },
            child: Text(
              isAuthError ? 'Login Ulang' : 'Coba Lagi',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String firstName) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
              const Spacer(),
              // Tombol lonceng dengan badge notifikasi
              Consumer<NotificationProvider>(
                builder: (ctx, np, _) => GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      if (np.unreadCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: AnimatedScale(
                            scale: np.unreadCount > 0 ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                np.unreadCount > 9 ? '9+' : '${np.unreadCount}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32), // Increased from 20 for spacious vertical spacing
          Text(
            'Halo, $firstName 👋',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            'Selamat Datang!',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              const TabSwitchNotification(1).dispatch(context);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cari layanan laundry…',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
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
        Expanded(
          child: _SummaryCard(
            icon: Icons.local_laundry_service_rounded,
            color: AppColors.statusCuci,
            label: 'Aktif',
            value: dash.isLoading ? '…' : '${dash.activeOrders.length}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.check_circle_rounded,
            color: AppColors.statusSelesai,
            label: 'Selesai',
            value: dash.isLoading ? '…' : '${dash.completedOrders.length}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.layers_rounded,
            color: AppColors.primaryMid,
            label: 'Layanan',
            value: dash.isLoading ? '…' : '${dash.services.length}',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Services ──────────────────────────────────────────────────────────────
  Widget _buildServicesGrid(DashboardProvider dash) {
    if (dash.isLoading) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 110,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          ),
        ),
      );
    }
    if (dash.services.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Belum ada layanan tersedia.',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 140,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => _ServiceChip(service: dash.services[i]),
          childCount: dash.services.length,
        ),
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
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          ),
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
  final Color color;
  final String label;
  final String value;
  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isZero = value == '0';
    final cardBg = isZero ? const Color(0xFFF8F9FA) : Colors.white;
    final valueColor = isZero ? Colors.grey.shade400 : AppColors.textPrimary;
    final iconBgOpacity = isZero ? 0.05 : 0.12;
    final iconColor = isZero ? Colors.grey.shade400 : color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
        boxShadow: isZero ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: iconBgOpacity),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isZero ? Colors.grey.shade400 : AppColors.textSecondary,
            ),
          ),
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
    final hasImage = service.imageUrl != null && service.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        final dash = context.read<DashboardProvider>();
        final currentQty = dash.cart[service.id] ?? 0;
        if (currentQty <= 0) {
          dash.updateCart(service.id, 1.0);
        }
        const TabSwitchNotification(2).dispatch(context);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: hasImage
                    ? Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Image.network(
                          service.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: _buildIconFallback(),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGreen.withValues(alpha: 0.5),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : _buildIconFallback(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              service.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              service.formattedPrice,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconFallback() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        service.materialIcon,
        color: AppColors.primaryGreen,
        size: 20,
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
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => TransactionDetailScreen(transaction: trx),
            transitionsBuilder: (context, anim, secondaryAnimation, child) {
              final slide = Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
              return SlideTransition(position: slide, child: child);
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.receipt_long_rounded, color: sc, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trx.invoiceCode,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trx.itemSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sl,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: sc,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trx.formattedTotal,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada pesanan nih',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Yuk cuci baju sekarang!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                const TabSwitchNotification(1).dispatch(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Lihat Layanan',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/dashboard_provider.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesanan & Status'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Pembayaran'),
            Tab(text: 'Proses'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () => context.read<DashboardProvider>().refresh(),
        child: dash.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryGreen))
            : TabBarView(
                controller: _tab,
                children: [
                  _OrderList(orders: dash.transactions),
                  _OrderList(orders: dash.pendingPayments,
                      emptyMsg: 'Tidak ada tagihan tertunda 🎉'),
                  _OrderList(orders: dash.inProgressOrders,
                      emptyMsg: 'Tidak ada pesanan yang sedang diproses.'),
                  _OrderList(orders: dash.completedOrders,
                      emptyMsg: 'Belum ada pesanan yang selesai.'),
                ],
              ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<TransactionModel> orders;
  final String emptyMsg;
  const _OrderList(
      {required this.orders,
      this.emptyMsg = 'Belum ada pesanan.'});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 80),
        Center(
          child: Column(children: [
            const Text('🧺', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(emptyMsg,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ]),
        ),
      ]);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _OrderCard(trx: orders[i]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final TransactionModel trx;
  const _OrderCard({required this.trx});

  @override
  Widget build(BuildContext context) {
    final sc   = AppColors.statusColor(trx.status);
    final sl   = AppColors.statusLabel(trx.status);
    final date = '${trx.createdAt.day}/${trx.createdAt.month}/${trx.createdAt.year}';

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(children: [
            Expanded(
              child: Text(trx.invoiceCode,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: sc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(sl,
                  style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w600, color: sc)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(date,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),

          // Progress stepper
          const SizedBox(height: 12),
          _StatusStepper(status: trx.status),

          if (trx.details.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 10),
            ...trx.details.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Text(d.service.icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${d.service.name} × ${d.quantity} ${d.service.unit}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textPrimary)),
                ),
                Text(
                  'Rp ${d.subtotal.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary),
                ),
              ]),
            )),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(trx.formattedTotal,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Status Stepper ────────────────────────────────────────────────────────────
class _StatusStepper extends StatelessWidget {
  final String status;
  const _StatusStepper({required this.status});

  static const _steps = ['baru', 'cuci', 'kering', 'setrika', 'selesai', 'diambil'];
  static const _labels = ['Baru', 'Cuci', 'Kering', 'Setrika', 'Selesai', 'Diambil'];

  @override
  Widget build(BuildContext context) {
    final current = _steps.indexOf(status.toLowerCase());
    return Row(
      children: List.generate(_steps.length, (i) {
        final done   = i <= current;
        final active = i == current;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.statusColor(status) : AppColors.cardBorder,
                    ),
                    child: active
                        ? const Icon(Icons.circle, size: 10, color: Colors.white)
                        : done
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                  ),
                  const SizedBox(height: 2),
                  Text(_labels[i],
                      style: GoogleFonts.poppins(
                          fontSize: 7,
                          color: done ? AppColors.statusColor(status) : AppColors.textSecondary,
                          fontWeight: done ? FontWeight.w600 : FontWeight.w400)),
                ],
              ),
              if (i < _steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    color: i < current ? AppColors.statusColor(status) : AppColors.cardBorder,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

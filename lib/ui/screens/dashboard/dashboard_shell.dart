import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../providers/dashboard_provider.dart';
import 'home_tab.dart';
import 'layanan_tab.dart';
import 'order_tab.dart';
import 'orders_tab.dart';
import 'profile_tab.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;

  static const _tabs = [
    HomeTab(),
    LayananTab(),
    OrderTab(),
    OrdersTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded,
                  label: 'Beranda', index: 0, current: _currentIndex, onTap: _onTap),
              _NavItem(icon: Icons.local_laundry_service_rounded,
                  label: 'Layanan', index: 1, current: _currentIndex, onTap: _onTap),
              _NavItem(icon: Icons.add_circle_rounded,
                  label: 'Order', index: 2, current: _currentIndex, onTap: _onTap, isAction: true),
              _NavItem(icon: Icons.receipt_long_rounded,
                  label: 'Pesanan', index: 3, current: _currentIndex, onTap: _onTap),
              _NavItem(icon: Icons.person_rounded,
                  label: 'Profil', index: 4, current: _currentIndex, onTap: _onTap),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(int i) => setState(() => _currentIndex = i);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int      index, current;
  final void Function(int) onTap;
  final bool     isAction;

  const _NavItem({
    required this.icon, required this.label,
    required this.index, required this.current, required this.onTap,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;

    if (isAction) {
      return GestureDetector(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryMid, AppColors.primaryGreen],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.4),
                      blurRadius: 12, offset: const Offset(0, 4))]),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? AppColors.primaryGreen : AppColors.textSecondary)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22,
                color: active ? AppColors.primaryGreen : AppColors.textSecondary),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? AppColors.primaryGreen : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

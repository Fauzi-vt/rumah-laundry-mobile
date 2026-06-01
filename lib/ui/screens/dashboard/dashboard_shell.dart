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

class _DashboardShellState extends State<DashboardShell>
    with TickerProviderStateMixin {
  int _currentIndex  = 0;
  int _previousIndex = 0;

  // Buat instance baru tiap rebuild agar AnimatedSwitcher mendeteksi perubahan
  final List<Widget> _tabWidgets = const [
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

  void _onTap(int i) {
    if (i == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex  = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final goingRight = _currentIndex > _previousIndex;

    return Scaffold(
      body: NotificationListener<TabSwitchNotification>(
        onNotification: (notification) {
          _onTap(notification.index);
          return true;
        },
        child: _TabTransitionView(
          index:      _currentIndex,
          goingRight: goingRight,
          child:      _tabWidgets[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
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
                  label: 'Order', index: 2, current: _currentIndex, onTap: _onTap,
                  isAction: true),
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
}

// ── Animated page container ────────────────────────────────────────────────────
class _TabTransitionView extends StatefulWidget {
  final int    index;
  final bool   goingRight;
  final Widget child;

  const _TabTransitionView({
    required this.index,
    required this.goingRight,
    required this.child,
  });

  @override
  State<_TabTransitionView> createState() => _TabTransitionViewState();
}

class _TabTransitionViewState extends State<_TabTransitionView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset>   _slide;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _buildAnimations();
    _ctrl.forward();
  }

  void _buildAnimations() {
    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: Offset(widget.goingRight ? 0.12 : -0.12, 0),
      end:   Offset.zero,
    ).animate(curved);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
  }

  @override
  void didUpdateWidget(_TabTransitionView old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _ctrl.reset();
      _buildAnimations();
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: widget.child,
      ),
    );
  }
}

// ── Nav Item ──────────────────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final IconData           icon;
  final String             label;
  final int                index, current;
  final void Function(int) onTap;
  final bool               isAction;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.isAction = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0.86,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _pressCtrl.reverse();
    widget.onTap(widget.index);
    _pressCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.index == widget.current;

    // ── Action button (Order) ─────────────────────────────────────────────
    if (widget.isAction) {
      return GestureDetector(
        onTap: _handleTap,
        child: ScaleTransition(
          scale: _pressCtrl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                width:  active ? 52 : 46,
                height: active ? 52 : 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryMid, AppColors.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen
                          .withOpacity(active ? 0.55 : 0.25),
                      blurRadius: active ? 20 : 8,
                      spreadRadius: active ? 2 : 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.add_rounded,
                    color: Colors.white, size: active ? 28 : 24),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active
                      ? AppColors.primaryGreen
                      : AppColors.textSecondary,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      );
    }

    // ── Regular item ──────────────────────────────────────────────────────
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _pressCtrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon bounce-in on activation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  widget.icon,
                  key: ValueKey<bool>(active),
                  size: active ? 24 : 22,
                  color: active
                      ? AppColors.primaryGreen
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              // Growing pill indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                width:  active ? 20 : 0,
                height: active ? 3  : 0,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active
                      ? AppColors.primaryGreen
                      : AppColors.textSecondary,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TabSwitchNotification extends Notification {
  final int index;
  const TabSwitchNotification(this.index);
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _editing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _address;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name    = TextEditingController(text: user?.name ?? '');
    _email   = TextEditingController(text: user?.email ?? '');
    _phone   = TextEditingController(text: user?.phone ?? '');
    _address = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose(); _email.dispose();
    _phone.dispose(); _address.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final dash = context.read<DashboardProvider>();
    final auth = context.read<AuthProvider>();

    final (user, err) = await dash.updateProfile(
      name:    _name.text.trim(),
      email:   _email.text.trim(),
      phone:   _phone.text.trim(),
      address: _address.text.trim(),
    );

    if (!mounted) return;
    if (err == null && user != null) {
      await auth.updateUser(user);
      setState(() => _editing = false);
      _showSnack('Profil berhasil diperbarui!');
    } else {
      _showSnack(err ?? 'Gagal memperbarui profil.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: isError ? Colors.red.shade700 : AppColors.primaryGreen,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user    = context.watch<AuthProvider>().user;
    final initial = (user?.name ?? 'U')[0].toUpperCase();
    final isLoading = context.watch<DashboardProvider>().profileLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _editing
                ? () => setState(() => _editing = false)
                : () => setState(() => _editing = true),
            child: Text(
              _editing ? 'Batal' : 'Edit',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── Avatar Header ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: AppColors.primaryGreen,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(initial,
                    style: GoogleFonts.poppins(
                        fontSize: 30, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(height: 12),
              Text(user?.name ?? '-',
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(user?.email ?? '-',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.white70)),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Stats ─────────────────────────────────────────────────────
          _buildStats(context),
          const SizedBox(height: 20),

          // ── Form / Info ───────────────────────────────────────────────
          _editing ? _buildEditForm(isLoading) : _buildInfoSection(user),

          const SizedBox(height: 12),

          // ── Menu ─────────────────────────────────────────────────────
          if (!_editing) _buildOtherMenu(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Stats bar ─────────────────────────────────────────────────────────────
  Widget _buildStats(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: 'Total Pesanan', value: '${dash.transactions.length}'),
            Container(width: 1, height: 36, color: AppColors.cardBorder),
            _Stat(label: 'Pesanan Aktif', value: '${dash.activeOrders.length}'),
            Container(width: 1, height: 36, color: AppColors.cardBorder),
            _Stat(
              label: 'Total Bayar',
              value: 'Rp ${dash.totalSpent.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
              small: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(user) {
    return _Section('Informasi Akun', [
      _InfoRow(icon: Icons.person_outline_rounded,
          label: 'Nama', value: user?.name ?? '-'),
      _InfoRow(icon: Icons.email_outlined,
          label: 'Email', value: user?.email ?? '-'),
      _InfoRow(icon: Icons.phone_outlined,
          label: 'Nomor HP',
          value: (user?.phone?.isNotEmpty == true) ? user!.phone! : '-'),
      _InfoRow(icon: Icons.location_on_outlined,
          label: 'Alamat',
          value: (user?.address?.isNotEmpty == true) ? user!.address! : '-'),
    ]);
  }

  Widget _buildEditForm(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Profil',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                _Field(ctrl: _name,    label: 'Nama Lengkap',
                    icon: Icons.person_outline_rounded, required: true),
                const SizedBox(height: 12),
                _Field(ctrl: _email,   label: 'Email',
                    icon: Icons.email_outlined,
                    required: true, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _Field(ctrl: _phone,   label: 'Nomor HP',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _Field(ctrl: _address, label: 'Alamat',
                    icon: Icons.location_on_outlined, maxLines: 2),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveProfile,
                child: isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text('Simpan Perubahan',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherMenu(BuildContext context) {
    return _Section('Lainnya', [
      _MenuRow(icon: Icons.info_outline_rounded,
          label: 'Tentang Aplikasi', onTap: () {}),
      _MenuRow(
        icon: Icons.logout_rounded,
        label: 'Keluar',
        color: Colors.red.shade600,
        onTap: () => _confirmLogout(context),
      ),
    ]);
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Konfirmasi Keluar',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Apakah Anda yakin ingin keluar?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
            child: Text('Keluar',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String label, value;
  final bool small;
  const _Stat({required this.label, required this.value, this.small = false});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value,
        style: GoogleFonts.poppins(
            fontSize: small ? 12 : 18, fontWeight: FontWeight.w700,
            color: AppColors.primaryGreen)),
    Text(label,
        style: GoogleFonts.poppins(
            fontSize: 10, color: AppColors.textSecondary)),
  ]);
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(title,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textSecondary, letterSpacing: 0.5)),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          children: List.generate(children.length, (i) => Column(children: [
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, indent: 56, color: AppColors.cardBorder),
          ])),
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Icon(icon, size: 20, color: AppColors.primaryGreen),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      ]),
    ]),
  );
}

class _MenuRow extends StatelessWidget {
  final IconData icon; final String label; final Color? color;
  final VoidCallback onTap;
  const _MenuRow({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Icon(icon, size: 20, color: c), const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: c))),
          Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label; final IconData icon;
  final bool required; final int maxLines;
  final TextInputType? keyboardType;
  const _Field({required this.ctrl, required this.label, required this.icon,
      this.required = false, this.maxLines = 1, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines, keyboardType: keyboardType,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label tidak boleh kosong' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

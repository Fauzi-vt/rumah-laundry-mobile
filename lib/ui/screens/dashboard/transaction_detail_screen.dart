import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../core/api_constants.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  XFile? _selectedImage;
  Uint8List? _previewBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final trx = dash.transactions.firstWhere((t) => t.id == widget.transaction.id, orElse: () => widget.transaction);
    final sc  = AppColors.statusColor(trx.status);
    final sl  = AppColors.statusLabel(trx.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              // ── App Bar ───────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildSuccessBanner(trx),
                ),
                title: Text(
                  'Detail Pesanan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: 'Salin Invoice',
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: trx.invoiceCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invoice disalin!',
                              style: GoogleFonts.poppins(
                                  color: Colors.white)),
                          backgroundColor: AppColors.primaryGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // ── Invoice Info ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildSection(
                  child: _buildInvoiceInfo(trx, sc, sl),
                ),
              ),

              // ── Progress Tracker (Vertical Stepper) ────────────────────
              SliverToBoxAdapter(
                child: _buildSection(
                  title: 'Status Pengerjaan Cucian',
                  child: _buildProgressTracker(trx.status),
                ),
              ),

              // ── Delivery & Payment Info ───────────────────────────────
              SliverToBoxAdapter(
                child: _buildSection(
                  title: 'Informasi Pengiriman & Pembayaran',
                  child: _buildDeliveryInfo(trx),
                ),
              ),

              // ── Order Items ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildSection(
                  title: 'Daftar Layanan',
                  child: _buildItemList(trx),
                ),
              ),

              // ── Payment Summary ───────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildSection(
                  title: 'Ringkasan Pembayaran',
                  child: _buildPaymentSummary(trx),
                ),
              ),

              // ── Info note ─────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildInfoNote(trx)),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),

      // ── Floating Action Button (WhatsApp) ─────────────────────────────
      floatingActionButton: _buildWhatsAppFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // ── Bottom button ─────────────────────────────────────────────────
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ── Success Banner ────────────────────────────────────────────────────────
  Widget _buildSuccessBanner(TransactionModel trx) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 10),
            Text(
              'Detail Pesanan Aktif',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'No. Invoice: ${trx.invoiceCode}',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Invoice Info ──────────────────────────────────────────────────────────
  Widget _buildInvoiceInfo(
      TransactionModel trx, Color sc, String sl) {
    final date =
        '${trx.createdAt.day.toString().padLeft(2, '0')}/'
        '${trx.createdAt.month.toString().padLeft(2, '0')}/'
        '${trx.createdAt.year}  '
        '${trx.createdAt.hour.toString().padLeft(2, '0')}:'
        '${trx.createdAt.minute.toString().padLeft(2, '0')}';

    return Column(
      children: [
        _InfoRow(
          label: 'No. Invoice',
          value: trx.invoiceCode,
          valueStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const _Divider(),
        _InfoRow(
          label: 'Tanggal Masuk',
          value: date,
        ),
        const _Divider(),
        _InfoRow(
          label: 'Status Pesanan',
          valueWidget: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sc.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              sl,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: sc,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Progress Tracker (Stepper Vertikal Sesuai Alur) ───────────────────────
  static const _steps = [
    ('baru',    Icons.pending_actions_rounded,        'Menunggu', 'Pesanan masuk & menunggu antrean pengerjaan.'),
    ('cuci',    Icons.local_laundry_service_rounded,  'Dicuci',   'Pakaian sedang dalam proses pencucian & pembilasan.'),
    ('proses',  Icons.hourglass_empty_rounded,        'Diproses', 'Pakaian sedang dikeringkan atau sedang disetrika.'),
    ('selesai', Icons.check_circle_rounded,           'Selesai',  'Pakaian selesai disetrika, dipacking, & siap diambil.'),
    ('diambil', Icons.shopping_bag_rounded,            'Diambil',  'Pakaian telah diserahkan kembali kepada Anda.'),
  ];

  Widget _buildProgressTracker(String status) {
    int currentIdx;
    switch (status.toLowerCase()) {
      case 'baru':
        currentIdx = 0;
        break;
      case 'cuci':
        currentIdx = 1;
        break;
      case 'kering':
      case 'setrika':
        currentIdx = 2;
        break;
      case 'selesai':
        currentIdx = 3;
        break;
      case 'diambil':
        currentIdx = 4;
        break;
      default:
        currentIdx = 0;
    }

    return Column(
      children: List.generate(_steps.length, (i) {
        final isCompleted = i < currentIdx;
        final isActive = i == currentIdx;
        final isPending = i > currentIdx;
        final (_, icon, title, desc) = _steps[i];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primaryGreen.withOpacity(0.12)
                        : isActive
                            ? AppColors.primaryGreen
                            : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? AppColors.primaryGreen
                          : isCompleted
                              ? AppColors.primaryGreen.withOpacity(0.4)
                              : AppColors.cardBorder,
                      width: isActive ? 2.5 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primaryGreen.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isActive
                        ? Colors.white
                        : isCompleted
                            ? AppColors.primaryGreen
                            : Colors.grey.shade400,
                  ),
                ),
                if (i < _steps.length - 1)
                  Container(
                    width: 2,
                    height: 36,
                    color: isCompleted
                        ? AppColors.primaryGreen
                        : AppColors.cardBorder,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w800
                                : isCompleted
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                            color: isPending
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Saat ini',
                              style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isActive 
                            ? AppColors.textPrimary.withOpacity(0.8) 
                            : AppColors.textSecondary.withOpacity(0.8),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Delivery & Payment Info ───────────────────────────────────────────────
  Widget _buildDeliveryInfo(TransactionModel trx) {
    final String delivery = (trx.deliveryType == 'bawa_sendiri') ? 'Bawa Sendiri ke Toko' : 'Layanan Antar Jemput';
    final String payment = (trx.paymentMethod == 'transfer') ? 'Transfer Bank' : 'Tunai / COD (Cash)';

    return Column(
      children: [
        _InfoRow(label: 'Metode Pengiriman', value: delivery),
        const _Divider(),
        _InfoRow(label: 'Alamat Pengiriman', value: trx.address ?? '-'),
        const _Divider(),
        _InfoRow(label: 'Nomor Kontak', value: trx.phone ?? '-'),
        const _Divider(),
        _InfoRow(label: 'Metode Pembayaran', value: payment),
      ],
    );
  }

  // ── Item List ─────────────────────────────────────────────────────────────
  Widget _buildItemList(TransactionModel trx) {
    if (trx.details.isEmpty) {
      return Text('Tidak ada item.',
          style: GoogleFonts.poppins(
              color: AppColors.textSecondary, fontSize: 13));
    }
    return Column(
      children: trx.details.asMap().entries.map((entry) {
        final i = entry.key;
        final d = entry.value;
        
        final sub = d.subtotal.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
        final price = d.price.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
        
        final qty = d.service.unit == 'kg'
            ? '${d.quantity.toStringAsFixed(1)} ${d.service.unit}'
            : '${d.quantity.toInt()} ${d.service.unit}';

        return Column(
          children: [
            if (i > 0)
              Divider(
                  height: 20, thickness: 0.8, color: AppColors.cardBorder),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.service.icon,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.service.name,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Rp $price × $qty',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rp $sub',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Payment Summary ───────────────────────────────────────────────────────
  Widget _buildPaymentSummary(TransactionModel trx) {
    final subtotalPrice = trx.details.fold(0.0, (sum, d) => sum + d.subtotal);
    final deliveryFee = trx.deliveryType == 'antar_jemput' ? (trx.totalPrice - subtotalPrice > 0 ? trx.totalPrice - subtotalPrice : 10000.0) : 0.0;

    final formattedSubtotal = subtotalPrice.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
        
    final formattedDelivery = deliveryFee.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Column(
      children: [
        _InfoRow(label: 'Subtotal Layanan', value: 'Rp $formattedSubtotal'),
        const _Divider(),
        _InfoRow(
          label: 'Biaya Antar-Jemput', 
          value: trx.deliveryType == 'antar_jemput' ? 'Rp $formattedDelivery' : 'Gratis',
          valueStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: trx.deliveryType == 'antar_jemput' ? AppColors.accent : AppColors.primaryGreen,
          ),
        ),
        const _Divider(),
        _InfoRow(
          label: 'Total Tagihan',
          value: trx.formattedTotal,
          valueStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryGreen,
          ),
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _previewBytes = bytes;
      });
    }
  }

  Future<void> _uploadImage(int transactionId) async {
    if (_previewBytes == null || _selectedImage == null) return;
    setState(() {
      _isUploading = true;
    });

    final dash = context.read<DashboardProvider>();
    final err = await dash.uploadPaymentProof(
      transactionId: transactionId,
      bytes: _previewBytes!,
      filename: _selectedImage!.name,
    );

    if (!mounted) return;
    setState(() {
      _isUploading = false;
    });

    if (err == null) {
      setState(() {
        _selectedImage = null;
        _previewBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bukti pembayaran berhasil diunggah!',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunggah bukti: $err',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ── Info Note ─────────────────────────────────────────────────────────────
  Widget _buildInfoNote(TransactionModel trx) {
    if (trx.status != 'baru') return const SizedBox.shrink();

    final isTransfer = trx.paymentMethod == 'transfer';
    final hasProof = trx.paymentProofUrl != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isTransfer 
              ? (hasProof ? const Color(0xFFECFDF5) : AppColors.primaryLight) 
              : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isTransfer
                  ? (hasProof ? const Color(0xFFA7F3D0) : AppColors.primaryMid.withOpacity(0.3))
                  : Colors.amber.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isTransfer
                      ? (hasProof ? Icons.check_circle_rounded : Icons.account_balance_rounded)
                      : Icons.info_outline_rounded,
                  color: isTransfer
                      ? (hasProof ? const Color(0xFF059669) : AppColors.primaryGreen)
                      : Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  isTransfer
                      ? (hasProof ? 'Bukti Pembayaran Terunggah' : 'Instruksi Transfer')
                      : 'Pembayaran di Kasir',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isTransfer
                        ? (hasProof ? const Color(0xFF047857) : AppColors.primaryGreen)
                        : Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isTransfer) ...[
              if (hasProof) ...[
                Text(
                  'Bukti transfer Anda telah berhasil dikirim ke sistem. Silakan tunggu verifikasi oleh admin kami.',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ApiConstants.normalizeUrl(trx.paymentProofUrl)!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        color: Colors.grey.shade100,
                        alignment: Alignment.center,
                        child: Text(
                          'Gagal memuat gambar bukti transfer.',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Text(
                  'Silakan transfer ke rekening berikut:',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Bank_Central_Asia.svg/1200px-Bank_Central_Asia.svg.png',
                          width: 40,
                          height: 24,
                          errorBuilder: (_, __, ___) => const Icon(Icons.account_balance)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('1234567890',
                                style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            Text('a.n Rumah Laundry',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            size: 20, color: AppColors.primaryGreen),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: '1234567890'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Nomor rekening disalin!',
                                  style: GoogleFonts.poppins(color: Colors.white)),
                              backgroundColor: AppColors.primaryGreen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_previewBytes != null) ...[
                  Text(
                    'Pratinjau Bukti Transfer:',
                    style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _previewBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isUploading ? null : () {
                            setState(() {
                              _selectedImage = null;
                              _previewBytes = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Batal', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : () => _uploadImage(trx.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text('Unggah Sekarang', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_file_rounded, size: 18, color: Colors.white),
                      label: Text(
                        'Pilih & Unggah Bukti Transfer',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ] else ...[
              Text(
                'Harap lakukan pembayaran tunai di kasir terdekat atau kepada kurir kami saat penjemputan pakaian. '
                'Tunjukkan nomor invoice di atas kepada petugas.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.amber.shade900,
                  height: 1.5,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // ── WhatsApp FAB ──────────────────────────────────────────────────────────
  Widget _buildWhatsAppFab() {
    return FloatingActionButton.extended(
      onPressed: _openWhatsApp,
      backgroundColor: const Color(0xFF25D366), // WhatsApp Green
      icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
      label: Text(
        'Chat CS',
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final invoice = widget.transaction.invoiceCode;
    final message = 'Halo Admin Rumah Laundry, saya ingin konfirmasi pesanan dengan nomor invoice *$invoice*.';
    final url = Uri.parse('https://wa.me/6281223513917?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka WhatsApp.',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Section wrapper ───────────────────────────────────────────────────────
  Widget _buildSection({String? title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.home_rounded, size: 20),
            label: Text(
              'Kembali ke Beranda',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () {
              // Bersihkan stack dan arahkan ke halaman utama /home (DashboardShell)
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/home', (route) => false);
            },
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String      label;
  final String?     value;
  final Widget?     valueWidget;
  final TextStyle?  labelStyle;
  final TextStyle?  valueStyle;

  const _InfoRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: labelStyle ??
              GoogleFonts.poppins(
                  fontSize: 12.5, color: AppColors.textSecondary),
        ),
        valueWidget ??
            Text(
              value ?? '',
              style: valueStyle ??
                  GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Divider(height: 18, thickness: 0.8, color: AppColors.cardBorder);
}

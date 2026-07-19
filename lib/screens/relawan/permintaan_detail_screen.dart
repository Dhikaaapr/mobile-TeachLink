import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PermintaanDetailScreen extends StatefulWidget {
  final String requestId;

  const PermintaanDetailScreen({super.key, required this.requestId});

  @override
  State<PermintaanDetailScreen> createState() => _PermintaanDetailScreenState();
}

class _PermintaanDetailScreenState extends State<PermintaanDetailScreen> {
  bool _isProcessing = false;

  static const _primaryGreen = Color(0xFF2E9E5B);

  Future<void> _rejectRequest(Map<String, dynamic> requestData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await _confirmDialog(
      title: 'Tolak Request?',
      message: 'Request ini akan ditolak dan tidak bisa diproses ulang.',
      confirmLabel: 'Ya, Tolak',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).update({
        'status': 'rejected',
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedBy': user.uid,
      });
      if (!mounted) return;
      _showSnack('Request berhasil ditolak.', Colors.redAccent);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal menolak request: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> requestData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final scheduleId = (requestData['scheduleId'] as String?)?.trim();
    final siswaId = (requestData['siswaId'] as String?)?.trim();
    if (scheduleId == null || scheduleId.isEmpty || siswaId == null || siswaId.isEmpty) {
      _showSnack('Data request tidak lengkap.', Colors.redAccent);
      return;
    }

    final confirm = await _confirmDialog(
      title: 'Terima Request?',
      message: 'Sesi belajar akan dibuat dan jadwal ini tidak bisa diambil siswa lain.',
      confirmLabel: 'Ya, Terima',
      confirmColor: _primaryGreen,
    );
    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final requestRef = FirebaseFirestore.instance.collection('requests').doc(widget.requestId);
      final scheduleRef = FirebaseFirestore.instance.collection('schedules').doc(scheduleId);
      final sessionRef = FirebaseFirestore.instance.collection('sessions').doc('${scheduleId}_$siswaId');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final requestSnap = await transaction.get(requestRef);
        if (!requestSnap.exists) {
          throw Exception('Request tidak ditemukan.');
        }

        final requestMap = requestSnap.data() as Map<String, dynamic>;
        if ((requestMap['status'] as String?) != 'pending') {
          throw Exception('Request sudah diproses sebelumnya.');
        }

        final scheduleSnap = await transaction.get(scheduleRef);
        if (!scheduleSnap.exists) {
          throw Exception('Jadwal tidak ditemukan.');
        }

        final scheduleMap = scheduleSnap.data() as Map<String, dynamic>;
        final bookingState = (scheduleMap['bookingState'] as String?) ?? 'open';
        if (bookingState != 'open') {
          throw Exception('Jadwal sudah tidak tersedia.');
        }

        transaction.update(requestRef, {
          'status': 'accepted',
          'decidedAt': FieldValue.serverTimestamp(),
          'decidedBy': user.uid,
        });

        transaction.update(scheduleRef, {
          'bookingState': 'confirmed',
          'selectedRequestId': widget.requestId,
          'selectedSiswaId': siswaId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(sessionRef, {
          'scheduleId': scheduleId,
          'requestId': widget.requestId,
          'relawanId': requestMap['relawanId'],
          'relawanName': requestMap['relawanName'],
          'siswaId': siswaId,
          'siswaName': requestMap['siswaName'],
          'mataPelajaran': scheduleMap['mataPelajaran'] ?? requestMap['mapel'],
          'mode': scheduleMap['mode'] ?? requestMap['mode'],
          'detail': scheduleMap['detail'] ?? requestMap['detail'],
          'startAt': scheduleMap['startAt'] ?? requestMap['startAt'],
          'endAt': scheduleMap['endAt'] ?? requestMap['endAt'],
          'status': 'upcoming',
          'acceptedAt': FieldValue.serverTimestamp(),
          'completedAt': null,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
        transaction.set(notifRef, {
          'userId': siswaId,
          'judul': 'Permintaan Belajar Diterima',
          'isi': 'Relawan ${requestMap['relawanName'] ?? "Relawan"} menerima permintaan belajar Anda untuk mata pelajaran ${scheduleMap['mataPelajaran'] ?? requestMap['mapel'] ?? ""}.',
          'category': 'success',
          'createdAt': FieldValue.serverTimestamp(),
          'dibaca': false,
        });
      });

      // Otomatis tolak request pending lain untuk jadwal yang sama.
      final pendingOthers = await FirebaseFirestore.instance
          .collection('requests')
          .where('scheduleId', isEqualTo: scheduleId)
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in pendingOthers.docs) {
        if (doc.id == widget.requestId) continue;
        batch.update(doc.reference, {
          'status': 'rejected',
          'decidedAt': FieldValue.serverTimestamp(),
          'decidedBy': user.uid,
          'rejectedReason': 'Jadwal sudah diambil siswa lain.',
        });
      }
      await batch.commit();

      if (!mounted) return;
      _showSnack('Request di-accept. Sesi belajar berhasil dibuat.', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal menerima request: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestRef = FirebaseFirestore.instance.collection('requests').doc(widget.requestId);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Detail Permintaan', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0.5,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: requestRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat detail: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _primaryGreen));
          }

          final data = snapshot.data?.data();
          if (data == null) {
            return const Center(child: Text('Permintaan tidak ditemukan.'));
          }

          final status = (data['status'] as String?) ?? 'pending';
          final statusView = _statusView(status);
          final siswaName = (data['siswaName'] as String?) ?? '-';

          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, status == 'pending' ? 120 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Kartu profil siswa + status ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: _primaryGreen.withValues(alpha: 0.12),
                            child: Text(
                              siswaName.isNotEmpty ? siswaName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: _primaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            siswaName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                            decoration: BoxDecoration(
                              color: statusView.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusView.icon, size: 14, color: statusView.color),
                                const SizedBox(width: 6),
                                Text(
                                  statusView.label,
                                  style: TextStyle(
                                    color: statusView.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Kartu informasi detail ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Permintaan',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(Icons.menu_book_rounded, 'Mapel', (data['mapel'] as String?) ?? '-'),
                          const SizedBox(height: 16),
                          _buildWaktuRow(data['startAt'], data['endAt']),
                          const SizedBox(height: 16),
                          _buildDetailRow(Icons.laptop_mac_rounded, 'Mode', (data['mode'] as String?) ?? '-'),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            Icons.notes_rounded,
                            'Catatan',
                            (data['catatanSiswa'] as String?)?.trim().isNotEmpty == true
                                ? data['catatanSiswa'] as String
                                : '-',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- Tombol aksi mengambang di bawah ---
              if (status == 'pending')
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing ? null : () => _rejectRequest(data),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Tolak'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : () => _acceptRequest(data),
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_rounded, size: 18),
                            label: Text(_isProcessing ? 'Memproses...' : 'Terima Request'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: _primaryGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaktuRow(dynamic startAt, dynamic endAt) {
    final hasValidTime = startAt is Timestamp && endAt is Timestamp;
    final tanggal = hasValidTime ? _formatTanggal(startAt) : '-';
    final jam = hasValidTime ? _formatJam(startAt, endAt) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.schedule_rounded, size: 16, color: _primaryGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Waktu',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                tanggal,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.4),
              ),
              if (jam != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[700]),
                      const SizedBox(width: 5),
                      Text(
                        jam,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  _StatusView _statusView(String status) {
    switch (status) {
      case 'accepted':
        return const _StatusView(label: 'Accepted', color: Colors.green, icon: Icons.check_circle_rounded);
      case 'rejected':
        return const _StatusView(label: 'Rejected', color: Colors.red, icon: Icons.cancel_rounded);
      case 'cancelled':
        return const _StatusView(label: 'Cancelled', color: Colors.grey, icon: Icons.block_rounded);
      default:
        return const _StatusView(label: 'Menunggu Konfirmasi', color: Colors.orange, icon: Icons.hourglass_top_rounded);
    }
  }

  String _formatTanggal(Timestamp startAt) {
    final start = startAt.toDate();
    return '${_hariIndonesia(start.weekday)}, ${_dua(start.day)}/${_dua(start.month)}/${start.year}';
  }

  String _formatJam(Timestamp startAt, Timestamp endAt) {
    final start = startAt.toDate();
    final end = endAt.toDate();
    return '${_dua(start.hour)}:${_dua(start.minute)} - ${_dua(end.hour)}:${_dua(end.minute)}';
  }

  String _dua(int value) => value.toString().padLeft(2, '0');

  String _hariIndonesia(int weekday) {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return hari[(weekday - 1).clamp(0, 6)];
  }
}

class _StatusView {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusView({required this.label, required this.color, required this.icon});
}
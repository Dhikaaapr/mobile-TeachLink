import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestBelajarScreen extends StatefulWidget {
  final String scheduleId;
  final Map<String, dynamic> scheduleData;

  const RequestBelajarScreen({
    super.key,
    required this.scheduleId,
    required this.scheduleData,
  });

  @override
  State<RequestBelajarScreen> createState() => _RequestBelajarScreenState();
}

class _RequestBelajarScreenState extends State<RequestBelajarScreen> {
  bool _isSubmitting = false;
  final _catatanController = TextEditingController();

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _kirimPermintaan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login sebagai siswa terlebih dahulu'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final relawanId = (widget.scheduleData['ownerRelawanId'] as String?)?.trim();
    if (relawanId == null || relawanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data jadwal tidak valid: relawan tidak ditemukan'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (relawanId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak bisa mengajukan request ke jadwal milik sendiri'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final requestId = '${widget.scheduleId}_${user.uid}';

    setState(() {
      _isSubmitting = true;
    });

    try {
      final siswaDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final siswaName = (siswaDoc.data()?['nama'] as String?)?.trim();

      final requestRef = FirebaseFirestore.instance.collection('requests').doc(requestId);
      final existing = await requestRef.get();

      if (existing.exists) {
        final oldStatus = (existing.data()?['status'] as String?) ?? 'pending';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anda sudah pernah mengirim request untuk jadwal ini (status: $oldStatus).'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await requestRef.set({
        'scheduleId': widget.scheduleId,
        'relawanId': relawanId,
        'relawanName': widget.scheduleData['ownerRelawanName'] ?? 'Relawan',
        'siswaId': user.uid,
        'siswaName': siswaName?.isNotEmpty == true ? siswaName : 'Siswa',
        'mapel': widget.scheduleData['mataPelajaran'],
        'startAt': widget.scheduleData['startAt'],
        'endAt': widget.scheduleData['endAt'],
        'mode': widget.scheduleData['mode'],
        'detail': widget.scheduleData['detail'],
        'status': 'pending',
        'catatanSiswa': _catatanController.text.trim(),
        'requestedAt': FieldValue.serverTimestamp(),
        'decidedAt': null,
        'decidedBy': null,
      });

      // Tambahkan notifikasi untuk relawan
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': relawanId,
        'judul': 'Permintaan Belajar Baru',
        'isi': 'Siswa ${siswaName?.isNotEmpty == true ? siswaName : "Siswa"} mengajukan permintaan belajar untuk mata pelajaran ${widget.scheduleData['mataPelajaran'] ?? ""}.',
        'category': 'request',
        'createdAt': FieldValue.serverTimestamp(),
        'dibaca': false,
      });

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text('Permintaan Terkirim!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Request belajar Anda sudah dikirim ke relawan pemilik jadwal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim request: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kirim Permintaan Belajar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Relawan info header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    child: const Icon(Icons.person, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.scheduleData['ownerRelawanName'] ?? 'Relawan',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(widget.scheduleData['mataPelajaran'] ?? '-',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.schedule, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(_formatWaktuRingkas(widget.scheduleData['startAt']),
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.scheduleData['ownerRelawanId'])
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final bio = userData['bio'] ?? 'Belum ada informasi bio';
                final pekerjaan = userData['pekerjaan'] ?? '-';
                final keahlian = userData['keahlian'] ?? '-';
                final lokasi = userData['lokasi'] ?? '-';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tentang Relawan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bio,
                            style: const TextStyle(color: Colors.black87, height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.work, 'Pekerjaan', pekerjaan),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.workspace_premium, 'Keahlian', keahlian),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.location_on, 'Lokasi', lokasi),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            const Text('Detail Permintaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            TextFormField(
              initialValue: widget.scheduleData['mataPelajaran']?.toString() ?? '-',
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Mata Pelajaran',
                prefixIcon: const Icon(Icons.menu_book),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              initialValue: _formatWaktuLengkap(widget.scheduleData['startAt'], widget.scheduleData['endAt']),
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Jadwal',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Catatan
            TextField(
              controller: _catatanController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Catatan / Pesan untuk Relawan',
                hintText: 'Contoh: Saya kesulitan di bab pecahan, butuh bimbingan 2x seminggu...',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _kirimPermintaan,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSubmitting ? 'Mengirim...' : 'Kirim Permintaan',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatWaktuRingkas(dynamic timestamp) {
    if (timestamp is! Timestamp) return '-';
    final date = timestamp.toDate();
    return '${_dua(date.day)}/${_dua(date.month)}/${date.year} ${_dua(date.hour)}:${_dua(date.minute)}';
  }

  String _formatWaktuLengkap(dynamic startAt, dynamic endAt) {
    if (startAt is! Timestamp || endAt is! Timestamp) return '-';
    final start = startAt.toDate();
    final end = endAt.toDate();
    return '${_hariIndonesia(start.weekday)}, ${start.day}/${start.month}/${start.year} ${_dua(start.hour)}:${_dua(start.minute)} - ${_dua(end.hour)}:${_dua(end.minute)}';
  }

  String _dua(int value) => value.toString().padLeft(2, '0');

  String _hariIndonesia(int weekday) {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return hari[(weekday - 1).clamp(0, 6)];
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.black54)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'jadwal_form_screen.dart';

class DraftJadwalScreen extends StatelessWidget {
  const DraftJadwalScreen({super.key});

  Future<void> _hapusJadwal(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Jadwal?'),
        content: const Text(
          'Draft jadwal ini akan dihapus secara permanen dan tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('schedules')
          .doc(docId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Jadwal berhasil dihapus'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus jadwal: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _editJadwal(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JadwalFormScreen(
          docId: docId,
          initialData: data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Draft Jadwal'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Silakan login untuk melihat draft jadwal.',
                style: TextStyle(fontSize: 14.5),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                .collection('schedules')
                .where('ownerRelawanId', isEqualTo: user.uid)
                .where('draftState', isEqualTo: 'draft')
                .where('bookingState', isEqualTo: 'open')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat draft: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                docs.sort((a, b) {
                  final aDate =
                      (a.data()['tanggal'] as Timestamp?)?.toDate() ?? DateTime(2100);
                  final bDate =
                      (b.data()['tanggal'] as Timestamp?)?.toDate() ?? DateTime(2100);
                  return aDate.compareTo(bDate);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada draft jadwal.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final tanggal =
                        (data['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final jamMulai = (data['jamMulai'] as String?) ?? '-';
                    final jamSelesai = (data['jamSelesai'] as String?) ?? '-';
                    final mode = (data['mode'] as String?) ?? '-';
                    final detail = mode == 'Online'
                        ? (data['link'] as String?)
                        : (data['lokasi'] as String?);

                    return DraftJadwalCard(
                      tanggal: _formatTanggalIndonesia(tanggal),
                      waktu: '$jamMulai - $jamSelesai',
                      mapel: (data['mataPelajaran'] as String?) ?? '-',
                      mode: mode,
                      detail: (detail == null || detail.trim().isEmpty) ? '-' : detail,
                      onEdit: () => _editJadwal(context, doc.id, data),
                      onDelete: () => _hapusJadwal(context, doc.id),
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatTanggalIndonesia(DateTime date) {
    const namaHari = <String>[
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    const namaBulan = <String>[
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final hari = namaHari[date.weekday - 1];
    return '$hari, ${date.day} ${namaBulan[date.month]} ${date.year}';
  }
}

class DraftJadwalCard extends StatelessWidget {
  final String tanggal;
  final String waktu;
  final String mapel;
  final String mode;
  final String detail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DraftJadwalCard({
    super.key,
    required this.tanggal,
    required this.waktu,
    required this.mapel,
    required this.mode,
    required this.detail,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  tanggal,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF4E3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Draft',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF8A8F98)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'hapus') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 19, color: Color(0xFF4F46E5)),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'hapus',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 19, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text('Hapus'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.access_time, size: 20, color: Color(0xFF8A8F98)),
              const SizedBox(width: 8),
              Text(
                waktu,
                style: const TextStyle(fontSize: 15.5, color: Color(0xFF5F6368)),
              ),
              const SizedBox(width: 18),
              const Icon(Icons.menu_book_outlined, size: 20, color: Color(0xFF8A8F98)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mapel,
                  style: const TextStyle(fontSize: 15.5, color: Color(0xFF5F6368)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                mode == 'Online' ? Icons.videocam_outlined : Icons.location_on_outlined,
                size: 20,
                color: const Color(0xFF8A8F98),
              ),
              const SizedBox(width: 8),
              Text(
                mode,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF45484D),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFB4B8C0),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detail,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF6B6F76)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
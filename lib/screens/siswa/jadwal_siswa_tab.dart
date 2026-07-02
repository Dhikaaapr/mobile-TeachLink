import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/session_edit_screen.dart';

class JadwalSiswaTab extends StatelessWidget {
  const JadwalSiswaTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Jadwal Belajar"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Silakan login untuk melihat jadwal.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .where('siswaId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Gagal memuat jadwal: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                
                docs.sort((a, b) {
                  final aStart = a.data()['startAt'];
                  final bStart = b.data()['startAt'];
                  final aDate = aStart is Timestamp ? aStart.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate = bStart is Timestamp ? bStart.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  return aDate.compareTo(bDate);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada jadwal belajar.\nRequest yang di-approve relawan akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    return _buildJadwalCard(context, data);
                  },
                );
              },
            ),
    );
  }

  Widget _buildJadwalCard(BuildContext context, Map<String, dynamic> data) {
    final status = (data['status'] as String?) ?? 'upcoming';
    final Color statusColor = status == 'completed'
        ? Colors.grey
        : status == 'ongoing'
            ? Colors.blue
            : Colors.green;
    
    final String statusLabel = status == 'completed'
        ? 'Selesai'
        : status == 'ongoing'
            ? 'Sedang Berlangsung'
            : 'Akan Datang';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (data['mataPelajaran'] as String?) ?? '-',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.person,
                    size: 18,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Relawan: ${(data['relawanName'] as String?) ?? 'Relawan'}',
                    style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatWaktu(data['startAt'], data['endAt']),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.laptop, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  '${data['mode'] ?? '-'}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                if ((data['detail'] as String?)?.trim().isNotEmpty == true) ...[
                  const Text(' • ', style: TextStyle(color: Colors.black54)),
                  Expanded(
                    child: Text(
                      data['detail'] as String,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (data['acceptedAt'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Di-approve: ${_formatTanggal(data['acceptedAt'])}',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }

  String _formatWaktu(dynamic startAt, dynamic endAt) {
    if (startAt is! Timestamp || endAt is! Timestamp) return '-';
    final start = startAt.toDate();
    final end = endAt.toDate();
    return '${_hariIndonesia(start.weekday)}, ${_dua(start.day)}/${_dua(start.month)}/${start.year} ${_dua(start.hour)}:${_dua(start.minute)} - ${_dua(end.hour)}:${_dua(end.minute)}';
  }

  String _formatTanggal(dynamic timestamp) {
    if (timestamp is! Timestamp) return '-';
    final date = timestamp.toDate();
    return '${_dua(date.day)}/${_dua(date.month)}/${date.year}';
  }

  String _dua(int value) => value.toString().padLeft(2, '0');

  String _hariIndonesia(int weekday) {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return hari[(weekday - 1).clamp(0, 6)];
  }
}
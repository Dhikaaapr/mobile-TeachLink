import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'jadwal_form_screen.dart';
import '../common/session_edit_screen.dart';

class JadwalRelawanTab extends StatelessWidget {
  const JadwalRelawanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Jadwal Mengajar"),
      ),

      body: _buildBody(context),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Tambah Jadwal",
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const JadwalFormScreen(),
            ),
          );

          if (saved == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Jadwal berhasil dibuat dan dipublikasikan.'),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Silakan login kembali.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('relawanId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'upcoming')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat jadwal: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs.toList() ?? [];
        final now = DateTime.now();

        // Filter data: hanya tampilkan yang belum berakhir
        final docs = allDocs.where((doc) {
          final data = doc.data();
          final endAt = data['endAt'];
          final hasEnded = endAt is Timestamp && endAt.toDate().isBefore(now);
          return !hasEnded;
        }).toList();

        docs.sort((a, b) {
          final aStart = a.data()['startAt'];
          final bStart = b.data()['startAt'];
          final aDate = aStart is Timestamp ? aStart.toDate() : DateTime(2100);
          final bDate = bStart is Timestamp ? bStart.toDate() : DateTime(2100);
          return aDate.compareTo(bDate);
        });

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada jadwal fix.\nTerima request siswa terlebih dahulu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return _buildSessionCard(context, doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    String sessionId,
    Map<String, dynamic> data,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                    'Siswa: ${(data['siswaName'] as String?) ?? '-'}',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.laptop, size: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: '${data['mode'] ?? '-'}',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                      children: [
                        if ((data['detail'] as String?)?.trim().isNotEmpty == true)
                          TextSpan(
                            text: ' • ${data['detail']}',
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SessionEditScreen(
                            sessionId: sessionId,
                            sessionData: data,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    label: const Text('Edit Jadwal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  String _formatTanggal(dynamic timestamp) {
    if (timestamp is! Timestamp) return '-';
    final date = timestamp.toDate();
    return '${_dua(date.day)}/${_dua(date.month)}/${date.year}';
  }

  String _formatWaktu(dynamic startAt, dynamic endAt) {
    if (startAt is! Timestamp || endAt is! Timestamp) return '-';
    final start = startAt.toDate();
    final end = endAt.toDate();
    return '${_hariIndonesia(start.weekday)}, ${_dua(start.day)}/${_dua(start.month)}/${start.year} ${_dua(start.hour)}:${_dua(start.minute)} - ${_dua(end.hour)}:${_dua(end.minute)}';
  }

  String _dua(int value) => value.toString().padLeft(2, '0');

  String _hariIndonesia(int weekday) {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return hari[(weekday - 1).clamp(0, 6)];
  }
}
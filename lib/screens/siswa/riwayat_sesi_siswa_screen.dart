import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RiwayatSesiSiswaScreen extends StatelessWidget {
  const RiwayatSesiSiswaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Riwayat Sesi Belajar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildRiwayatBody(),
    );
  }

  Widget _buildRiwayatBody() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Silakan login kembali.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('siswaId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat riwayat: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        final now = DateTime.now();
        final docs = allDocs.where((doc) {
          final data = doc.data();
          final status = (data['status'] as String?) ?? 'upcoming';
          final endAt = data['endAt'];
          
          final hasEnded = endAt is Timestamp && endAt.toDate().isBefore(now);
          
          return status == 'completed' || status == 'cancelled' || hasEnded;
        }).toList();

        docs.sort((a, b) {
          final aStart = a.data()['startAt'];
          final bStart = b.data()['startAt'];
          final aDate = aStart is Timestamp ? aStart.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = bStart is Timestamp ? bStart.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

        if (docs.isEmpty) {
          return const Center(child: Text('Belum ada riwayat sesi.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final status = (data['status'] as String?) ?? 'completed';
            final isCompleted = status == 'completed';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCompleted ? Colors.blue[50] : Colors.orange[50],
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.cancel,
                    color: isCompleted ? Colors.blue : Colors.orange,
                  ),
                ),
                title: Text((data['mataPelajaran'] as String?) ?? '-'),
                subtitle: Text(
                  '${_formatWaktu(data['startAt'], data['endAt'])}\nRelawan: ${(data['relawanName'] as String?) ?? '-'}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  String _formatWaktu(dynamic startAt, dynamic endAt) {
    if (startAt is! Timestamp || endAt is! Timestamp) return '-';
    final start = startAt.toDate();
    final end = endAt.toDate();
    return '${_dua(start.day)}/${_dua(start.month)}/${start.year} ${_dua(start.hour)}:${_dua(start.minute)} - ${_dua(end.hour)}:${_dua(end.minute)}';
  }

  String _dua(int value) => value.toString().padLeft(2, '0');
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifikasi_siswa_screen.dart';
import 'request_belajar_screen.dart';

class _RelawanPreview {
  final String id;
  final String nama;
  final String keahlian;
  final Timestamp? createdAt;

  const _RelawanPreview({
    required this.id,
    required this.nama,
    required this.keahlian,
    required this.createdAt,
  });
}

class HomeTabSiswa extends StatelessWidget {
  const HomeTabSiswa({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotifikasiSiswaScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: user == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Text('Silakan login ulang untuk melihat dashboard.'),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGreetingCard(user.uid),
                  const SizedBox(height: 20),
                  _buildStatsSection(user.uid),
                  const SizedBox(height: 20),
                  const Text('Relawan Rekomendasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRelawanRekomendasi(context),
                  const SizedBox(height: 20),
                  const Text('Jadwal Belajar Mendatang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildUpcomingSessions(user.uid),
                ],
              ),
      ),
    );
  }

  Widget _buildGreetingCard(String uid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final nama = (snapshot.data?.data()?['nama'] as String?)?.trim();
        final namaTampil = nama?.isNotEmpty == true ? nama! : 'Siswa';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    child: const Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang,',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                      ),
                      Text(
                        '$namaTampil 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Tetap semangat belajar hari ini!',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('sessions').where('siswaId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final assignedSessions = docs.where((doc) {
          final data = doc.data();
          final relawanId = (data['relawanId'] as String?)?.trim() ?? '';
          return relawanId.isNotEmpty;
        }).toList();

        final totalSesi = assignedSessions.length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Sesi',
                value: '$totalSesi',
                icon: Icons.menu_book,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('schedules')
                    .where('publishState', isEqualTo: 'published')
                    .where('bookingState', isEqualTo: 'open')
                    .snapshots(),
                builder: (context, scheduleSnapshot) {
                  int availableCount = 0;
                  if (scheduleSnapshot.hasData) {
                    final now = DateTime.now();
                    availableCount = scheduleSnapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final startAt = data['startAt'];
                      if (startAt is! Timestamp) return false;
                      return startAt.toDate().isAfter(now);
                    }).length;
                  }
                  return _buildStatCard(
                    title: 'Jadwal Tersedia',
                    value: '$availableCount',
                    icon: Icons.timer,
                    color: Colors.green,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRelawanRekomendasi(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('schedules')
          .where('publishState', isEqualTo: 'published')
          .where('bookingState', isEqualTo: 'open')
          .snapshots(),
      builder: (context, scheduleSnapshot) {
        if (scheduleSnapshot.hasError) {
          return Text('Gagal memuat relawan: ${scheduleSnapshot.error}');
        }

        if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final now = DateTime.now();
        final relawanIds = <String>{};
        for (final doc in scheduleSnapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
          final data = doc.data();
          final startAt = data['startAt'];
          if (startAt is! Timestamp || !startAt.toDate().isAfter(now)) {
            continue;
          }

          final relawanId = (data['ownerRelawanId'] as String?)?.trim() ?? '';
          if (relawanId.isNotEmpty) {
            relawanIds.add(relawanId);
          }
        }

        if (relawanIds.isEmpty) {
          return const SizedBox(
            height: 90,
            child: Center(child: Text('Belum ada relawan tersedia saat ini.')),
          );
        }

        return FutureBuilder<List<_RelawanPreview>>(
          future: _loadRelawanPreviews(relawanIds.toList()),
          builder: (context, relawanSnapshot) {
            if (relawanSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (relawanSnapshot.hasError) {
              return Text('Gagal memuat profil relawan: ${relawanSnapshot.error}');
            }

            final relawanList = relawanSnapshot.data ?? [];
            if (relawanList.isEmpty) {
              return const SizedBox(
                height: 90,
                child: Center(child: Text('Data relawan belum tersedia.')),
              );
            }

            return SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: relawanList.length,
                itemBuilder: (context, index) {
                  final relawan = relawanList[index];
                  return GestureDetector(
                    onTap: () => _navigateToRequestFromRecommendation(context, relawan.id, relawan.nama),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue[100],
                            child: const Icon(Icons.person, color: Colors.blue, size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            relawan.nama.split(' ').first,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            relawan.keahlian.split(',').first.trim(),
                            style: const TextStyle(color: Colors.black54, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToRequestFromRecommendation(BuildContext context, String relawanId, String relawanName) async {
    final schedulesQuery = await FirebaseFirestore.instance
        .collection('schedules')
        .where('ownerRelawanId', isEqualTo: relawanId)
        .where('publishState', isEqualTo: 'published')
        .where('bookingState', isEqualTo: 'open')
        .limit(1)
        .get();
    
    if (schedulesQuery.docs.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relawan ini belum memiliki jadwal tersedia')),
      );
      return;
    }
    
    final scheduleDoc = schedulesQuery.docs.first;
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestBelajarScreen(
          scheduleId: scheduleDoc.id,
          scheduleData: scheduleDoc.data(),
        ),
      ),
    );
  }

  Future<List<_RelawanPreview>> _loadRelawanPreviews(List<String> relawanIds) async {
    final futures = relawanIds.map((id) => FirebaseFirestore.instance.collection('users').doc(id).get());
    final snapshots = await Future.wait(futures);

    final result = <_RelawanPreview>[];

    for (final snapshot in snapshots) {
      if (!snapshot.exists) {
        continue;
      }

      final data = snapshot.data();
      if (data == null) {
        continue;
      }

      final nama = (data['nama'] as String?)?.trim();
      final keahlian = (data['keahlian'] as String?)?.trim();
      result.add(
        _RelawanPreview(
          id: snapshot.id,
          nama: nama?.isNotEmpty == true ? nama! : 'Relawan',
          keahlian: keahlian?.isNotEmpty == true ? keahlian! : '-',
          createdAt: data['createdAt'] as Timestamp?,
        ),
      );
    }

    result.sort((a, b) {
      final aMillis = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bMillis = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bMillis.compareTo(aMillis);
    });

    return result.take(5).toList();
  }

  Widget _buildUpcomingSessions(String uid) {

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('sessions').where('siswaId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Gagal memuat sesi: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final todayWeekday = now.weekday;
        final docs = (snapshot.data?.docs.toList() ?? []).where((doc) {
          final data = doc.data();
          final relawanId = (data['relawanId'] as String?)?.trim() ?? '';
          final startAt = data['startAt'];
          final status = (data['status'] as String?)?.toLowerCase() ?? '';

          if (relawanId.isEmpty || startAt is! Timestamp) {
            return false;
          }

          final start = startAt.toDate();
          final isAssigned = status == 'upcoming' || status == 'ongoing' || status == 'assigned' || status == 'accepted';
          return isAssigned && start.weekday == todayWeekday;
        }).toList();

        docs.sort((a, b) {
          final aStart = a.data()['startAt'];
          final bStart = b.data()['startAt'];
          final aDate = aStart is Timestamp ? aStart.toDate() : DateTime(2100);
          final bDate = bStart is Timestamp ? bStart.toDate() : DateTime(2100);
          return aDate.compareTo(bDate);
        });

        if (docs.isEmpty) {
          return const Card(
            child: ListTile(
              title: Text('Belum ada jadwal untuk hari ini.'),
              subtitle: Text('Jadwal akan tampil sesuai hari berjalan dan sudah memiliki relawan.'),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: const Icon(Icons.menu_book, color: Colors.blue),
                ),
                title: Text((data['mataPelajaran'] as String?) ?? 'Sesi Belajar'),
                subtitle: Text(_formatWaktu(data['startAt'], data['endAt'])),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {},
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatWaktu(dynamic startAt, dynamic endAt) {
    if (startAt is! Timestamp || endAt is! Timestamp) return '-';
    final start = startAt.toDate();
    final end = endAt.toDate();
    return '${_hariIndonesia(start.weekday)}, ${_dua(start.day)}/${_dua(start.month)} ${_dua(start.hour)}:${_dua(start.minute)} - ${_dua(end.hour)}:${_dua(end.minute)}';
  }

  String _dua(int value) => value.toString().padLeft(2, '0');

  String _hariIndonesia(int weekday) {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return hari[(weekday - 1).clamp(0, 6)];
  }
}

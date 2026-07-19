import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifikasi_relawan_screen.dart';
import 'permintaan_relawan_tab.dart';

class HomeTabRelawan extends StatefulWidget {
  const HomeTabRelawan({super.key});

  @override
  State<HomeTabRelawan> createState() => _HomeTabRelawanState();
}

class _HomeTabRelawanState extends State<HomeTabRelawan> {
  String _namaUser = 'Relawan';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _namaUser = doc.get('nama') ?? 'Relawan';
        });
      }
    }
  }  @override
  Widget build(BuildContext context) {
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
              MaterialPageRoute(builder: (_) => const NotifikasiRelawanScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
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
                            '$_namaUser 👋',
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Terima kasih sudah menjadi relawan!',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('sessions')
                        .where('relawanId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int uniqueStudents = 0;
                      if (snapshot.hasData) {
                        final siswaIds = <String>{};
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final siswaId = data['siswaId'];
                          if (siswaId != null) {
                            siswaIds.add(siswaId);
                          }
                        }
                        uniqueStudents = siswaIds.length;
                      }
                      return _buildStatCard(
                        title: 'Total Siswa',
                        value: '$uniqueStudents',
                        icon: Icons.people,
                        color: Colors.blue,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('requests')
                        .where('relawanId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final requestCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildStatCard(
                        title: 'Total Request',
                        value: '$requestCount',
                        icon: Icons.timer,
                        color: Colors.green,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Sesi Hari Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .where('relawanId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('status', isEqualTo: 'upcoming')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final now = DateTime.now();
                final currentWeekday = now.weekday;
                
                final todaySessions = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final startAt = data['startAt'];
                  if (startAt is! Timestamp) return false;
                  
                  final startDate = startAt.toDate();
                  if (startDate.isBefore(now)) return false;
                  if (startDate.weekday != currentWeekday) return false;
                  
                  return true;
                }).toList();

                todaySessions.sort((a, b) {
                  final aStart = (a.data() as Map<String, dynamic>)['startAt'] as Timestamp;
                  final bStart = (b.data() as Map<String, dynamic>)['startAt'] as Timestamp;
                  return aStart.toDate().compareTo(bStart.toDate());
                });

                final limitedSessions = todaySessions.take(2).toList();

                if (limitedSessions.isEmpty) {
                  return const Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('Tidak ada sesi hari ini', style: TextStyle(color: Colors.black54)),
                      ),
                    ),
                  );
                }

                return Column(
                  children: limitedSessions.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final startAt = data['startAt'] as Timestamp?;
                    final endAt = data['endAt'] as Timestamp?;
                    
                    String waktu = '-';
                    if (startAt != null && endAt != null) {
                      final start = startAt.toDate();
                      final end = endAt.toDate();
                      waktu = '${_dua(start.hour)}:${_dua(start.minute)} - ${_dua(end.hour)}:${_dua(end.minute)}';
                    }

                    return _buildSesiCard(
                      mapel: data['mataPelajaran'] ?? '-',
                      waktu: waktu,
                      siswa: data['siswaName'] ?? '-',
                      lokasi: data['mode'] ?? '-',
                      warnaAksen: Colors.blue,
                    );
                  }).toList(),
                );
              },
            ),
            
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Request Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PermintaanRelawanTab()),
                    );
                  },
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('relawanId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final allRequests = snapshot.data!.docs.toList();
                
                // Urutkan secara lokal untuk menghindari error index Firestore
                allRequests.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  
                  final timeA = dataA['requestedAt'] as Timestamp?;
                  final timeB = dataB['requestedAt'] as Timestamp?;
                  
                  if (timeA == null && timeB == null) return 0;
                  if (timeA == null) return 1;
                  if (timeB == null) return -1;
                  
                  return timeB.compareTo(timeA); // Descending order
                });

                final limitedRequests = allRequests.take(1).toList();

                if (limitedRequests.isEmpty) {
                  return const Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('Tidak ada request terbaru', style: TextStyle(color: Colors.black54)),
                      ),
                    ),
                  );
                }

                return Column(
                  children: limitedRequests.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildRequestCard(
                      namaSiswa: data['siswaName'] ?? '-',
                      mapel: data['mapel'] ?? '-',
                      pesan: data['catatanSiswa'] ?? '-',
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSesiCard({
    required String mapel,
    required String waktu,
    required String siswa,
    required String lokasi,
    required Color warnaAksen,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: warnaAksen.withValues(alpha: 0.3), width: 1),
      ),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: warnaAksen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.class_, color: warnaAksen),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mapel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(waktu, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(siswa, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.green, size: 32),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard({
    required String namaSiswa,
    required String mapel,
    required String pesan,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: const Icon(Icons.person_outline, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Butuh bantuan: $mapel', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
                
              ],
            ),
            if (pesan.isNotEmpty && pesan != '-')
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Text(
                  '"$pesan"',
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                ),
              )
            else
              const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Terima'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  String _dua(int value) => value.toString().padLeft(2, '0');
}

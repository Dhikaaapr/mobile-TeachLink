import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pilih_jadwal_relawan_screen.dart';

class RelawanDetailScreen extends StatelessWidget {
  final String relawanId;
  const RelawanDetailScreen({super.key, required this.relawanId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(relawanId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data relawan tidak ditemukan'));
          }

          final data = snapshot.data!.data()!;
          final nama = (data['nama'] as String?)?.trim() ?? 'Relawan';
          final keahlian = (data['keahlian'] as String?)?.trim() ?? '-';
          final lokasi = (data['lokasi'] as String?)?.trim() ?? '-';
          final bio = (data['bio'] as String?)?.trim() ?? 'Belum ada informasi bio';
          final pekerjaan = (data['pekerjaan'] as String?)?.trim() ?? '-';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          child: const Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nama,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('sessions')
                            .where('relawanId', isEqualTo: relawanId)
                            .snapshots(),
                        builder: (context, sessionSnapshot) {
                          int totalSiswa = 0;

                          if (sessionSnapshot.hasData) {
                            final sessions = sessionSnapshot.data!.docs;
                            final uniqueSiswa = <String>{};

                            for (final doc in sessions) {
                              final sessionData = doc.data();
                              final siswaId = (sessionData['siswaId'] as String?)?.trim();
                              if (siswaId != null && siswaId.isNotEmpty) {
                                uniqueSiswa.add(siswaId);
                              }
                            }

                            totalSiswa = uniqueSiswa.length;
                          }

                          return Row(
                            children: [
                              Expanded(child: _buildStatChip(Icons.people, '$totalSiswa Siswa diajar', Colors.blue)),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      _buildSectionCard(
                        title: 'Tentang Relawan',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bio, style: const TextStyle(color: Colors.black87, height: 1.5)),
                            const SizedBox(height: 12),
                            _buildDetailRow(Icons.work, 'Pekerjaan', pekerjaan),
                            const SizedBox(height: 8),
                            _buildDetailRow(Icons.workspace_premium, 'Keahlian', keahlian),
                            const SizedBox(height: 8),
                            _buildDetailRow(Icons.location_on, 'Lokasi', lokasi),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PilihJadwalRelawanScreen(
                                  relawanId: relawanId,
                                  relawanName: nama,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Pilih Jadwal Tersedia',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
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

import 'package:flutter/material.dart';
import 'relawan_detail_screen.dart';
import 'notifikasi_screen.dart';

class HomeTab extends StatelessWidget {
  final String role;
  const HomeTab({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isSiswa = role == 'siswa';

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
              MaterialPageRoute(builder: (_) => NotifikasiScreen(role: role)),
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
                gradient: LinearGradient(
                  colors: isSiswa
                      ? [const Color(0xFF1565C0), const Color(0xFF42A5F5)]
                      : [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
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
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: const Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang,',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                          ),
                          Text(
                            isSiswa ? 'Budi Santoso 👋' : 'Rina Dewi 👋',
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isSiswa
                        ? 'Tetap semangat belajar hari ini!'
                        : 'Terima kasih sudah menjadi relawan!',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: isSiswa ? 'Total Sesi' : 'Total Siswa',
                    value: isSiswa ? '5' : '12',
                    icon: isSiswa ? Icons.menu_book : Icons.people,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: isSiswa ? 'Jam Belajar' : 'Jam Sosial',
                    value: isSiswa ? '12j' : '48j',
                    icon: Icons.timer,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick action untuk Siswa
            if (isSiswa) ...[
              const Text('Relawan Rekomendasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final data = RelawanDetailScreen.dummyData[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RelawanDetailScreen(relawanIndex: index)),
                      ),
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
                            Text(data['nama'].toString().split(' ')[0],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(data['keahlian'].toString().split(',')[0],
                                style: const TextStyle(color: Colors.black54, fontSize: 11),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, size: 12, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(data['rating'], style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Jadwal/Aktivitas list
            Text(
              isSiswa ? 'Jadwal Belajar Mendatang' : 'Aktivitas Terbaru',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(3, (index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSiswa ? Colors.blue[50] : Colors.green[50],
                    child: Icon(
                      isSiswa ? Icons.menu_book : Icons.volunteer_activism,
                      color: isSiswa ? Colors.blue : Colors.green,
                    ),
                  ),
                  title: Text(
                    isSiswa
                        ? 'Sesi Belajar #${index + 1}'
                        : 'Kegiatan Mengajar #${index + 1}',
                  ),
                  subtitle: Text(
                    isSiswa
                        ? 'Matematika • Besok, 14:00'
                        : 'SDN 01 Jakarta • 2 Hari yang lalu',
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {},
                ),
              );
            }),
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
            color: Colors.black.withOpacity(0.05),
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
}

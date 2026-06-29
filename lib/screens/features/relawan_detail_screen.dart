import 'package:flutter/material.dart';
import 'request_belajar_screen.dart';

class RelawanDetailScreen extends StatelessWidget {
  final int relawanIndex;
  const RelawanDetailScreen({super.key, required this.relawanIndex});

  // Public dummy data accessible from search tab
  static const List<Map<String, dynamic>> dummyData = [
    {
      'nama': 'Ahmad Fauzi',
      'keahlian': 'Matematika, Fisika',
      'lokasi': 'Jakarta Selatan',
      'rating': '4.9',
      'totalSiswa': 18,
      'jamSosial': 72,
      'pendidikan': 'S1 Teknik, UI',
      'bio': 'Saya adalah relawan yang berpengalaman dalam mengajar Matematika dan Fisika. Senang membantu siswa memahami konsep sulit dengan cara yang mudah dan menyenangkan.',
      'ulasan': [
        {'nama': 'Budi S.', 'bintang': 5, 'komentar': 'Pak Ahmad sangat sabar dan penjelasannya mudah dimengerti!'},
        {'nama': 'Siti R.', 'bintang': 5, 'komentar': 'Nilai MTK saya naik drastis setelah belajar dengan beliau.'},
      ],
    },
    {
      'nama': 'Rina Dewi',
      'keahlian': 'Bahasa Inggris, Seni',
      'lokasi': 'Jakarta Utara',
      'rating': '4.8',
      'totalSiswa': 15,
      'jamSosial': 60,
      'pendidikan': 'S1 Sastra Inggris, UNJ',
      'bio': 'Relawan pengajar Bahasa Inggris dengan metode komunikatif. Percaya bahwa belajar bahasa harus menyenangkan dan penuh praktik.',
      'ulasan': [
        {'nama': 'Dian P.', 'bintang': 5, 'komentar': 'Kak Rina super friendly dan cara ngajarnya seru banget!'},
        {'nama': 'Roni A.', 'bintang': 4, 'komentar': 'Jelas dan sabar, highly recommended.'},
      ],
    },
    {
      'nama': 'Budi Hartono',
      'keahlian': 'IPA, Kimia',
      'lokasi': 'Jakarta Timur',
      'rating': '4.7',
      'totalSiswa': 10,
      'jamSosial': 45,
      'pendidikan': 'S1 Kimia, ITB',
      'bio': 'Mahasiswa tingkat akhir yang hobi berbagi ilmu. Spesialisasi IPA dan Kimia untuk SMP dan SMA.',
      'ulasan': [
        {'nama': 'Leni K.', 'bintang': 5, 'komentar': 'Penjelasan kimianya sangat detail, saya jadi suka!'},
        {'nama': 'Farhan M.', 'bintang': 4, 'komentar': 'Bagus, materinya terstruktur dengan baik.'},
      ],
    },
    {
      'nama': 'Dewi Lestari',
      'keahlian': 'B.Indonesia, Sejarah',
      'lokasi': 'Jakarta Barat',
      'rating': '4.9',
      'totalSiswa': 20,
      'jamSosial': 80,
      'pendidikan': 'S1 Pendidikan Bahasa, UPI',
      'bio': 'Guru muda yang berdedikasi. Berpengalaman mengajar Bahasa Indonesia dan Sejarah dengan metode bercerita yang menarik.',
      'ulasan': [
        {'nama': 'Ardi W.', 'bintang': 5, 'komentar': 'Cara beliau mengajar sejarah sangat hidup dan tidak membosankan!'},
        {'nama': 'Nina S.', 'bintang': 5, 'komentar': 'Sangat membantu untuk persiapan UN, terima kasih!'},
      ],
    },
    {
      'nama': 'Rizky Ramadhan',
      'keahlian': 'Pemrograman, MTK',
      'lokasi': 'Depok',
      'rating': '4.8',
      'totalSiswa': 8,
      'jamSosial': 32,
      'pendidikan': 'S1 Ilmu Komputer, IPB',
      'bio': 'Software developer yang ingin berbagi ilmu coding ke generasi muda. Juga kuat di bidang Matematika, khususnya logika.',
      'ulasan': [
        {'nama': 'Yusuf A.', 'bintang': 5, 'komentar': 'Kak Rizky ngajar coding dari nol, saya jadi langsung bisa!'},
        {'nama': 'Mia C.', 'bintang': 4, 'komentar': 'Sangat membantu, sabar dalam menjelaskan.'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final data = dummyData[relawanIndex % dummyData.length];
    final List<Map<String, dynamic>> ulasan = List<Map<String, dynamic>>.from(data['ulasan']);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
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
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: const Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['nama'],
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
                  // Stats Row
                  Row(
                    children: [
                      Expanded(child: _buildStatChip(Icons.star, data['rating'], Colors.amber)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatChip(Icons.people, '${data['totalSiswa']} Siswa', Colors.blue)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatChip(Icons.timer, '${data['jamSosial']}j', Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Detail Card
                  _buildSectionCard(
                    title: 'Tentang Relawan',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['bio'], style: const TextStyle(color: Colors.black87, height: 1.5)),
                        const SizedBox(height: 12),
                        _buildDetailRow(Icons.school, 'Pendidikan', data['pendidikan']),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.workspace_premium, 'Keahlian', data['keahlian']),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.location_on, 'Lokasi', data['lokasi']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ulasan
                  _buildSectionCard(
                    title: '⭐ Ulasan Siswa',
                    child: Column(
                      children: ulasan.map((ulasan) => _buildUlasanItem(ulasan)).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Request
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RequestBelajarScreen(relawan: data),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Kirim Permintaan Belajar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildUlasanItem(Map<String, dynamic> ulasan) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue[100],
            child: const Icon(Icons.person, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ulasan['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    ...List.generate(ulasan['bintang'], (_) => const Icon(Icons.star, size: 14, color: Colors.amber)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(ulasan['komentar'], style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

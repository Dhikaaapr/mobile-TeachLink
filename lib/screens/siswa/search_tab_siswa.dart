import 'package:flutter/material.dart';
import 'relawan_detail_screen.dart';

// Dummy data relawan - dipindahkan ke sini agar mudah diakses oleh siswa
const List<Map<String, dynamic>> dummyRelawan = [
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

class SearchTabSiswa extends StatelessWidget {
  const SearchTabSiswa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Cari Relawan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari relawan atau keahlian...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dummyRelawan.length,
              itemBuilder: (context, index) => _buildRelawanCard(context, index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelawanCard(BuildContext context, int index) {
    final data = dummyRelawan[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RelawanDetailScreen(relawanIndex: index)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue[100],
                child: const Icon(Icons.person, size: 36, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['nama'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(data['keahlian'],
                        style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 15, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(data['rating'], style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on, size: 15, color: Colors.grey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(data['lokasi'],
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

// Dummy data permintaan masuk untuk relawan
final List<Map<String, dynamic>> dummyPermintaan = [
  {
    'nama': 'Budi Santoso',
    'kelas': 'SMP Kelas 8',
    'mapel': 'Matematika',
    'hari': 'Senin',
    'catatan': 'Saya kesulitan di bab pecahan dan aljabar, mohon bimbingannya kak.',
    'lokasi': 'Jakarta Selatan',
    'status': 'menunggu',
  },
  {
    'nama': 'Siti Rahma',
    'kelas': 'SD Kelas 6',
    'mapel': 'IPA / Sains',
    'hari': 'Rabu',
    'catatan': 'Mau persiapan UN, butuh bimbingan intensif untuk IPA.',
    'lokasi': 'Jakarta Timur',
    'status': 'menunggu',
  },
  {
    'nama': 'Arif Hidayat',
    'kelas': 'SMA Kelas 10',
    'mapel': 'Fisika',
    'hari': 'Jumat',
    'catatan': 'Baru mulai belajar fisika, masih bingung dengan konsep dasar gerak.',
    'lokasi': 'Depok',
    'status': 'diterima',
  },
  {
    'nama': 'Lina Safitri',
    'kelas': 'SMP Kelas 9',
    'mapel': 'Matematika',
    'hari': 'Sabtu',
    'catatan': 'Perlu bantuan untuk soal-soal trigonometri dan persamaan kuadrat.',
    'lokasi': 'Bekasi',
    'status': 'menunggu',
  },
];

class PermintaanDetailScreen extends StatefulWidget {
  final int index;
  const PermintaanDetailScreen({super.key, required this.index});

  @override
  State<PermintaanDetailScreen> createState() => _PermintaanDetailScreenState();
}

class _PermintaanDetailScreenState extends State<PermintaanDetailScreen> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = dummyPermintaan[widget.index]['status'];
  }

  void _ubahStatus(String status) {
    setState(() => _status = status);
    final msg = status == 'diterima' ? '✅ Permintaan diterima!' : '❌ Permintaan ditolak.';
    final color = status == 'diterima' ? Colors.green : Colors.red;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
    if (status == 'diterima') {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = dummyPermintaan[widget.index];

    Color statusColor;
    String statusLabel;
    switch (_status) {
      case 'diterima':
        statusColor = Colors.green;
        statusLabel = '✅ Diterima';
        break;
      case 'ditolak':
        statusColor = Colors.red;
        statusLabel = '❌ Ditolak';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = '⏳ Menunggu Konfirmasi';
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detail Permintaan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Text(
                statusLabel,
                textAlign: TextAlign.center,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 20),

            // Siswa profile
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[100],
                    child: const Icon(Icons.person, size: 36, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['nama'],
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(data['kelas'], style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(data['lokasi'],
                              style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Request details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detail Permintaan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.menu_book, 'Mata Pelajaran', data['mapel']),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.calendar_today, 'Hari Belajar', data['hari']),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.notes, 'Catatan Siswa', data['catatan']),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons (only if masih menunggu)
            if (_status == 'menunggu') ...[
              ElevatedButton.icon(
                onPressed: () => _ubahStatus('diterima'),
                icon: const Icon(Icons.check_circle),
                label: const Text('Terima Permintaan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _ubahStatus('ditolak'),
                icon: const Icon(Icons.cancel),
                label: const Text('Tolak Permintaan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 2),
            SizedBox(
              width: 250,
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }
}

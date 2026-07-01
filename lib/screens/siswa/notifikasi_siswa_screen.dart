import 'package:flutter/material.dart';

class NotifikasiSiswaScreen extends StatelessWidget {
  const NotifikasiSiswaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifs = [
      {
        'icon': Icons.check_circle,
        'color': Colors.green,
        'judul': 'Permintaan Diterima!',
        'isi': 'Ahmad Fauzi menerima permintaan belajar Matematika Anda.',
        'waktu': '5 menit lalu',
        'dibaca': false,
      },
      {
        'icon': Icons.calendar_today,
        'color': Colors.blue,
        'judul': 'Sesi Belajar Besok',
        'isi': 'Pengingat: Sesi Matematika bersama Ahmad Fauzi besok pukul 14:00.',
        'waktu': '1 jam lalu',
        'dibaca': false,
      },
      {
        'icon': Icons.star,
        'color': Colors.amber,
        'judul': 'Beri Ulasan',
        'isi': 'Bagaimana sesi belajar Anda kemarin? Berikan ulasan untuk Rina Dewi.',
        'waktu': '1 hari lalu',
        'dibaca': true,
      },
      {
        'icon': Icons.people,
        'color': Colors.purple,
        'judul': 'Relawan Baru di Sekitar Anda',
        'isi': 'Ada 3 relawan baru yang bergabung di Jakarta Selatan. Cek sekarang!',
        'waktu': '2 hari lalu',
        'dibaca': true,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Tandai semua dibaca', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifs.length,
        itemBuilder: (context, index) {
          final n = notifs[index];
          final bool dibaca = n['dibaca'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: dibaca ? Colors.white : Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dibaca ? Colors.grey[200]! : Colors.blue[200]!,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: (n['color'] as Color).withOpacity(0.15),
                child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 22),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      n['judul'],
                      style: TextStyle(
                        fontWeight: dibaca ? FontWeight.normal : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (!dibaca)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(n['isi'], style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(n['waktu'], style: const TextStyle(fontSize: 11, color: Colors.black38)),
                ],
              ),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}

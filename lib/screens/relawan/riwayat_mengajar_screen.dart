import 'package:flutter/material.dart';

class RiwayatMengajarScreen extends StatelessWidget {
  const RiwayatMengajarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Riwayat Mengajar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5,
        itemBuilder: (context, index) {
          final isCompleted = index % 2 == 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: isCompleted ? Colors.green[50] : Colors.orange[50],
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.cancel,
                  color: isCompleted ? Colors.green : Colors.orange,
                ),
              ),
              title: const Text(
                'Matematika - SMP',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text('Siswa: Budi (Kelas 8)'),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted ? 'Selesai pada: 12 Okt 2023' : 'Dibatalkan',
                    style: TextStyle(
                      color: isCompleted ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                // Tampilkan detail riwayat jika diperlukan
              },
            ),
          );
        },
      ),
    );
  }
}

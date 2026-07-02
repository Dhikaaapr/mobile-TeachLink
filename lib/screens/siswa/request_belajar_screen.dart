import 'package:flutter/material.dart';

class RequestBelajarScreen extends StatefulWidget {
  final Map<String, dynamic> relawan;
  const RequestBelajarScreen({super.key, required this.relawan});

  @override
  State<RequestBelajarScreen> createState() => _RequestBelajarScreenState();
}

class _RequestBelajarScreenState extends State<RequestBelajarScreen> {
  String? _selectedMapel;
  String? _selectedHari;
  final _catatanController = TextEditingController();

  final List<String> _mapelList = [
    'Matematika', 'IPA / Sains', 'Bahasa Inggris', 'Bahasa Indonesia',
    'Fisika', 'Kimia', 'Sejarah', 'Pemrograman'
  ];
  final List<String> _hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  void _kirimPermintaan() {
    if (_selectedMapel == null || _selectedHari == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap pilih mata pelajaran dan hari terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Permintaan Terkirim!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Permintaan belajar Anda kepada ${widget.relawan['nama']} telah dikirim. Tunggu konfirmasi dari relawan.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // back to detail
                Navigator.of(context).pop(); // back to search
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kembali ke Beranda'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kirim Permintaan Belajar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Relawan info header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    child: const Icon(Icons.person, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.relawan['nama'],
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(widget.relawan['keahlian'],
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(widget.relawan['lokasi'],
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ]),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(widget.relawan['rating'],
                          style:
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Detail Permintaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Mata Pelajaran
            DropdownButtonFormField<String>(
              initialValue: _selectedMapel,
              decoration: InputDecoration(
                labelText: 'Mata Pelajaran yang Dibutuhkan',
                prefixIcon: const Icon(Icons.menu_book),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _mapelList
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedMapel = val),
            ),
            const SizedBox(height: 16),

            // Hari
            DropdownButtonFormField<String>(
              initialValue: _selectedHari,
              decoration: InputDecoration(
                labelText: 'Preferensi Hari Belajar',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _hariList
                  .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedHari = val),
            ),
            const SizedBox(height: 16),

            // Catatan
            TextField(
              controller: _catatanController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Catatan / Pesan untuk Relawan',
                hintText: 'Contoh: Saya kesulitan di bab pecahan, butuh bimbingan 2x seminggu...',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _kirimPermintaan,
              icon: const Icon(Icons.send),
              label: const Text('Kirim Permintaan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

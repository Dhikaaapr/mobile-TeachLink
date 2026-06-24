import 'package:flutter/material.dart';
import 'login_screen.dart';

class ProfileTab extends StatelessWidget {
  final String role;
  const ProfileTab({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isSiswa = role == 'siswa';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: isSiswa ? Colors.blue : Colors.green,
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSiswa ? 'Budi Santoso' : 'Rina Dewi',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              isSiswa ? 'siswa@teachlink.com' : 'relawan@teachlink.com',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSiswa ? Colors.blue[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSiswa ? '🎓 Siswa' : '🌟 Relawan',
                  style: TextStyle(
                    color: isSiswa ? Colors.blue : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Role-specific info card
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
                  Text(
                    isSiswa ? 'Info Pelajar' : 'Info Relawan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  if (isSiswa) ...[
                    _buildInfoRow(Icons.school, 'Jenjang', 'SMP Kelas 8'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.menu_book, 'Mata Pelajaran', 'MTK, IPA, B.Inggris'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, 'Lokasi', 'Jakarta Selatan'),
                  ] else ...[
                    _buildInfoRow(Icons.workspace_premium, 'Keahlian', 'Matematika, Sains'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.timer, 'Total Jam Sosial', '48 Jam'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.people, 'Total Siswa', '12 Siswa'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.star, 'Rating', '4.8 / 5.0'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, 'Lokasi', 'Jakarta Selatan'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildProfileMenu(icon: Icons.edit_outlined, title: 'Edit Profil', onTap: () {}),
            _buildProfileMenu(
              icon: Icons.history,
              title: isSiswa ? 'Riwayat Sesi Belajar' : 'Riwayat Mengajar',
              onTap: () {},
            ),
            _buildProfileMenu(icon: Icons.settings_outlined, title: 'Pengaturan', onTap: () {}),
            _buildProfileMenu(icon: Icons.help_outline, title: 'Pusat Bantuan', onTap: () {}),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Keluar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.black54)),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildProfileMenu({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

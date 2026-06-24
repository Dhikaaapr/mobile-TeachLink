import 'package:flutter/material.dart';
import 'relawan_detail_screen.dart';
import 'permintaan_detail_screen.dart';

class SearchTab extends StatelessWidget {
  final String role;
  const SearchTab({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isSiswa = role == 'siswa';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isSiswa ? 'Cari Relawan' : 'Permintaan Siswa'),
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
                hintText: isSiswa ? 'Cari relawan atau keahlian...' : 'Cari siswa atau mata pelajaran...',
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
              itemCount: isSiswa
                  ? RelawanDetailScreen.dummyData.length
                  : dummyPermintaan.length,
              itemBuilder: (context, index) {
                if (isSiswa) {
                  return _buildRelawanCard(context, index);
                } else {
                  return _buildPermintaanCard(context, index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelawanCard(BuildContext context, int index) {
    final data = RelawanDetailScreen.dummyData[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => RelawanDetailScreen(relawanIndex: index)),
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
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(data['keahlian'],
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 15, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(data['rating'],
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on,
                            size: 15, color: Colors.grey),
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

  Widget _buildPermintaanCard(BuildContext context, int index) {
    final data = dummyPermintaan[index];
    final Color statusColor = data['status'] == 'diterima'
        ? Colors.green
        : data['status'] == 'ditolak'
            ? Colors.red
            : Colors.orange;
    final String statusLabel = data['status'] == 'diterima'
        ? 'Diterima'
        : data['status'] == 'ditolak'
            ? 'Ditolak'
            : 'Menunggu';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PermintaanDetailScreen(index: index)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.green[100],
                child: const Icon(Icons.person, size: 32, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(data['nama'],
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(statusLabel,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${data['kelas']} • ${data['mapel']}',
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Hari ${data['hari']}',
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(data['lokasi'],
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'request_belajar_screen.dart';

class SearchTabSiswa extends StatefulWidget {
  const SearchTabSiswa({super.key});

  @override
  State<SearchTabSiswa> createState() => _SearchTabSiswaState();
}

class _SearchTabSiswaState extends State<SearchTabSiswa> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan nama, mata pelajaran, lokasi, mode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .where('publishState', isEqualTo: 'published')
                  .where('bookingState', isEqualTo: 'open')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Gagal memuat jadwal: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final now = DateTime.now();
                
                var availableDocs = docs.where((doc) {
                  final startAt = doc.data()['startAt'];
                  if (startAt is! Timestamp) return false;
                  return startAt.toDate().isAfter(now);
                }).toList();

                if (_searchQuery.isNotEmpty) {
                  availableDocs = availableDocs.where((doc) {
                    final data = doc.data();
                    final nama = (data['ownerRelawanName'] as String? ?? '').toLowerCase();
                    final mataPelajaran = (data['mataPelajaran'] as String? ?? '').toLowerCase();
                    final mode = (data['mode'] as String? ?? '').toLowerCase();
                    final detail = (data['detail'] as String? ?? '').toLowerCase();
                    
                    return nama.contains(_searchQuery) ||
                        mataPelajaran.contains(_searchQuery) ||
                        mode.contains(_searchQuery) ||
                        detail.contains(_searchQuery);
                  }).toList();
                }

                availableDocs.sort((a, b) {
                  final aStart = a.data()['startAt'];
                  final bStart = b.data()['startAt'];
                  final aDate = aStart is Timestamp ? aStart.toDate() : DateTime(2100);
                  final bDate = bStart is Timestamp ? bStart.toDate() : DateTime(2100);
                  return aDate.compareTo(bDate);
                });

                if (availableDocs.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isNotEmpty 
                          ? 'Relawan tidak ditemukan'
                          : 'Belum ada jadwal tersedia saat ini.',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableDocs.length,
                  itemBuilder: (context, index) {
                    final doc = availableDocs[index];
                    final data = doc.data();
                    return _buildScheduleCard(context, doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(
    BuildContext context,
    String scheduleId,
    Map<String, dynamic> data,
  ) {
    final startAt = data['startAt'] as Timestamp?;
    final endAt = data['endAt'] as Timestamp?;
    final mode = (data['mode'] as String?) ?? '-';
    final detail = (data['detail'] as String?)?.trim() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (data['mataPelajaran'] as String?) ?? '-',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Open',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Relawan: ${(data['ownerRelawanName'] as String?) ?? 'Relawan'}',
              style: const TextStyle(fontSize: 13.5, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              _formatWaktu(startAt, endAt),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              '$mode • $detail',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestBelajarScreen(
                        scheduleId: scheduleId,
                        scheduleData: data,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Request Belajar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatWaktu(Timestamp? startAt, Timestamp? endAt) {
    if (startAt == null || endAt == null) return '-';
    final start = startAt.toDate();
    final end = endAt.toDate();
    return '${_hariIndonesia(start.weekday)}, ${_dua(start.day)}/${_dua(start.month)}/${start.year} ${_dua(start.hour)}:${_dua(start.minute)} - ${_dua(end.hour)}:${_dua(end.minute)}';
  }

  String _dua(int value) => value.toString().padLeft(2, '0');

  String _hariIndonesia(int weekday) {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return hari[(weekday - 1).clamp(0, 6)];
  }
}

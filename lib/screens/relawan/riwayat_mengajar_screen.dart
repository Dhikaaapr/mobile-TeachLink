import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/sertifikat_service.dart';

class RiwayatMengajarScreen extends StatefulWidget {
  const RiwayatMengajarScreen({super.key});

  @override
  State<RiwayatMengajarScreen> createState() => _RiwayatMengajarScreenState();
}

class _RiwayatMengajarScreenState extends State<RiwayatMengajarScreen> {
  bool _isGeneratingSertifikat = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Riwayat Mengajar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cetak Sertifikat',
            icon: _isGeneratingSertifikat
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.workspace_premium_outlined),
            onPressed: _isGeneratingSertifikat ? null : _pilihPeriodeSertifikat,
          ),
        ],
      ),
      body: _buildRiwayatBody(),
    );
  }

  // ================== SERTIFIKAT ==================

  Future<void> _pilihPeriodeSertifikat() async {
    final periode = await showModalBottomSheet<_PeriodeSertifikat>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Cetak Sertifikat Rekap Mengajar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Pilih periode rekap yang ingin dicetak',
                    style: TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_view_month, color: Colors.green),
                  title: const Text('6 Bulan Terakhir'),
                  onTap: () => Navigator.pop(context, _PeriodeSertifikat.enamBulan),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.green),
                  title: const Text('1 Tahun Terakhir'),
                  onTap: () => Navigator.pop(context, _PeriodeSertifikat.satuTahun),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (periode == null) return;
    await _generateSertifikat(periode);
  }

  Future<void> _generateSertifikat(_PeriodeSertifikat periode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Silakan login kembali.', isError: true);
      return;
    }

    setState(() => _isGeneratingSertifikat = true);

    try {
      final now = DateTime.now();
      final DateTime periodeMulai;
      final String periodeLabel;

      if (periode == _PeriodeSertifikat.enamBulan) {
        periodeMulai = DateTime(now.year, now.month - 6, now.day);
        periodeLabel = '6 Bulan Terakhir';
      } else {
        periodeMulai = DateTime(now.year - 1, now.month, now.day);
        periodeLabel = '1 Tahun Terakhir';
      }

      // Ambil nama relawan asli dari Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final namaRelawan = (userDoc.data()?['nama'] as String?)?.trim();

      // Ambil sesi selesai asli dalam rentang periode yang dipilih
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .where('relawanId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      final docsDalamPeriode = sessionsSnapshot.docs.where((doc) {
        final startAt = doc.data()['startAt'];
        if (startAt is! Timestamp) return false;
        final tanggal = startAt.toDate();
        return tanggal.isAfter(periodeMulai) || tanggal.isAtSameMomentAs(periodeMulai);
      }).toList();

      if (docsDalamPeriode.isEmpty) {
        if (!mounted) return;
        _showSnack('Belum ada sesi mengajar selesai pada periode ini.', isError: true);
        setState(() => _isGeneratingSertifikat = false);
        return;
      }

      final mataPelajaranSet = <String>{};
      final siswaIdSet = <String>{};
      double totalJam = 0;

      for (final doc in docsDalamPeriode) {
        final data = doc.data();

        final mapel = (data['mataPelajaran'] as String?)?.trim();
        if (mapel != null && mapel.isNotEmpty) mataPelajaranSet.add(mapel);

        final siswaId = data['siswaId'] as String?;
        if (siswaId != null) siswaIdSet.add(siswaId);

        final startAt = data['startAt'];
        final endAt = data['endAt'];
        if (startAt is Timestamp && endAt is Timestamp) {
          totalJam += endAt.toDate().difference(startAt.toDate()).inMinutes / 60.0;
        }
      }

      final nomorSertifikat =
          'TL/${now.year}${now.month.toString().padLeft(2, '0')}/${user.uid.substring(0, 6).toUpperCase()}';

      final pdf = await SertifikatService.buatSertifikat(
        namaRelawan: (namaRelawan == null || namaRelawan.isEmpty) ? 'Relawan TeachLink' : namaRelawan,
        mataPelajaran: mataPelajaranSet.toList(),
        periodeLabel: periodeLabel,
        periodeMulai: periodeMulai,
        periodeSelesai: now,
        totalSesi: docsDalamPeriode.length,
        totalJam: totalJam.round(),
        totalSiswa: siswaIdSet.length,
        tanggalTerbit: now,
        nomorSertifikat: nomorSertifikat,
      );

      if (!mounted) return;
      await SertifikatService.previewDanBagikan(pdf, 'Sertifikat_Mengajar_$periodeLabel');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal membuat sertifikat: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isGeneratingSertifikat = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  // ================== LIST RIWAYAT (real - collection 'sessions') ==================

  Widget _buildRiwayatBody() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Silakan login kembali.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('relawanId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat riwayat: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) {
          final status = (doc.data()['status'] as String?) ?? 'upcoming';
          return status == 'completed' || status == 'cancelled';
        }).toList();

        docs.sort((a, b) {
          final aStart = a.data()['startAt'];
          final bStart = b.data()['startAt'];
          final aDate = aStart is Timestamp ? aStart.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = bStart is Timestamp ? bStart.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

        if (docs.isEmpty) {
          return const Center(child: Text('Belum ada riwayat mengajar.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final status = (data['status'] as String?) ?? 'completed';
            final isCompleted = status == 'completed';
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
                title: Text(
                  (data['mataPelajaran'] as String?) ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Siswa: ${(data['siswaName'] as String?) ?? '-'}'),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted
                          ? 'Selesai pada: ${_formatTanggal(data['completedAt'] ?? data['startAt'])}'
                          : 'Dibatalkan',
                      style: TextStyle(
                        color: isCompleted ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTanggal(dynamic timestamp) {
    if (timestamp is! Timestamp) return '-';
    final dt = timestamp.toDate();
    return '${_dua(dt.day)}/${_dua(dt.month)}/${dt.year} ${_dua(dt.hour)}:${_dua(dt.minute)}';
  }

  String _dua(int value) => value.toString().padLeft(2, '0');
}

enum _PeriodeSertifikat { enamBulan, satuTahun }
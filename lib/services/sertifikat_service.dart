import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SertifikatService {
  static const PdfColor _hijauUtama = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor _emas = PdfColor.fromInt(0xFFC9A227);
  static const PdfColor _abuTeks = PdfColor.fromInt(0xFF555555);

  /// Membuat dokumen PDF sertifikat rekap mengajar relawan.
  ///
  /// [namaRelawan] dan [mataPelajaran] diambil dari profil & data sesi asli
  /// (bukan data dummy) yang dikirim oleh pemanggil fungsi ini.
  static Future<pw.Document> buatSertifikat({
    required String namaRelawan,
    required List<String> mataPelajaran,
    required String periodeLabel,
    required DateTime periodeMulai,
    required DateTime periodeSelesai,
    required int totalSesi,
    required int totalJam,
    required int totalSiswa,
    required DateTime tanggalTerbit,
    required String nomorSertifikat,
  }) async {
    final pdf = pw.Document();

    final mapelText = mataPelajaran.isEmpty ? 'Berbagai Mata Pelajaran' : mataPelajaran.join(', ');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _emas, width: 2.2),
            ),
            padding: const pw.EdgeInsets.all(10),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _hijauUtama, width: 1.2),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 36),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'TEACHLINK',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _hijauUtama,
                      letterSpacing: 4,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Platform Relawan Belajar',
                    style: pw.TextStyle(fontSize: 9, color: _abuTeks, letterSpacing: 1.5),
                  ),
                  pw.SizedBox(height: 22),
                  pw.Container(width: 90, height: 2, color: _emas),
                  pw.SizedBox(height: 22),
                  pw.Text(
                    'SERTIFIKAT PENGHARGAAN',
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Nomor: $nomorSertifikat',
                    style: pw.TextStyle(fontSize: 9, color: _abuTeks),
                  ),
                  pw.SizedBox(height: 26),
                  pw.Text(
                    'Diberikan dengan bangga kepada',
                    style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: _abuTeks),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    namaRelawan,
                    style: pw.TextStyle(
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                      color: _hijauUtama,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(width: 220, height: 1.2, color: _emas),
                  pw.SizedBox(height: 20),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                    child: pw.Text(
                      'Atas dedikasi, waktu, dan kontribusinya sebagai relawan pengajar untuk mata pelajaran '
                      '$mapelText selama periode $periodeLabel '
                      '(${_formatTanggal(periodeMulai)} - ${_formatTanggal(periodeSelesai)}) '
                      'pada platform TeachLink.',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 11.5, color: PdfColors.black, lineSpacing: 3),
                    ),
                  ),
                  pw.SizedBox(height: 26),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      _buildStatBox('$totalSesi', 'Sesi Mengajar'),
                      pw.SizedBox(width: 18),
                      _buildStatBox('$totalJam', 'Jam Mengajar'),
                      pw.SizedBox(width: 18),
                      _buildStatBox('$totalSiswa', 'Siswa Dibantu'),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Diterbitkan di Jakarta, ${_formatTanggal(tanggalTerbit)}',
                            style: pw.TextStyle(fontSize: 9.5, color: _abuTeks),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Dokumen ini digenerate otomatis oleh sistem TeachLink\nberdasarkan data riwayat mengajar yang tercatat.',
                            style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.SizedBox(height: 30),
                          pw.Container(width: 140, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Tim TeachLink',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildStatBox(String angka, String label) {
    return pw.Container(
      width: 130,
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF1F8F1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _hijauUtama, width: 0.6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            angka,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _hijauUtama),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: _abuTeks),
          ),
        ],
      ),
    );
  }

  static String _formatTanggal(DateTime date) {
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${date.day} ${bulan[date.month - 1]} ${date.year}';
  }

  /// Menampilkan preview PDF sekaligus memberi opsi print / share / simpan.
  static Future<void> previewDanBagikan(pw.Document pdf, String namaFile) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: namaFile,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JadwalFormScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initialData;

  const JadwalFormScreen({
    super.key,
    this.docId,
    this.initialData,
  });

  @override
  State<JadwalFormScreen> createState() => _JadwalFormScreenState();
}

class _JadwalFormScreenState extends State<JadwalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _mataPelajaran;
  DateTime? _tanggal;
  String? _jamMulai;
  String? _jamSelesai;
  String? _mode;

  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();

  static const Color _primaryColor = Color(0xFF2E7D32);

  final List<String> mataPelajaran = [
    'Matematika',
    'Bahasa Indonesia',
    'Bahasa Inggris',
    'IPA',
    'IPS',
    'Fisika',
    'Kimia',
    'Biologi',
    'Informatika',
  ];

  final List<String> jamList = [
    '07.00',
    '08.00',
    '09.00',
    '10.00',
    '11.00',
    '12.00',
    '13.00',
    '14.00',
    '15.00',
    '16.00',
    '17.00',
    '18.00',
    '19.00',
    '20.00',
  ];

  bool get _isEditMode => widget.docId != null;

  @override
  void initState() {
    super.initState();
    _isiDataAwalJikaAda();
  }

  void _isiDataAwalJikaAda() {
    final data = widget.initialData;
    if (data == null) return;

    _mataPelajaran = data['mataPelajaran'] as String?;
    _tanggal = (data['tanggal'] as Timestamp?)?.toDate();
    _jamMulai = data['jamMulai'] as String?;
    _jamSelesai = data['jamSelesai'] as String?;
    _mode = data['mode'] as String?;

    final detail = (data['detail'] as String?)?.trim() ?? '';
    final link = (data['link'] as String?)?.trim() ?? '';
    final lokasi = (data['lokasi'] as String?)?.trim() ?? '';

    if (_mode == 'Online') {
      _linkController.text = detail.isNotEmpty ? detail : link;
    }
    if (_mode == 'Offline') {
      _lokasiController.text = detail.isNotEmpty ? detail : lokasi;
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tanggal = picked;
      });
    }
  }

  Future<void> _simpanJadwal() async {
    if (_formKey.currentState!.validate()) {
      if (_tanggal == null) {
        _showSnackBar('Silakan pilih tanggal mengajar', isError: true);
        return;
      }
      if (_mode == null) {
        _showSnackBar('Silakan pilih mode mengajar', isError: true);
        return;
      }

      if (!_isWaktuValid()) {
        _showSnackBar('Jam selesai harus lebih besar dari jam mulai', isError: true);
        return;
      }

      final user = _auth.currentUser;
      if (user == null) {
        _showSnackBar('Sesi login tidak ditemukan. Silakan login ulang.', isError: true);
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final ownerName = (userDoc.data()?['nama'] as String?)?.trim();

      final detail = _mode == 'Online'
          ? _linkController.text.trim()
          : _lokasiController.text.trim();

      final startAt = _dateAndTimeToDateTime(_tanggal!, _jamMulai!);
      final endAt = _dateAndTimeToDateTime(_tanggal!, _jamSelesai!);

      try {
        final payload = {
          'ownerRelawanId': user.uid,
          'ownerRelawanName': ownerName?.isNotEmpty == true ? ownerName : 'Relawan',
          'mataPelajaran': _mataPelajaran,
          'tanggal': Timestamp.fromDate(DateTime(_tanggal!.year, _tanggal!.month, _tanggal!.day)),
          'jamMulai': _jamMulai,
          'jamSelesai': _jamSelesai,
          'startAt': Timestamp.fromDate(startAt),
          'endAt': Timestamp.fromDate(endAt),
          'mode': _mode,
          'detail': detail,
          'link': _mode == 'Online' ? detail : '',
          'lokasi': _mode == 'Offline' ? detail : '',
          'draftState': 'draft',
          'publishState': 'published',
          'bookingState': 'open',
          'selectedRequestId': null,
          'selectedSiswaId': null,
        };

        if (_isEditMode) {
          await _firestore
              .collection('schedules')
              .doc(widget.docId)
              .update({
            ...payload,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await _firestore.collection('schedules').add({
            ...payload,
            'createdAt': FieldValue.serverTimestamp(),
            'publishedAt': FieldValue.serverTimestamp(),
          });
        }

        _showSnackBar(
          _isEditMode
              ? 'Jadwal draft berhasil diperbarui'
              : 'Jadwal berhasil disimpan dan dipublikasikan',
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        _showSnackBar(
          _isEditMode
              ? 'Gagal memperbarui jadwal: $e'
              : 'Gagal menyimpan jadwal: $e',
          isError: true,
        );
      }
    }
  }

  DateTime _dateAndTimeToDateTime(DateTime date, String time) {
    final parts = time.split('.');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool _isWaktuValid() {
    if (_jamMulai == null || _jamSelesai == null) {
      return false;
    }

    int toMinutes(String value) {
      final parts = value.split('.');
      final hour = int.tryParse(parts.first) ?? 0;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      return (hour * 60) + minute;
    }

    return toMinutes(_jamSelesai!) > toMinutes(_jamMulai!);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  InputDecoration _inputDecoration(String? label, IconData icon) {
  return InputDecoration(
    labelText: (label == null || label.trim().isEmpty) ? null : label,
    prefixIcon: Icon(icon, color: _primaryColor),
    filled: true,
    fillColor: Colors.grey.shade50,
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
      borderSide: const BorderSide(color: _primaryColor, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
  );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          _isEditMode ? "Edit Jadwal" : "Tambah Jadwal",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryColor, Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_note_rounded,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Buat Jadwal Mengajar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Isi detail jadwal dengan lengkap",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Card: Detail Pelajaran
              _buildCard(
                children: [
                  _sectionTitle("DETAIL PELAJARAN"),
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration(null, Icons.menu_book_rounded),
                    value: _mataPelajaran,
                    items: mataPelajaran
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) => setState(() => _mataPelajaran = value),
                    validator: (value) =>
                        value == null ? "Pilih mata pelajaran terlebih dahulu" : null,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Card: detail Jadwal
              _buildCard(
                children: [
                  _sectionTitle("DETAIL JADWAL"),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pilihTanggal,
                    child: InputDecorator(
                      decoration: _inputDecoration(null, Icons.calendar_month_rounded)
                          .copyWith(suffixIcon: const Icon(Icons.arrow_drop_down)),
                      child: Text(
                        _tanggal == null
                            ? "Pilih Tanggal"
                            : "${_tanggal!.day.toString().padLeft(2, '0')}/${_tanggal!.month.toString().padLeft(2, '0')}/${_tanggal!.year}",
                        style: TextStyle(
                          color: _tanggal == null ? Colors.grey.shade500 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: _inputDecoration("Jam Mulai", Icons.schedule_rounded),
                          value: _jamMulai,
                          items: jamList
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) => setState(() => _jamMulai = value),
                          validator: (value) => value == null ? "Wajib diisi" : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: _inputDecoration("Jam Selesai", Icons.schedule_rounded),
                          value: _jamSelesai,
                          items: jamList
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) => setState(() => _jamSelesai = value),
                          validator: (value) => value == null ? "Wajib diisi" : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Card: Mode Mengajar
              _buildCard(
                children: [
                  _sectionTitle("MODE MENGAJAR"),
                  Row(
                    children: [
                      Expanded(
                        child: _ModeOption(
                          label: "Online",
                          icon: Icons.videocam_rounded,
                          selected: _mode == "Online",
                          color: _primaryColor,
                          onTap: () => setState(() => _mode = "Online"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ModeOption(
                          label: "Offline",
                          icon: Icons.location_on_rounded,
                          selected: _mode == "Offline",
                          color: _primaryColor,
                          onTap: () => setState(() => _mode = "Offline"),
                        ),
                      ),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _mode == "Online"
                        ? Padding(
                            key: const ValueKey("online"),
                            padding: const EdgeInsets.only(top: 16),
                            child: TextFormField(
                              controller: _linkController,
                              decoration: _inputDecoration("Link Google Meet", Icons.link_rounded),
                              validator: (value) {
                                if (_mode == "Online" && (value == null || value.trim().isEmpty)) {
                                  return "Link tidak boleh kosong";
                                }
                                return null;
                              },
                            ),
                          )
                        : _mode == "Offline"
                            ? Padding(
                                key: const ValueKey("offline"),
                                padding: const EdgeInsets.only(top: 16),
                                child: TextFormField(
                                  controller: _lokasiController,
                                  decoration: _inputDecoration("Lokasi Mengajar", Icons.map_rounded),
                                  validator: (value) {
                                    if (_mode == "Offline" && (value == null || value.trim().isEmpty)) {
                                      return "Lokasi tidak boleh kosong";
                                    }
                                    return null;
                                  },
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey("none")),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _simpanJadwal,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text(
                    "Simpan Jadwal",
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey.shade500, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
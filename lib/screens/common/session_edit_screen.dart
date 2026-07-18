import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionEditScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> sessionData;

  const SessionEditScreen({
    super.key,
    required this.sessionId,
    required this.sessionData,
  });

  @override
  State<SessionEditScreen> createState() => _SessionEditScreenState();
}

class _SessionEditScreenState extends State<SessionEditScreen> {
  late DateTime _startDate;
  String? _startTime;
  String? _endTime;
  late String _mode;
  late TextEditingController _detailController;
  bool _isSaving = false;

  final List<String> jamList = [
    '07.00', '08.00', '09.00', '10.00', '11.00', '12.00', '13.00',
    '14.00', '15.00', '16.00', '17.00', '18.00', '19.00', '20.00',
  ];

  @override
  void initState() {
    super.initState();
    
    final startAt = widget.sessionData['startAt'];
    final endAt = widget.sessionData['endAt'];
    
    if (startAt is Timestamp) {
      final start = startAt.toDate();
      _startDate = DateTime(start.year, start.month, start.day);
      final startStr = '${start.hour.toString().padLeft(2, '0')}.${start.minute.toString().padLeft(2, '0')}';
      _startTime = jamList.contains(startStr) ? startStr : jamList.first;
    } else {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day);
      _startTime = jamList.first;
    }
    
    if (endAt is Timestamp) {
      final end = endAt.toDate();
      final endStr = '${end.hour.toString().padLeft(2, '0')}.${end.minute.toString().padLeft(2, '0')}';
      _endTime = jamList.contains(endStr) ? endStr : jamList[1];
    } else {
      _endTime = jamList[1];
    }
    
    _mode = (widget.sessionData['mode'] as String?) ?? 'Online';
    _detailController = TextEditingController(text: widget.sessionData['detail'] as String? ?? '');
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    final startParts = _startTime!.split('.');
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );
    
    final endParts = _endTime!.split('.');
    final endDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu selesai harus setelah waktu mulai'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .update({
        'startAt': Timestamp.fromDate(startDateTime),
        'endAt': Timestamp.fromDate(endDateTime),
        'mode': _mode,
        'detail': _detailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui jadwal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  static const Color _primaryColor = Color(0xFF2E7D32);

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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            color: Colors.black.withValues(alpha: 0.04),
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

  Widget _buildModeOption(String mode, IconData icon) {
    final selected = _mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mode = mode),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _primaryColor.withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _primaryColor : Colors.grey.shade300,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? _primaryColor : Colors.grey.shade500, size: 24),
              const SizedBox(height: 6),
              Text(
                mode,
                style: TextStyle(
                  color: selected ? _primaryColor : Colors.grey.shade600,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Edit Jadwal', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  const Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sessionData['mataPelajaran'] as String? ?? '-',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Siswa: ${widget.sessionData['siswaName'] as String? ?? '-'}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          'Relawan: ${widget.sessionData['relawanName'] as String? ?? '-'}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildCard(
              children: [
                _sectionTitle("DETAIL WAKTU"),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: _inputDecoration(null, Icons.calendar_month_rounded)
                        .copyWith(suffixIcon: const Icon(Icons.arrow_drop_down)),
                    child: Text(
                      _formatDate(_startDate),
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: _inputDecoration("Waktu Mulai", Icons.schedule_rounded),
                        value: _startTime,
                        items: jamList.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.black87)))).toList(),
                        onChanged: (value) => setState(() => _startTime = value),
                        dropdownColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: _inputDecoration("Waktu Selesai", Icons.schedule_rounded),
                        value: _endTime,
                        items: jamList.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.black87)))).toList(),
                        onChanged: (value) => setState(() => _endTime = value),
                        dropdownColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              children: [
                _sectionTitle("MODE MENGAJAR"),
                Row(
                  children: [
                    _buildModeOption("Online", Icons.videocam_rounded),
                    const SizedBox(width: 12),
                    _buildModeOption("Offline", Icons.location_on_rounded),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _detailController,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    _mode == 'Online' ? 'Link Google Meet' : 'Lokasi Mengajar',
                    _mode == 'Online' ? Icons.link_rounded : Icons.location_on_rounded,
                  ).copyWith(
                    hintText: _mode == 'Online' 
                        ? 'Contoh: https://meet.google.com/...' 
                        : 'Contoh: Kosan bu noor, gang wikarta...',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final hariStr = hari[(date.weekday - 1).clamp(0, 6)];
    return '$hariStr, ${date.day}/${date.month}/${date.year}';
  }
}

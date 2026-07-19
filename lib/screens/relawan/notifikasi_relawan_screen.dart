import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotifikasiRelawanScreen extends StatelessWidget {
  const NotifikasiRelawanScreen({super.key});

  IconData _getIcon(String? category) {
    switch (category) {
      case 'success':
        return Icons.check_circle;
      case 'reminder':
        return Icons.calendar_today;
      case 'rating':
        return Icons.star;
      case 'people':
        return Icons.people;
      case 'info':
        return Icons.info;
      case 'request':
        return Icons.person_add;
      case 'achievement':
        return Icons.workspace_premium;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String? category) {
    switch (category) {
      case 'success':
        return Colors.green;
      case 'reminder':
        return Colors.orange;
      case 'rating':
        return Colors.amber;
      case 'people':
        return Colors.purple;
      case 'info':
        return Colors.purple;
      case 'request':
        return Colors.blue;
      case 'achievement':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  String _formatWaktu(dynamic waktu) {
    if (waktu == null) return '';
    DateTime dateTime;
    if (waktu is Timestamp) {
      dateTime = waktu.toDate();
    } else if (waktu is DateTime) {
      dateTime = waktu;
    } else {
      return waktu.toString();
    }

    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _tandaiSemuaDibaca(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('dibaca', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'dibaca': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _tandaiDibaca(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .update({'dibaca': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (userId.isNotEmpty)
            TextButton(
              onPressed: () => _tandaiSemuaDibaca(userId),
              child: const Text('Tandai semua dibaca', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: userId.isEmpty
          ? const Center(child: Text('Silakan login terlebih dahulu untuk melihat notifikasi.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<QueryDocumentSnapshot> docs = (snapshot.data?.docs ?? []).toList();

                // Urutkan secara client-side berdasarkan createdAt descending
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['createdAt'] as Timestamp?;
                  final bTime = bData['createdAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada notifikasi',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final n = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final bool dibaca = n['dibaca'] ?? false;
                    final category = n['category'] as String?;
                    final icon = _getIcon(category);
                    final color = _getColor(category);
                    final waktu = _formatWaktu(n['createdAt']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: dibaca ? Colors.white : Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: dibaca ? Colors.grey[200]! : Colors.green[200]!,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                n['judul'] ?? '',
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
                                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(n['isi'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 6),
                            Text(waktu, style: const TextStyle(fontSize: 11, color: Colors.black38)),
                          ],
                        ),
                        onTap: () {
                          if (!dibaca) {
                            _tandaiDibaca(docId);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

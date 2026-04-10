import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class FileViewerScreen extends StatelessWidget {
  final String? url;
  final String? fileName;
  final String? fileType;
  const FileViewerScreen({super.key, this.url, this.fileName, this.fileType});

  @override
  Widget build(BuildContext context) {
    final isImage = _checkIfImage(url, fileType);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(fileName ?? "عرض الملف", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.download_outlined), onPressed: () {}),
        ],
      ),
      body: Center(
        child: isImage ? _buildImageViewer(url) : _buildDocViewer(url, fileName, fileType),
      ),
    );
  }

  bool _checkIfImage(String? url, String? type) {
    if (type?.contains('image') ?? false) return true;
    final u = url?.toLowerCase() ?? '';
    return u.endsWith('.jpg') || u.endsWith('.jpeg') || u.endsWith('.png') || u.endsWith('.webp');
  }

  Widget _buildImageViewer(String? url) {
    if (url == null) return const Icon(Icons.broken_image, color: Colors.grey, size: 60);
    return InteractiveViewer(
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 4,
      child: Image.network(url, fit: BoxFit.contain),
    );
  }

  Widget _buildDocViewer(String? url, String? name, String? type) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_getFileIcon(type), size: 100, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(height: 24),
        Text(name ?? "ملف غير معروف", style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(url ?? "لا يوجد رابط متوفر", style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.open_in_new),
          label: Text("فتح في المتصفح أو مشغل خارجي", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
        ),
      ],
    );
  }

  IconData _getFileIcon(String? type) {
    final t = type?.toLowerCase() ?? '';
    if (t.contains('pdf')) return Icons.picture_as_pdf;
    if (t.contains('word') || t.endsWith('doc') || t.endsWith('docx')) return Icons.description;
    if (t.contains('excel') || t.endsWith('xls') || t.endsWith('xlsx')) return Icons.grid_on;
    return Icons.insert_drive_file;
  }
}


import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_model.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  // Generate PDF with user labels
  Future<pw.Document> generateLabelsPdf(UserModel user, int copies) async {
    final pdf = pw.Document();

    // More labels per page with compact layout (3 columns x 10 rows = 30 per page)
    const labelsPerRow = 3;
    const rowsPerPage = 10;
    const labelsPerPage = labelsPerRow * rowsPerPage;

    final totalPages = (copies / labelsPerPage).ceil();

    for (int page = 0; page < totalPages; page++) {
      final startIndex = page * labelsPerPage;
      final endIndex = (startIndex + labelsPerPage) > copies
          ? copies
          : startIndex + labelsPerPage;
      final labelsOnThisPage = endIndex - startIndex;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(15),
          build: (context) {
            return pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(labelsOnThisPage, (index) {
                return _buildLabel(user);
              }),
            );
          },
        ),
      );
    }

    return pdf;
  }

  pw.Widget _buildLabel(UserModel user) {
    // Fixed width for 3 columns on A4
    const labelWidth = 175.0;

    return pw.Container(
      width: labelWidth,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            user.name,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
            maxLines: 2,
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            user.address,
            style: const pw.TextStyle(fontSize: 11),
            maxLines: 3,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Phone: ${user.phone}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  // Preview PDF
  Future<void> previewPdf(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // Save PDF to device
  Future<String> savePdf(pw.Document pdf, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return filePath;
  }

  // Share PDF
  Future<void> sharePdf(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'User Label');
  }

  // Download PDF (save and share)
  Future<void> downloadPdf(UserModel user, int copies) async {
    final pdf = await generateLabelsPdf(user, copies);
    final fileName =
        '${user.name.replaceAll(' ', '_')}_labels_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = await savePdf(pdf, fileName);
    await sharePdf(filePath);
  }

  // Direct print
  Future<void> printLabels(UserModel user, int copies) async {
    final pdf = await generateLabelsPdf(user, copies);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${user.name} Labels',
    );
  }
}

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_model.dart';

class ExcelService {
  static final ExcelService _instance = ExcelService._internal();
  factory ExcelService() => _instance;
  ExcelService._internal();

  // Import users from Excel file
  Future<List<UserModel>?> importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final users = <UserModel>[];
      final sheet = excel.tables.keys.first;
      final rows = excel.tables[sheet]?.rows;

      if (rows == null || rows.isEmpty) return users;

      // Skip header row (index 0)
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        // Generate ID if not present
        final id = row.isNotEmpty && row[0]?.value != null
            ? row[0]!.value.toString()
            : DateTime.now().millisecondsSinceEpoch.toString() + i.toString();

        final name =
            row.length > 1 && row[1]?.value != null ? row[1]!.value.toString() : '';
        final address =
            row.length > 2 && row[2]?.value != null ? row[2]!.value.toString() : '';
        final phone =
            row.length > 3 && row[3]?.value != null ? row[3]!.value.toString() : '';

        if (name.isNotEmpty) {
          users.add(UserModel(
            id: id,
            name: name,
            address: address,
            phone: phone,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      return users;
    } catch (e) {
      throw Exception('Error importing Excel: $e');
    }
  }

  // Export users to Excel file
  Future<String?> exportToExcel(List<UserModel> users) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Users'];

      // Add headers
      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Name'),
        TextCellValue('Address'),
        TextCellValue('Phone'),
        TextCellValue('Created At'),
        TextCellValue('Updated At'),
      ]);

      // Add data rows
      for (final user in users) {
        sheet.appendRow([
          TextCellValue(user.id),
          TextCellValue(user.name),
          TextCellValue(user.address),
          TextCellValue(user.phone),
          TextCellValue(user.createdAt.toIso8601String()),
          TextCellValue(user.updatedAt.toIso8601String()),
        ]);
      }

      // Remove default Sheet1
      excel.delete('Sheet1');

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'users_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';

      final fileBytes = excel.encode();
      if (fileBytes == null) return null;

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      return filePath;
    } catch (e) {
      throw Exception('Error exporting Excel: $e');
    }
  }

  // Share exported Excel file
  Future<void> shareExcel(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Users Export');
  }
}

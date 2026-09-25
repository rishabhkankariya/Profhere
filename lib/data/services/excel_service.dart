import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ExcelService {
  Future<List<TimetableImportRow>> pickAndParseTimetable() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return const <TimetableImportRow>[];
    }

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      throw const FormatException('Unable to read the selected Excel file.');
    }

    return parseTimetableRows(bytes);
  }

  List<TimetableImportRow> parseTimetableRows(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw const FormatException('Excel file does not contain any sheets.');
    }

    final sheet = excel.tables.values.first;
    if (sheet.rows.isEmpty) {
      throw const FormatException('Excel sheet is empty.');
    }

    final headerRow = sheet.rows.first;
    final headers = headerRow
        .map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '')
        .toList();

    final facultyIndex = headers.indexOf('faculty');
    final dayIndex = headers.indexOf('day');
    final startIndex = headers.indexOf('start time');
    final endIndex = headers.indexOf('end time');
    final subjectIndex = headers.indexOf('subject');

    if (facultyIndex == -1 ||
        dayIndex == -1 ||
        startIndex == -1 ||
        endIndex == -1) {
      throw const FormatException(
        'Expected headers: Faculty, Day, Start Time, End Time.',
      );
    }

    final rows = <TimetableImportRow>[];

    for (final rawRow in sheet.rows.skip(1)) {
      final faculty = _cellValue(rawRow, facultyIndex);
      final day = _cellValue(rawRow, dayIndex);
      final startTime = _cellValue(rawRow, startIndex);
      final endTime = _cellValue(rawRow, endIndex);
      final subject = subjectIndex == -1
          ? 'Imported Slot'
          : _cellValue(rawRow, subjectIndex, fallback: 'Imported Slot');

      if (faculty.isEmpty &&
          day.isEmpty &&
          startTime.isEmpty &&
          endTime.isEmpty) {
        continue;
      }

      rows.add(
        TimetableImportRow(
          facultyName: faculty,
          dayOfWeek: day,
          startTime: startTime,
          endTime: endTime,
          subject: subject,
        ),
      );
    }

    return rows;
  }

  String _cellValue(List<Data?> row, int index, {String fallback = ''}) {
    if (index < 0 || index >= row.length) {
      return fallback;
    }

    return row[index]?.value?.toString().trim() ?? fallback;
  }
}

class TimetableImportRow {
  const TimetableImportRow({
    required this.facultyName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
  });

  final String facultyName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String subject;
}

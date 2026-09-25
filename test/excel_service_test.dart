import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profhere/data/services/excel_service.dart';

void main() {
  test('parseTimetableRows reads expected timetable columns', () {
    final workbook = Excel.createExcel();
    final sheet = workbook['Sheet1'];

    sheet.appendRow(<CellValue>[
      TextCellValue('Faculty'),
      TextCellValue('Day'),
      TextCellValue('Start Time'),
      TextCellValue('End Time'),
      TextCellValue('Subject'),
    ]);
    sheet.appendRow(<CellValue>[
      TextCellValue('Prof. Arjun Iyer'),
      TextCellValue('Monday'),
      TextCellValue('10:00'),
      TextCellValue('11:00'),
      TextCellValue('Data Structures'),
    ]);

    final bytes = Uint8List.fromList(workbook.save()!);
    final rows = ExcelService().parseTimetableRows(bytes);

    expect(rows, hasLength(1));
    expect(rows.first.facultyName, 'Prof. Arjun Iyer');
    expect(rows.first.dayOfWeek, 'Monday');
    expect(rows.first.startTime, '10:00');
    expect(rows.first.endTime, '11:00');
    expect(rows.first.subject, 'Data Structures');
  });
}

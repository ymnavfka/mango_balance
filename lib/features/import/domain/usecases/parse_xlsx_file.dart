import 'dart:typed_data';

import '../../data/parsers/xlsx_import_parser.dart';
import '../entities/parsed_import.dart';

class ParseXlsxFile {
  ParseXlsxFile(this.parser);

  final XlsxImportParser parser;

  ParsedImport call(Uint8List bytes) => parser.parse(bytes);
}

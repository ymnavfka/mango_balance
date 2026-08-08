import 'dart:typed_data';

import '../../data/parsers/xlsx_import_parser.dart';
import '../entities/parsed_file.dart';

class ParseXlsxFile {
  ParseXlsxFile(this.parser);

  final XlsxImportParser parser;

  ParsedFile call(Uint8List bytes) => parser.parse(bytes);
}

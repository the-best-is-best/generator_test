import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:generator_test/src/domain/domain.dart';

/// Retrieves the file content from the [GeneratorPath.input]/[fileName].dart file.
///
/// [addPart] adds `part '[fileName].g.dart';' to the file after imports
String inputContent(
  String fileName, {
  bool addPart = false,
  bool format = true,
}) {
  final path = '${GeneratorPath.input}/$fileName.dart';

  String? part;

  if (addPart) {
    part = "part '$fileName.g.dart';";
  }

  final content = getFileContent(
    path,
    part: part,
    format: format,
  );

  return content;
}

/// Retrieves the file content from the [GeneratorPath.output]/[fileName].dart file.
///
/// Automatically adds
/// - `part of '[fileName].dart';`
/// - `// GENERATED CODE - DO NOT MODIFY BY HAND`
/// - Generator's name (`T`) comment
String outputContent(
  String fileName,
  Type generatorType, {
  bool format = true,
}) {
  return outputContentMultiGen(
    fileName,
    ['$generatorType'],
    format: format,
  );
}

/// Gets the output content from the given [fileName].
String outputContentMultiGen(
  String fileName,
  Iterable<String> type, {
  bool format = true,
}) {
  final path = '${GeneratorPath.output}/$fileName.dart';

  final output = getFileContent(path, format: format);
  const generatedByHand = '// GENERATED CODE - DO NOT MODIFY BY HAND\n';

  final part = "part of '$fileName.dart';\n";

  // TODO: look into how this looks with multiple generators
  final generator = '''
// **************************************************************************
// ${type.first}
// **************************************************************************''';

  final result = [generatedByHand, part, generator, output].join('\n');

  return result;
}

/// gets the file's content from the given [path].
String getFileContent(
  String path, {
  String? part,
  bool format = false,
}) {
  final file = File(path);

  if (!file.existsSync()) {
    throw Exception('File not found: $path');
  }

  final content = file.readAsStringSync();

  final partRegex = RegExp("part .*';\n");

  if (content.contains(partRegex)) {
    return content.replaceFirst(RegExp("part .*';\n"), part ?? '');
  }

  if (!content.contains(RegExp('import .*;'))) {
    return [part ?? '', content].join('\n');
  }

  if (part == null) {
    return content;
  }

  final lines = content.split('\n');
  final indexAfterImport = lines.indexWhere(
    (line) =>
        !line.startsWith(RegExp(r'^(import|//|\s)', multiLine: true)) &&
        line.isNotEmpty,
  );

  lines.insertAll(indexAfterImport, [part, '']);

  final result = lines.join('\n');

  if (format) {
    return formatContent(result);
  }

  return result;
}

/// formats the [content] to dart's code style
String formatContent(String content) {
  final formatter = DartFormatter();
  try {
    return formatter.format(content);
  } catch (e) {
    // ignore: avoid_print
    print('Could not format content. Error: $e');
    return content;
  }
}

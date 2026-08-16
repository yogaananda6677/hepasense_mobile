import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract class ReportPlatformService {
  Future<String> writeTemporaryPdf(Uint8List bytes, String filename);
  Future<void> openPdf(String path);
  Future<void> sharePdf(String path);
}

class SystemReportPlatformService implements ReportPlatformService {
  String? _lastTemporaryPath;

  @override
  Future<String> writeTemporaryPdf(Uint8List bytes, String filename) async {
    final directory = await getTemporaryDirectory();
    final safeFilename =
        RegExp(r'^hepasense-hasil-skrining-\d{8}\.pdf$').hasMatch(filename)
        ? filename
        : 'hepasense-hasil-skrining.pdf';
    final previous = _lastTemporaryPath;
    if (previous != null && previous != '${directory.path}/$safeFilename') {
      final previousFile = File(previous);
      if (await previousFile.exists()) await previousFile.delete();
    }
    final file = File('${directory.path}/$safeFilename');
    await file.writeAsBytes(bytes, flush: true);
    _lastTemporaryPath = file.path;
    return file.path;
  }

  @override
  Future<void> openPdf(String path) async {
    final result = await OpenFilex.open(path, type: 'application/pdf');
    if (result.type != ResultType.done) {
      throw const ReportPlatformException(
        'Tidak ada aplikasi yang dapat membuka PDF ini.',
      );
    }
  }

  @override
  Future<void> sharePdf(String path) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/pdf')],
        title: 'Hasil Skrining HepaSense',
        text: 'Hasil skrining HepaSense',
      ),
    );
    if (result.status == ShareResultStatus.unavailable) {
      throw const ReportPlatformException(
        'Fitur berbagi belum tersedia pada perangkat ini.',
      );
    }
  }
}

class ReportPlatformException implements Exception {
  const ReportPlatformException(this.message);
  final String message;
}

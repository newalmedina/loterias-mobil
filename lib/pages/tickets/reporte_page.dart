import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// 🔥 ESTE ERA EL QUE FALTABA
import 'package:esc_pos_utils/esc_pos_utils.dart';

class ReporteTicketService {
  // =========================
  // 1. DISEÑO
  // =========================
  List<String> buildLines({
    required List<dynamic> ventas,
    required String title,
  }) {
    List<String> lines = [];

    lines.add(title);
    lines.add("--------------------------------");

    for (final v in ventas) {
      lines.add("VENTA: ${v['code']}");
      lines.add("FECHA: ${v['date']}");

      final details = v['details'] ?? [];

      for (final d in details) {
        lines.add(
          "${d['short_name']} ${d['number_formatted']} ${d['type']} ${d['monto_jugada']}",
        );
      }

      lines.add("--------------------------------");
    }

    return lines;
  }

  // =========================
  // 2. ESC/POS PRINT
  // =========================
  Future<List<int>> buildTicket({
    required List<dynamic> ventas,
    required String title,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    final lines = buildLines(ventas: ventas, title: title);

    List<int> bytes = [];

    for (int i = 0; i < lines.length; i++) {
      final text = lines[i];

      if (i == 0) {
        bytes += generator.text(
          text,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
          ),
        );
      } else {
        bytes += generator.text(text);
      }
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  // =========================
  // 3. PREVIEW
  // =========================
  Future<File> buildPreviewImage({
    required List<dynamic> ventas,
    required String title,
  }) async {
    final lines = buildLines(ventas: ventas, title: title);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const width = 576.0;
    double y = 20;

    void draw(
      String text, {
      double size = 14,
      FontWeight weight = FontWeight.normal,
    }) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: size, fontWeight: weight),
        ),
        textDirection: TextDirection.ltr,
      );

      tp.layout(maxWidth: width - 20);
      tp.paint(canvas, Offset(10, y));
      y += tp.height + 6;
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (i == 0) {
        draw(line, size: 18, weight: FontWeight.bold);
      } else {
        draw(line);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), y.toInt());

    final byteData = await img.toByteData(
      format: ui.ImageByteFormat.png,
    );

    final file = File(
      "${(await getTemporaryDirectory()).path}/ticket.png",
    );

    await file.writeAsBytes(byteData!.buffer.asUint8List());

    return file;
  }

  // =========================
  // 4. SHARE
  // =========================
  Future<void> sharePreview({
    required List<dynamic> ventas,
    required String title,
  }) async {
    final file = await buildPreviewImage(
      ventas: ventas,
      title: title,
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text: title,
    );
  }
}

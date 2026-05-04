import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

class PdfGenerator {
  static Future<void> generateAndShareInventory(
    List<Product> products, {
    String? label,
    String restaurantName = 'Cathédrale',
    String createdBy = 'Anonyme',
    bool isSingleSection = false,
  }) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pw.SvgImage? logoSvg;
    try {
      final svgString = await rootBundle.loadString('assets/images/STAS_LOGOMACA1_VECT.svg');
      logoSvg = pw.SvgImage(svg: svgString);
    } catch (_) {}

    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final primaryColor = PdfColor.fromHex('#4F46E5'); 
    final darkBg = PdfColor.fromHex('#1E293B');
    final accentColor = PdfColor.fromHex('#10B981');
    final mutedText = PdfColor.fromHex('#64748B');
    final borderCol = PdfColor.fromHex('#E2E8F0');

    final totalValueHT = products.fold<double>(0, (sum, p) => sum + (p.quantity * p.priceHT));
    final totalValueTTC = totalValueHT * 1.2;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(restaurantName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20, color: primaryColor)),
                      pw.Text(label ?? "RELEVE D'INVENTAIRE", style: pw.TextStyle(fontSize: 12, color: darkBg, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  if (logoSvg != null) pw.Container(height: 60, width: 120, child: logoSvg),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8FAFC'), borderRadius: pw.BorderRadius.circular(8), border: pw.Border.all(color: borderCol)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _statBlock('DATE', '$dateStr - $timeStr', mutedText, darkBg),
                    _statBlock('OPERATEUR', createdBy.toUpperCase(), mutedText, darkBg),
                    _statBlock('VALEUR HT', '${totalValueHT.toStringAsFixed(2)} \u20AC', mutedText, primaryColor),
                    _statBlock('VALEUR TTC', '${totalValueTTC.toStringAsFixed(2)} \u20AC', mutedText, accentColor),
                  ],
                ),
              ),
            ],
          ),
        ),
        build: (context) {
          final sections = isSingleSection ? { 'GENERAL': products } : {
            'BAR': products.where((p) => p.space == SpaceType.bar).toList(),
            'METRO': products.where((p) => p.space == SpaceType.metro).toList(),
            'LABO': products.where((p) => p.space == SpaceType.labo).toList(),
          };

          final widgets = <pw.Widget>[];
          for (final entry in sections.entries) {
            if (entry.value.isEmpty) continue;
            
            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 10, bottom: 8),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Text('SECTION : ${entry.key}', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9)),
              ),
            );
            
            widgets.add(_buildTable(entry.value, borderCol));
            widgets.add(pw.SizedBox(height: 15));
          }
          return widgets;
        },
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text('Page ${context.pageNumber} / ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        ),
      ),
    );

    final filename = 'Inventaire_${restaurantName}_$dateStr.pdf'.replaceAll(' ', '_').replaceAll('/', '-');
    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }

  static pw.Widget _statBlock(String label, String val, PdfColor labelCol, PdfColor valCol) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 7, color: labelCol, fontWeight: pw.FontWeight.bold)),
      pw.Text(val, style: pw.TextStyle(fontSize: 9, color: valCol, fontWeight: pw.FontWeight.bold)),
    ],
  );

  static pw.Widget _buildTable(List<Product> products, PdfColor border) {
    return pw.Table(
      border: pw.TableBorder.all(color: border, width: 0.5),
      columnWidths: { 0: const pw.FlexColumnWidth(4), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(1.5) },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
          children: ['ARTICLE', 'STOCK', 'UNITE', 'VALEUR HT'].map((t) => pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          )).toList(),
        ),
        ...products.map((p) {
          final isLow = p.quantity <= p.minQuantity;
          return pw.TableRow(
            children: [
              _cell(p.name, isLow: isLow),
              _cell(_fmt(p.quantity), isLow: isLow, align: pw.Alignment.center),
              _cell(p.unit, align: pw.Alignment.center),
              _cell('${(p.quantity * p.priceHT).toStringAsFixed(2)} \u20AC', align: pw.Alignment.center),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(String text, { bool isLow = false, pw.Alignment align = pw.Alignment.centerLeft }) => pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Container(
      alignment: align,
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, color: isLow ? PdfColor.fromHex('#EF4444') : null, fontWeight: isLow ? pw.FontWeight.bold : null)),
    ),
  );

  static String _fmt(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}

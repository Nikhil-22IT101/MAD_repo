import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> items = [];

  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  double gstRate = 18.0;
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDark = prefs.getBool('theme') ?? false;
    });
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDark = !isDark;
    });
    await prefs.setBool('theme', isDark);
  }

  void _addItem() {
    if (nameController.text.isEmpty || priceController.text.isEmpty) return;

    double price = double.tryParse(priceController.text) ?? 0;
    double cgst = (price * gstRate / 100) / 2;
    double sgst = cgst;
    double total = price + cgst + sgst;

    setState(() {
      items.add({
        'name': nameController.text,
        'price': price,
        'gst': gstRate,
        'cgst': cgst,
        'sgst': sgst,
        'total': total,
      });
      nameController.clear();
      priceController.clear();
    });
  }

  void _clearInvoice() {
    setState(() {
      items.clear();
    });
  }

  Map<String, double> _calculateTotals() {
    double subtotal = 0;
    double totalCgst = 0;
    double totalSgst = 0;

    for (var item in items) {
      subtotal += item['price'];
      totalCgst += item['cgst'];
      totalSgst += item['sgst'];
    }

    double grandTotal = subtotal + totalCgst + totalSgst;
    return {
      'subtotal': subtotal,
      'cgst': totalCgst,
      'sgst': totalSgst,
      'grandTotal': grandTotal,
    };
  }

  Future<void> _generatePdfInvoice() async {
    final pdf = pw.Document();
    final totals = _calculateTotals();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Invoice', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Name', 'Price', 'CGST', 'SGST', 'Total'],
              data: items.map((e) {
                return [
                  e['name'],
                  e['price'].toStringAsFixed(2),
                  e['cgst'].toStringAsFixed(2),
                  e['sgst'].toStringAsFixed(2),
                  e['total'].toStringAsFixed(2),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey600),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _pdfSummaryRow('Subtotal', totals['subtotal']!),
                  _pdfSummaryRow('Total CGST', totals['cgst']!),
                  _pdfSummaryRow('Total SGST', totals['sgst']!),
                  pw.Divider(),
                  _pdfSummaryRow('Grand Total', totals['grandTotal']!, isBold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _pdfSummaryRow(String label, double value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              )),
          pw.Text('₹${value.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('GST Billing App'),
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleTheme,
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _inputCard(),
              const SizedBox(height: 20),
              Expanded(child: _productList()),
              _buildTotalSummary(),
              const SizedBox(height: 10),
              _footerButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (₹)'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<double>(
              value: gstRate,
              decoration: const InputDecoration(labelText: 'GST Rate'),
              items: [5, 12, 18, 28].map((rate) {
                return DropdownMenuItem<double>(
                  value: rate.toDouble(),
                  child: Text('$rate%'),
                );
              }).toList(),
              onChanged: (value) => setState(() => gstRate = value ?? 18),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productList() {
    if (items.isEmpty) {
      return const Center(child: Text('No products added yet.'));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: const Icon(Icons.shopping_cart),
          title: Text(item['name']),
          subtitle: Text(
              'Price: ₹${item['price'].toStringAsFixed(2)}\nCGST: ₹${item['cgst'].toStringAsFixed(2)}, SGST: ₹${item['sgst'].toStringAsFixed(2)}'),
          trailing: Text('₹${item['total'].toStringAsFixed(2)}'),
        );
      },
    );
  }

  Widget _buildTotalSummary() {
    final totals = _calculateTotals();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invoice Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _summaryRow('Subtotal:', totals['subtotal']!),
            _summaryRow('Total CGST:', totals['cgst']!),
            _summaryRow('Total SGST:', totals['sgst']!),
            const Divider(),
            _summaryRow('Grand Total:', totals['grandTotal']!, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('₹${value.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _footerButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: _clearInvoice,
          icon: const Icon(Icons.clear),
          label: const Text('Clear Invoice'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
        ElevatedButton.icon(
          onPressed: _generatePdfInvoice,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Download PDF'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
        ),
      ],
    );
  }
}

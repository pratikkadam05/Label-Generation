import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/pdf_service.dart';
import '../services/bluetooth_printer_service.dart';

class PrintPreviewScreen extends StatefulWidget {
  final UserModel user;
  final int copies;

  const PrintPreviewScreen({
    super.key,
    required this.user,
    required this.copies,
  });

  @override
  State<PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends State<PrintPreviewScreen> {
  final PdfService _pdfService = PdfService();
  final BluetoothPrinterService _bluetoothService = BluetoothPrinterService();
  bool _isLoading = false;
  bool _isBluetoothPrinting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview (${widget.copies} labels)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _printLabels,
            icon: const Icon(Icons.print),
            tooltip: 'Print',
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Preview shows how ${widget.copies} labels will appear on the page',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Preview Grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page simulation
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Page Preview',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          // Compact grid of labels (3 columns, showing max 24 on preview)
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: List.generate(
                              widget.copies > 24 ? 24 : widget.copies,
                              (index) => _buildLabelPreview(context),
                            ),
                          ),
                          if (widget.copies > 24) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.more_horiz, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+ ${widget.copies - 24} more labels',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Divider(),
                          _buildDetailRow(Icons.person, 'Name', widget.user.name),
                          _buildDetailRow(
                              Icons.location_on, 'Address', widget.user.address),
                          _buildDetailRow(Icons.phone, 'Phone', widget.user.phone),
                          _buildDetailRow(
                              Icons.copy, 'Copies', '${widget.copies}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bluetooth printer status
                  if (_bluetoothService.isConnected &&
                      _bluetoothService.connectedDevice != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bluetooth_connected,
                              color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Connected: ${_bluetoothService.connectedDevice!.name ?? "Printer"}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await _bluetoothService.disconnect();
                              setState(() {});
                            },
                            child: Icon(Icons.close,
                                color: Colors.green.shade700, size: 20),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      // Bluetooth Print Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (_isLoading || _isBluetoothPrinting)
                              ? null
                              : _bluetoothPrint,
                          icon: _isBluetoothPrinting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.bluetooth),
                          label: const Text('Bluetooth'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // System Print Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _printLabels,
                          icon: const Icon(Icons.print),
                          label: const Text('System'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Download PDF Button
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _downloadPdf,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download),
                          label: const Text('PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelPreview(BuildContext context) {
    // Calculate width for 3 labels per row with spacing
    final screenWidth = MediaQuery.of(context).size.width;
    final labelWidth = (screenWidth - 32 - 32 - 8) / 3;

    return Container(
      width: labelWidth,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.user.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            widget.user.address,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            widget.user.phone,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf() async {
    setState(() => _isLoading = true);

    try {
      await _pdfService.downloadPdf(widget.user, widget.copies);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _printLabels() async {
    setState(() => _isLoading = true);

    try {
      await _pdfService.printLabels(widget.user, widget.copies);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _bluetoothPrint() async {
    // Check if already connected
    if (!_bluetoothService.isConnected) {
      // Show printer selection dialog
      final device = await BluetoothPrinterService.showPrinterDialog(context);
      if (device == null) {
        return; // User cancelled
      }
      setState(() {}); // Update UI to show connected printer
    }

    // Print labels
    setState(() => _isBluetoothPrinting = true);

    try {
      await _bluetoothService.printLabels(widget.user, widget.copies);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Labels printed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBluetoothPrinting = false);
      }
    }
  }
}

import 'dart:async';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance =
      BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  final BluetoothPrint _bluetoothPrint = BluetoothPrint.instance;
  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;

  // Getters
  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  Stream<bool> get isScanning => _bluetoothPrint.isScanning;

  // Request Bluetooth permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );
  }

  // Check if Bluetooth is available
  Future<bool> isBluetoothAvailable() async {
    return await _bluetoothPrint.isAvailable;
  }

  // Check if Bluetooth is on
  Future<bool> isBluetoothOn() async {
    return await _bluetoothPrint.isOn;
  }

  // Start scanning for devices
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      throw Exception('Bluetooth permissions not granted');
    }

    final isAvailable = await isBluetoothAvailable();
    if (!isAvailable) {
      throw Exception('Bluetooth is not available on this device');
    }

    final isOn = await isBluetoothOn();
    if (!isOn) {
      throw Exception('Please turn on Bluetooth');
    }

    await _bluetoothPrint.startScan(timeout: timeout);
  }

  // Stop scanning
  Future<void> stopScan() async {
    await _bluetoothPrint.stopScan();
  }

  // Get scan results stream
  Stream<List<BluetoothDevice>> get scanResults => _bluetoothPrint.scanResults;

  // Connect to a device
  Future<bool> connect(BluetoothDevice device) async {
    try {
      await _bluetoothPrint.connect(device);
      _connectedDevice = device;
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      _connectedDevice = null;
      return false;
    }
  }

  // Disconnect from device
  Future<void> disconnect() async {
    await _bluetoothPrint.disconnect();
    _isConnected = false;
    _connectedDevice = null;
  }

  // Listen to connection state
  Stream<int> get state => _bluetoothPrint.state;

  // Print user labels
  Future<void> printLabels(UserModel user, int copies) async {
    if (!_isConnected || _connectedDevice == null) {
      throw Exception('No printer connected');
    }

    Map<String, dynamic> config = {};

    List<LineText> lines = [];

    for (int i = 0; i < copies; i++) {
      // Add separator line for each label except the first
      if (i > 0) {
        lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '--------------------------------',
          align: LineText.ALIGN_CENTER,
          linefeed: 1,
        ));
      }

      // Name - Bold and larger
      lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: user.name,
        weight: 1,
        align: LineText.ALIGN_CENTER,
        fontZoom: 2,
        linefeed: 1,
      ));

      // Address
      lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: user.address,
        align: LineText.ALIGN_CENTER,
        linefeed: 1,
      ));

      // Phone
      lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Phone: ${user.phone}',
        align: LineText.ALIGN_CENTER,
        linefeed: 1,
      ));

      // Empty line between labels
      lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '',
        linefeed: 1,
      ));
    }

    // Final separator
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '================================',
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));

    await _bluetoothPrint.printReceipt(config, lines);
  }

  // Print test page
  Future<void> printTestPage() async {
    if (!_isConnected || _connectedDevice == null) {
      throw Exception('No printer connected');
    }

    Map<String, dynamic> config = {};

    List<LineText> lines = [
      LineText(
        type: LineText.TYPE_TEXT,
        content: '================================',
        align: LineText.ALIGN_CENTER,
        linefeed: 1,
      ),
      LineText(
        type: LineText.TYPE_TEXT,
        content: 'PRINTER TEST',
        weight: 1,
        align: LineText.ALIGN_CENTER,
        fontZoom: 2,
        linefeed: 1,
      ),
      LineText(
        type: LineText.TYPE_TEXT,
        content: '================================',
        align: LineText.ALIGN_CENTER,
        linefeed: 1,
      ),
      LineText(
        type: LineText.TYPE_TEXT,
        content: 'Connection Successful!',
        align: LineText.ALIGN_CENTER,
        linefeed: 1,
      ),
      LineText(
        type: LineText.TYPE_TEXT,
        content: 'Billing Application',
        align: LineText.ALIGN_CENTER,
        linefeed: 1,
      ),
      LineText(
        type: LineText.TYPE_TEXT,
        content: DateTime.now().toString(),
        align: LineText.ALIGN_CENTER,
        linefeed: 1,
      ),
      LineText(
        type: LineText.TYPE_TEXT,
        content: '================================',
        align: LineText.ALIGN_CENTER,
        linefeed: 1,
      ),
      LineText(
        type: LineText.TYPE_TEXT,
        content: '',
        linefeed: 3,
      ),
    ];

    await _bluetoothPrint.printReceipt(config, lines);
  }

  // Show printer selection dialog
  static Future<BluetoothDevice?> showPrinterDialog(
      BuildContext context) async {
    return showDialog<BluetoothDevice>(
      context: context,
      builder: (context) => const BluetoothPrinterDialog(),
    );
  }
}

// Bluetooth Printer Selection Dialog Widget
class BluetoothPrinterDialog extends StatefulWidget {
  const BluetoothPrinterDialog({super.key});

  @override
  State<BluetoothPrinterDialog> createState() => _BluetoothPrinterDialogState();
}

class _BluetoothPrinterDialogState extends State<BluetoothPrinterDialog> {
  final BluetoothPrinterService _printerService = BluetoothPrinterService();
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startScan();

    // Listen to scan results
    _printerService.scanResults.listen((devices) {
      if (mounted) {
        setState(() {
          _devices = devices;
        });
      }
    });

    // Listen to scanning state
    _printerService.isScanning.listen((scanning) {
      if (mounted) {
        setState(() {
          _isScanning = scanning;
        });
      }
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _error = null;
      _devices = [];
    });

    try {
      await _printerService.startScan();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final success = await _printerService.connect(device);
      if (success && mounted) {
        Navigator.of(context).pop(device);
      } else if (mounted) {
        setState(() {
          _error = 'Failed to connect to ${device.name}';
          _isConnecting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Connection error: $e';
          _isConnecting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _printerService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bluetooth, color: Colors.blue),
          const SizedBox(width: 8),
          const Expanded(child: Text('Select Printer')),
          if (_isScanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isScanning
                                ? Icons.bluetooth_searching
                                : Icons.bluetooth_disabled,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isScanning
                                ? 'Searching for printers...'
                                : 'No printers found',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (!_isScanning) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _startScan,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Scan Again'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return ListTile(
                          leading: const Icon(Icons.print, color: Colors.blue),
                          title: Text(device.name ?? 'Unknown Device'),
                          subtitle: Text(device.address ?? ''),
                          trailing: _isConnecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap:
                              _isConnecting ? null : () => _connectToDevice(device),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (!_isScanning)
          TextButton.icon(
            onPressed: _startScan,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
      ],
    );
  }
}

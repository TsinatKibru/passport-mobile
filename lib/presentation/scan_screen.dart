import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/repositories/passport_repository.dart';
import '../data/repositories/box_repository.dart';
import '../core/theme/app_theme.dart';

class ScanScreen extends ConsumerStatefulWidget {
  final String mode; // 'assign', 'move_box', 'issue'

  const ScanScreen({super.key, required this.mode});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _passportRepo = PassportRepository();
  final _boxRepo = BoxRepository();
  final _manualController = TextEditingController();

  // Scan state
  bool _isScanning = true;
  String? _scannedBoxQr;
  Map<String, dynamic>? _scannedBox;
  final List<Map<String, dynamic>> _scannedPassports = [];
  Map<String, dynamic>? _scannedSlot;
  Map<String, dynamic>? _targetPassport;

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      _processCode(barcode!.rawValue!);
    }
  }

  Future<void> _processCode(String code) async {
    setState(() {
      _isScanning = false;
    });

    try {
      if (widget.mode == 'assign') {
        if (_scannedBoxQr == null) {
          // Scanning Box first
          final box = await _boxRepo.getByQr(code);
          setState(() {
            _scannedBox = box;
            _scannedBoxQr = code;
          });
          _showSuccess('Box ${box['label']} scanned');
        } else {
          // Scanning Passports next
          // Check if already in list
          if (_scannedPassports.any((p) => p['qrCode'] == code)) {
            _showError('Passport already in scan list');
            return;
          }
          final passport = await _passportRepo.getByQr(code);
          setState(() {
            _scannedPassports.add(passport);
          });
          _showSuccess('Passport for ${passport['holderName']} scanned');
        }
      } else if (widget.mode == 'move_box') {
        if (_scannedBoxQr == null) {
          final box = await _boxRepo.getByQr(code);
          setState(() {
            _scannedBox = box;
            _scannedBoxQr = code;
          });
          _showSuccess('Box ${box['label']} scanned');
        } else {
          // Scan Slot next
          final dio = _boxRepo.dio;
          final res = await dio.get('/location/slots/qr/$code');
          setState(() {
            _scannedSlot = res.data;
          });
          _showSuccess('Slot ${res.data['name']} scanned');
        }
      } else if (widget.mode == 'issue') {
        final passport = await _passportRepo.getByQr(code);
        setState(() {
          _targetPassport = passport;
        });
        _showSuccess('Passport for ${passport['holderName']} scanned');
      }
    } catch (e) {
      _showError('Entity lookup failed for: $code');
    } finally {
      setState(() {
        _isScanning = true;
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitAssignment() async {
    if (_scannedBox == null || _scannedPassports.isEmpty) return;
    try {
      final passportIds = _scannedPassports.map((p) => p['id'] as String).toList();
      await _passportRepo.batchAssign(
        passportIds: passportIds,
        boxId: _scannedBox!['id'],
        action: 'PASSPORT_ASSIGNED',
      );
      if (mounted) {
        _showSuccess('Successfully assigned ${_scannedPassports.length} passports');
        context.pop();
      }
    } catch (e) {
      _showError('Batch assignment failed');
    }
  }

  Future<void> _submitBoxMove() async {
    if (_scannedBox == null || _scannedSlot == null) return;
    try {
      await _boxRepo.move(_scannedBox!['id'], _scannedSlot!['id']);
      if (mounted) {
        _showSuccess('Box successfully moved to slot ${_scannedSlot!['name']}');
        context.pop();
      }
    } catch (e) {
      _showError('Box move failed');
    }
  }

  Future<void> _submitPassportIssue() async {
    if (_targetPassport == null) return;
    try {
      await _passportRepo.issue(_targetPassport!['id']);
      if (mounted) {
        _showSuccess('Passport successfully issued');
        context.pop();
      }
    } catch (e) {
      _showError('Passport issue failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleText = 'Scanner';
    if (widget.mode == 'assign') titleText = 'Assign Passports';
    if (widget.mode == 'move_box') titleText = 'Move Box';
    if (widget.mode == 'issue') titleText = 'Issue Passport';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
      ),
      body: Column(
        children: [
          // 1. Camera Scanning View
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: _onDetect,
                ),
                // Scanner Overlay bounding box
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryLight, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Camera status text indicator
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isScanning ? 'Scan a QR code' : 'Processing...',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Manual Entry Fallback (For simulator/convenience testing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualController,
                    decoration: const InputDecoration(
                      hintText: 'Enter QR Label Manually...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    final code = _manualController.text.trim();
                    if (code.isNotEmpty) {
                      _processCode(code);
                      _manualController.clear();
                    }
                  },
                  icon: const Icon(Icons.send, color: AppColors.primary),
                )
              ],
            ),
          ),

          // 3. Status Information & Action buttons
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildStateContent(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSubmitButton(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStateContent() {
    if (widget.mode == 'assign') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Box Info
          if (_scannedBox != null) ...[
            Text('TARGET BOX', style: AppTextStyles.labelSmall),
            const SizedBox(height: 8),
            Card(
              color: AppColors.surfaceVariant,
              child: ListTile(
                leading: const Icon(Icons.inventory_2, color: AppColors.primary),
                title: Text(_scannedBox!['label'] ?? '', style: AppTextStyles.titleMedium),
                subtitle: Text('Capacity: ${_scannedBox!['occupiedCount']} / ${_scannedBox!['capacity']}'),
              ),
            ),
            const SizedBox(height: 20),
            Text('SCANNED PASSPORTS (${_scannedPassports.length})', style: AppTextStyles.labelSmall),
            const SizedBox(height: 8),
            if (_scannedPassports.isEmpty)
              Text('Scan passport QR codes to append...', style: AppTextStyles.caption)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _scannedPassports.length,
                itemBuilder: (context, idx) {
                  final p = _scannedPassports[idx];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.description, color: Colors.blue),
                      title: Text(p['holderName'] ?? ''),
                      subtitle: Text(p['qrCode'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                        onPressed: () {
                          setState(() {
                            _scannedPassports.removeAt(idx);
                          });
                        },
                      ),
                    ),
                  );
                },
              )
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Text(
                  'Please scan the Box QR code to begin',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            )
          ]
        ],
      );
    } else if (widget.mode == 'move_box') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_scannedBox != null) ...[
            Text('BOX TO MOVE', style: AppTextStyles.labelSmall),
            const SizedBox(height: 8),
            Card(
              color: AppColors.surfaceVariant,
              child: ListTile(
                leading: const Icon(Icons.inventory_2, color: AppColors.primary),
                title: Text(_scannedBox!['label'] ?? '', style: AppTextStyles.titleMedium),
                subtitle: Text('QR: ${_scannedBox!['qrCode']}'),
              ),
            ),
            const SizedBox(height: 20),
            if (_scannedSlot != null) ...[
              Text('DESTINATION SLOT', style: AppTextStyles.labelSmall),
              const SizedBox(height: 8),
              Card(
                color: AppColors.surfaceVariant,
                child: ListTile(
                  leading: const Icon(Icons.place, color: Colors.deepPurple),
                  title: Text(_scannedSlot!['name'] ?? '', style: AppTextStyles.titleMedium),
                  subtitle: Text(_scannedSlot!['location'] ?? ''),
                ),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30.0),
                  child: Text(
                    'Scan the target Slot QR code next',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              )
            ]
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Text(
                  'Please scan the Box QR code to begin',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            )
          ]
        ],
      );
    } else {
      // mode == 'issue'
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_targetPassport != null) ...[
            Text('PASSPORT TO ISSUE', style: AppTextStyles.labelSmall),
            const SizedBox(height: 8),
            Card(
              color: AppColors.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_targetPassport!['holderName'] ?? '', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 8),
                    Text('ID No: ${_targetPassport!['holderIdNo']}'),
                    Text('QR Code: ${_targetPassport!['qrCode']}'),
                    const SizedBox(height: 12),
                    Text('Current Status: ${_targetPassport!['status']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Text(
                  'Please scan the Passport QR code to issue',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            )
          ]
        ],
      );
    }
  }

  Widget _buildSubmitButton() {
    if (widget.mode == 'assign') {
      return ElevatedButton(
        onPressed: (_scannedBox != null && _scannedPassports.isNotEmpty) ? _submitAssignment : null,
        child: const Text('Confirm Assignment'),
      );
    } else if (widget.mode == 'move_box') {
      return ElevatedButton(
        onPressed: (_scannedBox != null && _scannedSlot != null) ? _submitBoxMove : null,
        child: const Text('Confirm Box Move'),
      );
    } else {
      return ElevatedButton(
        onPressed: (_targetPassport != null) ? _submitPassportIssue : null,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
        child: const Text('Confirm Issue to Owner'),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/passport_repository.dart';
import '../../../data/repositories/box_repository.dart';
import '../../../data/models/passport.dart';
import '../../../data/models/box.dart' as models;
import '../widgets/glass_card.dart';
import '../widgets/fingerprint_background.dart';

class PassportReturnPage extends StatefulWidget {
  const PassportReturnPage({super.key});

  @override
  State<PassportReturnPage> createState() => _PassportReturnPageState();
}

class _PassportReturnPageState extends State<PassportReturnPage> {
  final PassportRepository _passportRepo = PassportRepository();
  final BoxRepository _boxRepo = BoxRepository();

  // Step state
  int _currentStep = 1; // 1: Scan Passports, 2: Select Box, 3: Verify & Confirm

  // Scanned Passports Stack
  final List<Passport> _scannedPassports = [];

  // Storage Box State
  List<models.Box> _availableBoxes = [];
  models.Box? _selectedBox;
  bool _isLoadingBoxes = false;
  final TextEditingController _boxSearchController = TextEditingController();

  // Verification state
  bool _isSubmitting = false;
  String? _scannedSlotQr;

  @override
  void dispose() {
    _boxSearchController.dispose();
    super.dispose();
  }

  void _addPassportByQr(String code) async {
    if (_scannedPassports.any((p) => p.qrCode == code)) {
      _showFeedback('Passport already in stack', true);
      return;
    }

    try {
      final passport = await _passportRepo.getByQr(code);
      if (passport == null) {
        _showFeedback('Passport not found in system: $code', true);
        return;
      }

      setState(() {
        _scannedPassports.add(passport);
      });
      _showFeedback('Added: ${passport.holderName}', false);
    } catch (e) {
      _showFeedback('Error looking up passport: $e', true);
    }
  }

  void _loadAvailableBoxes() async {
    setState(() {
      _isLoadingBoxes = true;
      _currentStep = 2;
    });

    try {
      final boxes = await _boxRepo.getAvailable(_scannedPassports.length);
      setState(() {
        _availableBoxes = boxes;
        _isLoadingBoxes = false;
      });
    } catch (e) {
      setState(() => _isLoadingBoxes = false);
      _showFeedback('Failed to load matching boxes', true);
    }
  }

  void _lookupBoxManually(String qrCode) async {
    setState(() => _isLoadingBoxes = true);
    try {
      final box = await _boxRepo.getByQr(qrCode);
      setState(() {
        _isLoadingBoxes = false;
        if (box != null) {
          _selectedBox = box;
          _currentStep = 3;
        } else {
          _showFeedback('Box not found: $qrCode', true);
        }
      });
    } catch (e) {
      setState(() => _isLoadingBoxes = false);
      _showFeedback('Box lookup failed', true);
    }
  }

  void _submitReturn({bool overrideLocation = false}) async {
    if (_selectedBox == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final passportIds = _scannedPassports.map((p) => p.id).toList();
      final res = await _passportRepo.batchAssign(
        passportIds: passportIds,
        boxId: _selectedBox!.id,
        slotQrCode: _scannedSlotQr,
        overrideLocation: overrideLocation,
        action: 'PASSPORT_RETURNED',
      );

      setState(() {
        _isSubmitting = false;
      });

      if (res) {
        _showSuccessDialog();
      } else {
        _showFeedback('Failed to process returns. Please check inputs.', true);
      }
    } on DioException catch (dioErr) {
      setState(() => _isSubmitting = false);
      final responseData = dioErr.response?.data;
      if (responseData is Map && responseData['error'] == 'LOCATION_MISMATCH') {
        _handleLocationMismatch(
          currentLocation: responseData['currentLocation'] ?? 'Unknown',
          scannedLocation: responseData['scannedLocation'] ?? 'Unknown',
        );
      } else {
        _showFeedback(responseData?['message'] ?? 'Network submission error', true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showFeedback('Return transaction failed: $e', true);
    }
  }

  void _handleLocationMismatch({required String currentLocation, required String scannedLocation}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Location Mismatch', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Box ${_selectedBox!.label} is registered at:\n"$currentLocation"\n\nBut physically found at:\n"$scannedLocation"\n\nWould you like to correct the box\'s storage address and assign these passports?',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textBody)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitReturn(overrideLocation: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Update & Assign'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, size: 54, color: AppColors.success),
        title: const Text('Return Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Successfully returned ${_scannedPassports.length} passports to Box ${_selectedBox!.label}. All custody locations updated.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop(); // Go back to dashboard
            },
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  void _showFeedback(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FingerprintBackground(
        child: Column(
          children: [
            // AppBar area
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark),
                      onPressed: () {
                        if (_currentStep > 1) {
                          setState(() => _currentStep--);
                        } else {
                          context.pop();
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Return Custody Flow',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Text(
                      'Step $_currentStep of 3',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textBody),
                    ),
                  ],
                ),
              ),
            ),

            // Step Indicator progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: List.generate(3, (idx) {
                  final stepNum = idx + 1;
                  final isActive = stepNum <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Main body steps
            Expanded(
              child: _buildStepContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  // --- STEP 1: Scan Passports ---
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  MobileScanner(
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      if (barcode?.rawValue != null) {
                        _addPassportByQr(barcode!.rawValue!);
                      }
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Card(
                        color: Colors.black54,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Scan Passport QR Codes to Stack',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Scanned Stack (${_scannedPassports.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
                    ),
                    const Spacer(),
                    if (_scannedPassports.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _scannedPassports.clear()),
                        child: const Text('Clear All', style: TextStyle(color: AppColors.danger)),
                      ),
                  ],
                ),
                Expanded(
                  child: _scannedPassports.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.qr_code_2_rounded, size: 48, color: AppColors.textHint),
                              SizedBox(height: 8),
                              Text('No passports scanned yet', style: TextStyle(color: AppColors.textBody)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _scannedPassports.length,
                          itemBuilder: (ctx, idx) {
                            final passport = _scannedPassports[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: Colors.white,
                              child: ListTile(
                                leading: const Icon(Icons.contact_mail_rounded, color: AppColors.primary),
                                title: Text(passport.holderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${passport.qrCode} • ID: ${passport.holderIdNo}'),
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
                        ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _scannedPassports.isEmpty ? null : _loadAvailableBoxes,
                  child: const Text('Find Storage Box'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: Select Box ---
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Target Storage Box',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark),
          ),
          Text(
            'Showing boxes with at least ${_scannedPassports.length} available slots',
            style: const TextStyle(color: AppColors.textBody, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // Search manual box input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _boxSearchController,
              onSubmitted: _lookupBoxManually,
              decoration: InputDecoration(
                hintText: 'Or scan/type Box QR Code (e.g. BOX-0001)...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingBoxes
                ? const Center(child: CircularProgressIndicator())
                : _availableBoxes.isEmpty
                    ? const Center(
                        child: Text('No suitable boxes found. Try searching manually.'),
                      )
                    : ListView.builder(
                        itemCount: _availableBoxes.length,
                        itemBuilder: (ctx, idx) {
                          final box = _availableBoxes[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.white,
                            child: ListTile(
                              leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                              title: Text(box.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Space: ${box.occupiedCount}/${box.capacity} occupied • ${box.location ?? "No Location"}',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                              onTap: () {
                                setState(() {
                                  _selectedBox = box;
                                  _currentStep = 3;
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: Verify Location & Confirm ---
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm & Verify Box Location',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(_selectedBox!.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      Chip(
                        label: Text('QR: ${_selectedBox!.qrCode}', style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text('Target Slots Required: ${_scannedPassports.length}', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('Box Current Slot: ${_selectedBox!.slot?.name ?? "No Slot Assigned"}', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('Physical Location Address:\n${_selectedBox!.location ?? "Unassigned"}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textBody, height: 1.3)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Scan Slot QR Code at Physical Location',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
          ),
          const Text(
            'Align and scan the QR code of the slot shelf to verify the box is correctly positioned.',
            style: TextStyle(fontSize: 12, color: AppColors.textBody),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.black12,
              child: _scannedSlotQr != null
                  ? Container(
                      color: AppColors.success.withOpacity(0.08),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 48),
                          const SizedBox(height: 12),
                          Text('Scanned Slot QR: $_scannedSlotQr', style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => setState(() => _scannedSlotQr = null),
                            child: const Text('Scan Different Slot'),
                          ),
                        ],
                      ),
                    )
                  : MobileScanner(
                      onDetect: (capture) {
                        final barcode = capture.barcodes.firstOrNull;
                        if (barcode?.rawValue != null) {
                          setState(() {
                            _scannedSlotQr = barcode!.rawValue;
                          });
                        }
                      },
                    ),
            ),
          ),
          const SizedBox(height: 24),
          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _scannedSlotQr == null ? null : () => _submitReturn(overrideLocation: false),
                  child: const Text('Verify & Finalize Return'),
                ),
        ],
      ),
    );
  }
}

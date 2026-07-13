import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/passport_repository.dart';
import '../../../data/repositories/box_repository.dart';
import '../../../data/models/passport.dart';
import '../../../data/models/box.dart' as models;
import '../widgets/glass_card.dart';

class ScanPage extends ConsumerStatefulWidget {
  final String? initialMode;

  const ScanPage({super.key, this.initialMode});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  final PassportRepository _passportRepo = PassportRepository();
  final BoxRepository _boxRepo = BoxRepository();
  final TextEditingController _manualController = TextEditingController();

  // Animation controller for the scanning line
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  // Scanner State
  late String _activeMode; // 'assign', 'return', 'issue', 'verify', 'move_box'
  bool _isTorchOn = false;
  bool _isScanning = true;
  final List<Map<String, dynamic>> _recentScans = [];

  // Anti-spam scanning state
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  static const Duration _scanCooldown = Duration(seconds: 2);

  // Scanned objects
  models.Box? _scannedBox;
  final List<Passport> _scannedPassports = [];
  Passport? _scannedSinglePassport;
  Map<String, dynamic>? _scannedSlot;

  @override
  void initState() {
    super.initState();
    _activeMode = widget.initialMode ?? 'assign';
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _toggleTorch() async {
    await _scannerController.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      _processScannedCode(barcode!.rawValue!);
    }
  }

  Future<void> _processScannedCode(String code) async {
    // Anti-spam protection: ignore rapid duplicate scans
    final now = DateTime.now();
    if (_lastScannedCode == code && 
        _lastScanTime != null && 
        now.difference(_lastScanTime!) < _scanCooldown) {
      return; // Ignore duplicate scan
    }
    
    _lastScannedCode = code;
    _lastScanTime = now;
    
    setState(() {
      _isScanning = false;
    });

    // Track if an error occurred for delay calculation
    bool hasError = false;

    try {
      if (_activeMode == 'assign') {
        if (_scannedBox == null) {
          // Scanning Box QR first
          final box = await _boxRepo.getByQr(code);
          if (box == null) {
            _showFeedback('Box not found: $code', true);
            hasError = true;
          } else {
            setState(() {
              _scannedBox = box;
              _recentScans.insert(0, {
                'type': 'Box Scanned',
                'label': box.label,
                'code': code,
                'time': 'Just now',
                'success': true,
              });
            });
            _showFeedback('Box ${box.label} registered.', false);
          }
        } else {
          // Scanning Passport QR next
          if (_scannedPassports.any((p) => p.qrCode == code)) {
            _showFeedback('Passport already in current batch', true);
            hasError = true;
            setState(() => _isScanning = true);
            return;
          }
          final passport = await _passportRepo.getByQr(code);
          if (passport == null) {
            _showFeedback('Passport not found: $code', true);
            hasError = true;
          } else if (!passport.isIssued) {
            _showFeedback(
              '${passport.holderName} is ${passport.status} — only ISSUED passports can be assigned',
              true,
            );
            hasError = true;
          } else {
            setState(() {
              _scannedPassports.add(passport);
              _recentScans.insert(0, {
                'type': 'Passport Scanned',
                'label': passport.holderName,
                'code': code,
                'time': 'Just now',
                'success': true,
              });
            });
            _showFeedback('Passport: ${passport.holderName} added.', false);
          }
        }
      } else if (_activeMode == 'issue') {
        // Issue passport to holder
        final passport = await _passportRepo.getByQr(code);
        if (passport == null) {
          _showFeedback('Passport not found: $code', true);
          hasError = true;
        } else if (!passport.isInBox) {
          _showFeedback(
            '${passport.holderName} is ${passport.status} — only IN_BOX passports can be issued',
            true,
          );
          hasError = true;
        } else {
          setState(() {
            _scannedSinglePassport = passport;
            _recentScans.insert(0, {
              'type': 'Issue Passport',
              'label': passport.holderName,
              'code': code,
              'time': 'Just now',
              'success': true,
            });
          });
          _showFeedback('Passport identified: ${passport.holderName}', false);
        }
      } else if (_activeMode == 'move_box') {
        if (_scannedBox == null) {
          final box = await _boxRepo.getByQr(code);
          if (box == null) {
            _showFeedback('Box not found: $code', true);
            hasError = true;
          } else {
            setState(() {
              _scannedBox = box;
              _recentScans.insert(0, {
                'type': 'Box Scanned',
                'label': box.label,
                'code': code,
                'time': 'Just now',
                'success': true,
              });
            });
            _showFeedback('Box ${box.label} scanned.', false);
          }
        } else {
          // Scan Slot next
          final res = await _boxRepo.dio.get('/location/slots/qr/$code');
          if (res.data == null) {
            _showFeedback('Slot not found: $code', true);
            hasError = true;
          } else {
            setState(() {
              _scannedSlot = res.data;
              _recentScans.insert(0, {
                'type': 'Slot Scanned',
                'label': res.data['name'] ?? '',
                'code': code,
                'time': 'Just now',
                'success': true,
              });
            });
            _showFeedback('Slot ${res.data['name']} scanned.', false);
          }
        }
      } else {
        // Verify code
        final passport = await _passportRepo.getByQr(code);
        if (passport != null) {
          setState(() {
            _scannedSinglePassport = passport;
            _recentScans.insert(0, {
              'type': 'Verification Success',
              'label': passport.holderName,
              'code': code,
              'time': 'Just now',
              'success': true,
            });
          });
          _showVerificationDialog(passport);
        } else {
          // Check box instead
          final box = await _boxRepo.getByQr(code);
          if (box != null) {
            setState(() {
              _recentScans.insert(0, {
                'type': 'Box Verified',
                'label': box.label,
                'code': code,
                'time': 'Just now',
                'success': true,
              });
            });
            _showBoxDetailsDialog(box);
          } else {
            _showFeedback('QR code not registered in system: $code', true);
            hasError = true;
          }
        }
      }
    } catch (e) {
      _showFeedback('Lookup failed: $e', true);
      hasError = true;
    } finally {
      // Use different delays: 3s for errors, 1s for success
      Duration delayDuration = hasError 
          ? const Duration(seconds: 3) 
          : const Duration(seconds: 1);
      
      Future.delayed(delayDuration, () {
        if (mounted) {
          setState(() {
            _isScanning = true;
          });
        }
      });
    }
  }

  void _showFeedback(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetCurrentScan() {
    setState(() {
      _scannedBox = null;
      _scannedPassports.clear();
      _scannedSinglePassport = null;
      _scannedSlot = null;
    });
  }

  Future<void> _submitBatch() async {
    if (_scannedBox == null || _scannedPassports.isEmpty) return;
    
    setState(() => _isScanning = false);
    final passportIds = _scannedPassports.map((p) => p.id).toList();
    
    try {
      await _passportRepo.batchAssign(
        passportIds: passportIds,
        boxId: _scannedBox!.id,
        action: 'PASSPORT_ASSIGNED',
      );
      
      _showFeedback('Successfully stored ${passportIds.length} passports in ${_scannedBox!.label}', false);
      _resetCurrentScan();
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? (data['message'] as String? ?? 'Batch operation failed') : 'Batch operation failed';
      _showFeedback(message, true);
    } catch (e) {
      _showFeedback('Error submitting batch: $e', true);
    } finally {
      setState(() => _isScanning = true);
    }
  }

  Future<void> _submitIssue() async {
    if (_scannedSinglePassport == null) return;
    setState(() => _isScanning = false);
    try {
      final success = await _passportRepo.issue(_scannedSinglePassport!.id);
      if (success) {
        _showFeedback('Passport successfully issued to ${_scannedSinglePassport!.holderName}', false);
        _resetCurrentScan();
      } else {
        _showFeedback('Issuance failed', true);
      }
    } catch (e) {
      _showFeedback('Error: $e', true);
    } finally {
      setState(() => _isScanning = true);
    }
  }

  Future<void> _submitBoxMove() async {
    if (_scannedBox == null || _scannedSlot == null) return;
    setState(() => _isScanning = false);
    try {
      final success = await _boxRepo.move(_scannedBox!.id, _scannedSlot!['id']);
      if (success) {
        _showFeedback('Box successfully moved to slot ${_scannedSlot!['name']}', false);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          _resetCurrentScan();
        }
      } else {
        _showFeedback('Box move failed', true);
      }
    } catch (e) {
      _showFeedback('Error moving box: $e', true);
    } finally {
      setState(() => _isScanning = true);
    }
  }

  void _showVerificationDialog(Passport p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: AppColors.success),
            const SizedBox(width: 10),
            const Text('Passport Verified'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Holder: ${p.holderName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('ID Number: ${p.holderIdNo}'),
            Text('QR Code: ${p.qrCode}'),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Status: '),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.status == 'IN_BOX' ? AppColors.primary.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: p.status == 'IN_BOX' ? AppColors.primary : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            if (p.box != null) ...[
              const SizedBox(height: 10),
              Text('Location: Box ${p.box!.label}'),
              if (p.box!.location != null) Text('Shelf: ${p.box!.location}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBoxDetailsDialog(models.Box box) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(box.label),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QR Code: ${box.qrCode}'),
            Text('Capacity: ${box.occupiedCount} / ${box.capacity} occupied'),
            Text('Location: ${box.location ?? "Not assigned"}'),
            const SizedBox(height: 10),
            const Text('Passports stored inside:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            box.passports == null || box.passports!.isEmpty
                ? const Text('Box is empty')
                : SizedBox(
                    height: 120,
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: box.passports!.length,
                      itemBuilder: (context, idx) {
                        final p = box.passports![idx];
                        return Text('• ${p.holderName} (${p.qrCode})', style: const TextStyle(fontSize: 12));
                      },
                    ),
                  ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with scan mode tabs
            _buildModeSelector(),

            // Large Camera View
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRect(
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                    ),
                  ),
                  
                  // Stylized Scanner Bounding Frame (Ethiopian ePassport inspired)
                  Center(
                    child: AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isScanning ? AppColors.success.withOpacity(0.8) : AppColors.primary.withOpacity(0.8),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Stack(
                            children: [
                              // Target corners decoration
                              ..._buildCorners(),
                              
                              // Laser scanner animation line
                              Positioned(
                                top: _scanLineAnimation.value * 256,
                                left: 8,
                                right: 8,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: _isScanning ? AppColors.success : AppColors.primary,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isScanning ? AppColors.success : AppColors.primary).withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Overlay indicators (Torch, Gallery)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRoundButton(
                          icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          onTap: _toggleTorch,
                          isActive: _isTorchOn,
                        ),
                        const SizedBox(height: 12),
                        _buildRoundButton(
                          icon: Icons.photo_library_outlined,
                          onTap: () async {
                            // Gallery barcode scan integration (could mock or implement using image_picker if needed)
                            _showFeedback('Gallery import not supported on this device simulator', true);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Mode-specific status overlays
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: _buildStateOverlay(),
                  ),
                ],
              ),
            ),

            // Manual Entry & Summary / Action Button
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Manual entry textfield
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: TextField(
                              controller: _manualController,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                hintText: 'Enter code manually...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                filled: false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            final code = _manualController.text.trim();
                            if (code.isNotEmpty) {
                              _processScannedCode(code);
                              _manualController.clear();
                              FocusScope.of(context).unfocus();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(50, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Icon(Icons.arrow_forward, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Actions list / Scanned results
                    _buildScannedSection(),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildModeTab('assign', 'Assign Box', Icons.inventory_2_rounded),
            _buildModeTab('return', 'Return Custody', Icons.swap_horizontal_circle_rounded),
            _buildModeTab('issue', 'Issue Owner', Icons.assignment_turned_in_rounded),
            _buildModeTab('move_box', 'Move Box', Icons.drive_file_move_outlined),
            _buildModeTab('verify', 'Quick Verify', Icons.verified_user_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String mode, String label, IconData icon) {
    final isActive = _activeMode == mode;
    return GestureDetector(
      onTap: () {
        if (mode == 'return') {
          context.push('/scan?mode=return');
          return;
        }
        setState(() {
          _activeMode = mode;
          _resetCurrentScan();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.primary : AppColors.textBody,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStateOverlay() {
    String text = 'Ready to Scan';
    Color color = Colors.black87;
    
    if (_activeMode == 'assign') {
      if (_scannedBox == null) {
        text = 'Scan TARGET BOX QR Code';
        color = AppColors.primary;
      } else {
        text = 'Box Locked. Scan Passport QR Codes.';
        color = AppColors.success;
      }
    } else if (_activeMode == 'return') {
      if (_scannedBox == null) {
        text = 'Scan RETURN BOX QR Code';
        color = AppColors.primary;
      } else {
        text = 'Box Locked. Scan Returned Passports.';
        color = AppColors.warning;
      }
    } else if (_activeMode == 'move_box') {
      if (_scannedBox == null) {
        text = 'Scan BOX QR Code to Move';
        color = AppColors.primary;
      } else if (_scannedSlot == null) {
        text = 'Scan DESTINATION SLOT QR Code';
        color = Colors.deepPurple;
      } else {
        text = 'Slot Locked. Confirm movement.';
        color = AppColors.success;
      }
    } else if (_activeMode == 'issue') {
      text = 'Scan Passport QR Code to Issue';
      color = AppColors.danger;
    } else {
      text = 'Scan Any QR Code to Quick Verify';
      color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedSection() {
    if (_activeMode == 'assign' || _activeMode == 'return') {
      if (_scannedBox == null) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'Scan a Box QR code or input its label manually to begin storage.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textBody, fontSize: 13),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Target box details
          GlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Box: ${_scannedBox!.label}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Location: ${_scannedBox!.location ?? "Unassigned Slot"}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textBody),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_scannedBox!.occupiedCount}/${_scannedBox!.capacity}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _resetCurrentScan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scanned Passports List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scanned Passports (${_scannedPassports.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark),
              ),
              if (_scannedPassports.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _scannedPassports.clear()),
                  child: const Text('Clear list', style: TextStyle(fontSize: 11, color: AppColors.danger)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_scannedPassports.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, style: BorderStyle.values[1]),
              ),
              child: const Center(
                child: Text('Scan passport QR codes to append...', style: TextStyle(fontSize: 12, color: AppColors.textBody)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _scannedPassports.length,
              itemBuilder: (context, idx) {
                final p = _scannedPassports[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_ind_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.holderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(p.qrCode, style: const TextStyle(fontSize: 10, color: AppColors.textBody)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.danger),
                        onPressed: () {
                          setState(() {
                            _scannedPassports.removeAt(idx);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _scannedPassports.isEmpty ? null : _submitBatch,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              _activeMode == 'return' ? 'Confirm Return Custody' : 'Confirm Box Assignment',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    } else if (_activeMode == 'move_box') {
      if (_scannedBox == null) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'Scan a Box QR code to initiate movement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textBody, fontSize: 13),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Box to move details
          const Text(
            'BOX TO MOVE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textBody, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _scannedBox!.label,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Current Location: ${_scannedBox!.location ?? "Unassigned Slot"}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textBody),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _resetCurrentScan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Target slot details
          const Text(
            'DESTINATION SLOT',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textBody, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),

          if (_scannedSlot == null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, style: BorderStyle.values[1]),
              ),
              child: const Center(
                child: Text('Scan destination Slot QR code next...', style: TextStyle(fontSize: 12, color: AppColors.textBody)),
              ),
            )
          else
            GlassCard(
              padding: const EdgeInsets.all(12),
              borderRadius: 16,
              child: Row(
                children: [
                  const Icon(Icons.place_rounded, color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _scannedSlot!['name'] ?? 'Unknown Slot',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          _scannedSlot!['location'] ?? '',
                          style: const TextStyle(fontSize: 11, color: AppColors.textBody),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.danger),
                    onPressed: () => setState(() => _scannedSlot = null),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_scannedBox != null && _scannedSlot != null) ? _submitBoxMove : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Confirm Box Move',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    } else if (_activeMode == 'issue') {
      if (_scannedSinglePassport == null) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text(
              'Scan passport QR code to initiate owner hand-over.',
              style: TextStyle(color: AppColors.textBody, fontSize: 13),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'PASSPORT READY FOR ISSUANCE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textBody, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          GlassCard(
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _scannedSinglePassport!.holderName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 8),
                Text('ID No: ${_scannedSinglePassport!.holderIdNo}', style: const TextStyle(fontSize: 13)),
                Text('QR Code: ${_scannedSinglePassport!.qrCode}', style: const TextStyle(fontSize: 13, color: AppColors.textBody)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Current Custody: '),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _scannedSinglePassport!.status,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetCurrentScan,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitIssue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Confirm Issuance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // verify mode / logs
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Scans History',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 10),
          _recentScans.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: const Center(
                    child: Text('No scans recorded in this session', style: TextStyle(fontSize: 12, color: AppColors.textBody)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: math.min(5, _recentScans.length),
                  itemBuilder: (context, idx) {
                    final item = _recentScans[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['success'] ? Icons.check_circle_outline : Icons.error_outline,
                            color: item['success'] ? AppColors.success : AppColors.danger,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textBody)),
                                Text(item['label'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          Text(item['time'], style: const TextStyle(fontSize: 10, color: AppColors.textBody)),
                        ],
                      ),
                    );
                  },
                ),
        ],
      );
    }
  }

  List<Widget> _buildCorners() {
    const double length = 16;
    const double thickness = 3;
    final Color color = _isScanning ? AppColors.success : AppColors.primary;
    
    return [
      // Top Left
      Positioned(
        top: 0, left: 0,
        child: Container(width: length, height: thickness, color: color),
      ),
      Positioned(
        top: 0, left: 0,
        child: Container(width: thickness, height: length, color: color),
      ),
      // Top Right
      Positioned(
        top: 0, right: 0,
        child: Container(width: length, height: thickness, color: color),
      ),
      Positioned(
        top: 0, right: 0,
        child: Container(width: thickness, height: length, color: color),
      ),
      // Bottom Left
      Positioned(
        bottom: 0, left: 0,
        child: Container(width: length, height: thickness, color: color),
      ),
      Positioned(
        bottom: 0, left: 0,
        child: Container(width: thickness, height: length, color: color),
      ),
      // Bottom Right
      Positioned(
        bottom: 0, right: 0,
        child: Container(width: length, height: thickness, color: color),
      ),
      Positioned(
        bottom: 0, right: 0,
        child: Container(width: thickness, height: length, color: color),
      ),
    ];
  }
}

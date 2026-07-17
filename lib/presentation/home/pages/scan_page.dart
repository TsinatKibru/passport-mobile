import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/passport_repository.dart';
import '../../../data/repositories/box_repository.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../data/models/passport.dart';
import '../../../data/models/box.dart' as models;
import '../../../data/models/room.dart' as room_models;
import '../../../l10n/app_localizations.dart';
import '../widgets/glass_card.dart';

class ScanPage extends ConsumerStatefulWidget {
  final String? initialMode;

  /// Whether this scan page is the currently-visible tab. The camera only runs
  /// while active, so it isn't held open behind other tabs in the IndexedStack.
  final bool isActive;

  const ScanPage({super.key, this.initialMode, this.isActive = true});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final MobileScannerController _scannerController =
      MobileScannerController(autoStart: false);
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

  Future<void> _startScanner() async {
    if (_scannerController.value.isRunning) return;
    try {
      await _scannerController.start();
    } catch (e) {
      debugPrint('Failed to start mobile scanner: $e');
    }
  }

  Future<void> _stopScanner() async {
    if (!_scannerController.value.isRunning) return;
    try {
      await _scannerController.stop();
    } catch (e) {
      debugPrint('Failed to stop mobile scanner: $e');
    }
  }

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

    // A self-provided MobileScannerController is NOT auto-started by the widget
    // in mobile_scanner v7 — start it explicitly or the preview stays blank.
    // Only run it while this tab is active (see didUpdateWidget) so the camera
    // isn't held open behind other tabs in the IndexedStack.
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) {
      unawaited(_startScanner());
    }
  }

  @override
  void didUpdateWidget(covariant ScanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      unawaited(
        widget.isActive ? _startScanner() : _stopScanner(),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_startScanner());
    } else {
      unawaited(_stopScanner());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  // Map a raw backend passport status onto its localised label.
  String _passportStatusLabel(AppLocalizations l, String status) {
    switch (status.toUpperCase()) {
      case 'ISSUED':
        return l.psIssued;
      case 'IN_BOX':
        return l.psInBox;
      case 'RETURNED':
        return l.psReturned;
      default:
        return status;
    }
  }

  Future<void> _processScannedCode(String code) async {
    final l = AppLocalizations.of(context);
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
            _showFeedback(l.scanBoxNotFound(code), true);
            hasError = true;
          } else {
            setState(() {
              _scannedBox = box;
              _recentScans.insert(0, {
                'type': l.scanHistBoxScanned,
                'label': box.label,
                'code': code,
                'time': l.scanJustNow,
                'success': true,
              });
            });
            _showFeedback(l.scanBoxRegistered(box.label), false);
          }
        } else {
          // Scanning Passport QR next
          if (_scannedPassports.any((p) => p.qrCode == code)) {
            _showFeedback(l.scanPassportAlreadyInBatch, true);
            hasError = true;
            setState(() => _isScanning = true);
            return;
          }
          final passport = await _passportRepo.getByQr(code);
          if (passport == null) {
            _showFeedback(l.scanPassportNotFound(code), true);
            hasError = true;
          } else if (!passport.isIssued) {
            _showFeedback(
              l.scanOnlyIssuedCanAssign(
                  passport.holderName, _passportStatusLabel(l, passport.status)),
              true,
            );
            hasError = true;
          } else {
            setState(() {
              _scannedPassports.add(passport);
              _recentScans.insert(0, {
                'type': l.scanHistPassportScanned,
                'label': passport.holderName,
                'code': code,
                'time': l.scanJustNow,
                'success': true,
              });
            });
            _showFeedback(l.scanPassportAdded(passport.holderName), false);
          }
        }
      } else if (_activeMode == 'issue') {
        // Issue passport to holder
        final passport = await _passportRepo.getByQr(code);
        if (passport == null) {
          _showFeedback(l.scanPassportNotFound(code), true);
          hasError = true;
        } else if (!passport.isInBox) {
          _showFeedback(
            l.scanOnlyInBoxCanIssue(
                passport.holderName, _passportStatusLabel(l, passport.status)),
            true,
          );
          hasError = true;
        } else {
          setState(() {
            _scannedSinglePassport = passport;
            _recentScans.insert(0, {
              'type': l.scanHistIssuePassport,
              'label': passport.holderName,
              'code': code,
              'time': l.scanJustNow,
              'success': true,
            });
          });
          _showFeedback(l.scanPassportIdentified(passport.holderName), false);
        }
      } else if (_activeMode == 'move_box') {
        if (_scannedBox == null) {
          final box = await _boxRepo.getByQr(code);
          if (box == null) {
            _showFeedback(l.scanBoxNotFound(code), true);
            hasError = true;
          } else {
            setState(() {
              _scannedBox = box;
              _recentScans.insert(0, {
                'type': l.scanHistBoxScanned,
                'label': box.label,
                'code': code,
                'time': l.scanJustNow,
                'success': true,
              });
            });
            _showFeedback(l.scanBoxScanned(box.label), false);
          }
        } else {
          _showFeedback("Please select a target slot manually using the button below.", true);
          hasError = true;
        }
      } else {
        // Verify code
        final passport = await _passportRepo.getByQr(code);
        if (passport != null) {
          setState(() {
            _scannedSinglePassport = passport;
            _recentScans.insert(0, {
              'type': l.scanHistVerificationSuccess,
              'label': passport.holderName,
              'code': code,
              'time': l.scanJustNow,
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
                'type': l.scanHistBoxVerified,
                'label': box.label,
                'code': code,
                'time': l.scanJustNow,
                'success': true,
              });
            });
            _showBoxDetailsDialog(box);
          } else {
            _showFeedback(l.scanQrNotRegistered(code), true);
            hasError = true;
          }
        }
      }
    } catch (e) {
      _showFeedback(l.scanLookupFailed('$e'), true);
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
    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: isError ? c.onDanger : c.onSuccess,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? c.danger : c.success,
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

    final l = AppLocalizations.of(context);
    setState(() => _isScanning = false);
    final passportIds = _scannedPassports.map((p) => p.id).toList();

    try {
      await _passportRepo.batchAssign(
        passportIds: passportIds,
        boxId: _scannedBox!.id,
        action: 'PASSPORT_ASSIGNED',
      );

      _showFeedback(l.scanBatchStored(passportIds.length, _scannedBox!.label), false);
      _resetCurrentScan();
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? (data['message'] as String? ?? l.scanBatchFailed) : l.scanBatchFailed;
      _showFeedback(message, true);
    } catch (e) {
      _showFeedback(l.scanBatchError('$e'), true);
    } finally {
      setState(() => _isScanning = true);
    }
  }

  Future<void> _submitIssue() async {
    if (_scannedSinglePassport == null) return;
    final l = AppLocalizations.of(context);
    setState(() => _isScanning = false);
    try {
      final success = await _passportRepo.issue(_scannedSinglePassport!.id);
      if (success) {
        _showFeedback(l.scanIssueSuccess(_scannedSinglePassport!.holderName), false);
        _resetCurrentScan();
      } else {
        _showFeedback(l.scanIssueFailed, true);
      }
    } catch (e) {
      _showFeedback(l.scanGenericError('$e'), true);
    } finally {
      setState(() => _isScanning = true);
    }
  }

  Future<void> _submitBoxMove() async {
    if (_scannedBox == null || _scannedSlot == null) return;
    final l = AppLocalizations.of(context);
    setState(() => _isScanning = false);
    try {
      final success = await _boxRepo.move(_scannedBox!.id, _scannedSlot!['id']);
      if (success) {
        _showFeedback(l.scanBoxMoveSuccess(_scannedSlot!['name'] ?? ''), false);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          _resetCurrentScan();
        }
      } else {
        _showFeedback(l.scanBoxMoveFailed, true);
      }
    } catch (e) {
      _showFeedback(l.scanBoxMoveError('$e'), true);
    } finally {
      setState(() => _isScanning = true);
    }
  }

  void _showVerificationDialog(Passport p) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.verified_user_rounded, color: c.success),
            const SizedBox(width: 10),
            Text(l.scanPassportVerified),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.scanHolder(p.holderName), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(l.scanIdNumber(p.holderIdNo)),
            Text(l.scanQrCodeValue(p.qrCode)),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(l.scanStatusLabel),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.status == 'IN_BOX' ? c.primary.withOpacity(0.1) : c.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _passportStatusLabel(l, p.status),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: p.status == 'IN_BOX' ? c.primary : c.success,
                    ),
                  ),
                ),
              ],
            ),
            if (p.box != null) ...[
              const SizedBox(height: 10),
              Text(l.scanLocationBox(p.box!.label)),
              if (p.box!.location != null) Text(l.scanShelf(p.box!.location ?? '')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }

  void _showBoxDetailsDialog(models.Box box) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.inventory_2_rounded, color: c.primary),
            const SizedBox(width: 10),
            Text(box.label),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.scanQrCodeValue(box.qrCode)),
            Text(l.scanCapacity(box.occupiedCount, box.capacity)),
            Text(l.scanLocationValue(box.location ?? l.scanNotAssigned)),
            const SizedBox(height: 10),
            Text(l.scanPassportsStoredInside, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            box.passports == null || box.passports!.isEmpty
                ? Text(l.scanBoxEmpty)
                : SizedBox(
                    height: 120,
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: box.passports!.length,
                      itemBuilder: (context, idx) {
                        final p = box.passports![idx];
                        return Text(l.scanPassportBullet(p.holderName, p.qrCode), style: const TextStyle(fontSize: 12));
                      },
                    ),
                  ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
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
                            _showFeedback(l.scanGalleryUnsupported, true);
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
                              color: c.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.border),
                            ),
                            child: TextField(
                              controller: _manualController,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: l.scanEnterCodeManually,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            backgroundColor: c.primary,
                            minimumSize: const Size(50, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Icon(Icons.arrow_forward, color: c.onPrimary),
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
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Container(
      color: c.appBar,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildModeTab('assign', l.scanModeAssign, Icons.inventory_2_rounded, c),
          _buildModeTab('return', l.scanModeReturn, Icons.swap_horizontal_circle_rounded, c),
          _buildModeTab('issue', l.scanModeIssue, Icons.assignment_turned_in_rounded, c),
          _buildModeTab('move_box', l.scanModeMove, Icons.drive_file_move_outlined, c),
          _buildModeTab('verify', l.scanModeVerify, Icons.verified_user_rounded, c),
        ],
      ),
    );
  }

  Widget _buildModeTab(String mode, String label, IconData icon, AppPalette c) {
    final isActive = _activeMode == mode;
    return GestureDetector(
      onTap: () async {
        if (mode == 'return') {
          final previousMode = _activeMode;
          setState(() {
            _activeMode = mode;
          });
          // Wait for the expansion animation to complete
          await Future.delayed(const Duration(milliseconds: 200));
          if (!mounted) return;

          await context.push('/scan?mode=return');

          if (mounted) {
            setState(() {
              _activeMode = previousMode;
            });
          }
          return;
        }
        setState(() {
          _activeMode = mode;
          _resetCurrentScan();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive ? c.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? c.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isActive ? 16 : 22,
              color: isActive ? c.primary : c.textBody,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                ),
              ),
            ],
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
    final l = AppLocalizations.of(context);
    String text = l.scanReadyToScan;
    Color color = Colors.black87;

    if (_activeMode == 'assign') {
      if (_scannedBox == null) {
        text = l.scanTargetBoxPrompt;
        color = AppColors.primary;
      } else {
        text = l.scanBoxLockedPassports;
        color = AppColors.success;
      }
    } else if (_activeMode == 'return') {
      if (_scannedBox == null) {
        text = l.scanReturnBoxPrompt;
        color = AppColors.primary;
      } else {
        text = l.scanBoxLockedReturned;
        color = AppColors.warning;
      }
    } else if (_activeMode == 'move_box') {
      if (_scannedBox == null) {
        text = l.scanBoxToMovePrompt;
        color = AppColors.primary;
      } else if (_scannedSlot == null) {
        text = l.scanDestSlotPrompt;
        color = Colors.deepPurple;
      } else {
        text = l.scanSlotLockedConfirm;
        color = AppColors.success;
      }
    } else if (_activeMode == 'issue') {
      text = l.scanPassportToIssuePrompt;
      color = AppColors.danger;
    } else {
      text = l.scanAnyToVerifyPrompt;
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
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (_activeMode == 'assign' || _activeMode == 'return') {
      if (_scannedBox == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              l.scanAssignHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textBody, fontSize: 13),
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
                Icon(Icons.inventory_2_rounded, color: c.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.scanTargetBox(_scannedBox!.label),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        l.scanLocationValue(_scannedBox!.location ?? l.scanUnassignedSlot),
                        style: TextStyle(fontSize: 11, color: c.textBody),
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
                l.scanScannedPassportsCount(_scannedPassports.length),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: c.primaryDark),
              ),
              if (_scannedPassports.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _scannedPassports.clear()),
                  child: Text(l.scanClearList, style: TextStyle(fontSize: 11, color: c.danger)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_scannedPassports.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border, style: BorderStyle.values[1]),
              ),
              child: Center(
                child: Text(l.scanAppendHint, style: TextStyle(fontSize: 12, color: c.textBody)),
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
                    color: c.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_ind_rounded, size: 18, color: c.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.holderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(p.qrCode, style: TextStyle(fontSize: 10, color: c.textBody)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, size: 18, color: c.danger),
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
              _activeMode == 'return' ? l.scanConfirmReturn : l.scanConfirmAssign,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    } else if (_activeMode == 'move_box') {
      if (_scannedBox == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              l.scanMoveHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textBody, fontSize: 13),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Box to move details
          Text(
            l.scanBoxToMove,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: c.textBody, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Row(
              children: [
                Icon(Icons.inventory_2_rounded, color: c.primary),
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
                        l.scanCurrentLocation(_scannedBox!.location ?? l.scanUnassignedSlot),
                        style: TextStyle(fontSize: 11, color: c.textBody),
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
          Text(
            l.scanDestSlot,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: c.textBody, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),

          if (_scannedSlot == null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.unarchive_outlined, size: 40, color: c.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    "No destination slot selected",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c.textBody),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openSlotSelector,
                    icon: const Icon(Icons.place_rounded, size: 18),
                    label: const Text("Select Target Slot"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
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
                          _scannedSlot!['name'] ?? l.scanUnknownSlot,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          _scannedSlot!['location'] ?? '',
                          style: TextStyle(fontSize: 11, color: c.textBody),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, size: 18, color: c.danger),
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
            child: Text(
              l.scanConfirmMove,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    } else if (_activeMode == 'issue') {
      if (_scannedSinglePassport == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              l.scanIssueHint,
              style: TextStyle(color: c.textBody, fontSize: 13),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.scanPassportReadyIssuance,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: c.textBody, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          GlassCard(
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _scannedSinglePassport!.holderName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: c.primaryDark),
                ),
                const SizedBox(height: 8),
                Text('${l.boxesIdNo}: ${_scannedSinglePassport!.holderIdNo}', style: const TextStyle(fontSize: 13)),
                Text(l.scanQrCodeValue(_scannedSinglePassport!.qrCode), style: TextStyle(fontSize: 13, color: c.textBody)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(l.scanCurrentCustody),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _passportStatusLabel(l, _scannedSinglePassport!.status),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c.primary),
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
                    side: BorderSide(color: c.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(l.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitIssue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.danger,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(l.scanConfirmIssuance, style: TextStyle(fontWeight: FontWeight.bold, color: c.onDanger)),
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
          Text(
            l.scanRecentHistory,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: c.primaryDark),
          ),
          const SizedBox(height: 10),
          _recentScans.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(l.scanNoScans, style: TextStyle(fontSize: 12, color: c.textBody)),
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
                        color: c.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['success'] ? Icons.check_circle_outline : Icons.error_outline,
                            color: item['success'] ? c.success : c.danger,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['type'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: c.textBody)),
                                Text(item['label'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          Text(item['time'], style: TextStyle(fontSize: 10, color: c.textBody)),
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

  void _openSlotSelector() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SlotSelectionSheet(
        onSlotSelected: (slot, locationPath) {
          setState(() {
            _scannedSlot = {
              'id': slot.id,
              'name': slot.name,
              'location': locationPath,
            };
            _recentScans.insert(0, {
              'type': l.scanHistSlotScanned,
              'label': slot.name,
              'code': slot.name,
              'time': l.scanJustNow,
              'success': true,
            });
          });
          _showFeedback(l.scanSlotScanned(slot.name), false);
        },
      ),
    );
  }
}

class _SlotSelectionSheet extends StatefulWidget {
  final Function(room_models.VaultSlot slot, String locationPath) onSlotSelected;
  const _SlotSelectionSheet({required this.onSlotSelected});

  @override
  State<_SlotSelectionSheet> createState() => _SlotSelectionSheetState();
}

class _SlotSelectionSheetState extends State<_SlotSelectionSheet> {
  final LocationRepository _locationRepo = LocationRepository();
  bool _isLoading = false;

  String _level = 'rooms'; // 'rooms', 'shelves', 'rows', 'slots'
  List<room_models.Room> _rooms = [];
  List<room_models.Shelf> _shelves = [];
  List<room_models.VaultRow> _rows = [];
  List<room_models.VaultSlot> _slots = [];

  room_models.Room? _selectedRoom;
  room_models.Shelf? _selectedShelf;
  room_models.VaultRow? _selectedRow;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final list = await _locationRepo.getRooms();
      setState(() {
        _rooms = list;
        _level = 'rooms';
        _selectedRoom = null;
        _selectedShelf = null;
        _selectedRow = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadShelves(room_models.Room room) async {
    setState(() => _isLoading = true);
    try {
      final list = await _locationRepo.getShelves(room.id);
      setState(() {
        _shelves = list;
        _selectedRoom = room;
        _level = 'shelves';
        _selectedShelf = null;
        _selectedRow = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRows(room_models.Shelf shelf) async {
    setState(() => _isLoading = true);
    try {
      final list = await _locationRepo.getRows(shelf.id);
      setState(() {
        _rows = list;
        _selectedShelf = shelf;
        _level = 'rows';
        _selectedRow = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSlots(room_models.VaultRow row) async {
    setState(() => _isLoading = true);
    try {
      final list = await _locationRepo.getSlots(row.id);
      setState(() {
        _slots = list;
        _level = 'slots';
        _selectedRow = row;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateBack() {
    if (_level == 'slots') {
      _loadRows(_selectedShelf!);
    } else if (_level == 'rows') {
      _loadShelves(_selectedRoom!);
    } else if (_level == 'shelves') {
      _loadRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 16),
          _buildHeader(c),
          _buildBreadcrumbs(c),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildCurrentView(c),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppPalette c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Select Target Slot",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.primaryDark,
            ),
          ),
          if (_level != 'rooms')
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.primary, size: 20),
              onPressed: _navigateBack,
            ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(AppPalette c) {
    final crumbs = <Widget>[
      GestureDetector(
        onTap: _loadRooms,
        child: Text(
          "Rooms",
          style: TextStyle(color: c.primary, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    ];

    if (_selectedRoom != null) {
      crumbs.add(Icon(Icons.chevron_right, size: 12, color: c.textBody));
      crumbs.add(GestureDetector(
        onTap: () => _loadShelves(_selectedRoom!),
        child: Text(
          _selectedRoom!.name,
          style: TextStyle(
            color: _level == 'shelves' ? c.textBody : c.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ));
    }
    if (_selectedShelf != null) {
      crumbs.add(Icon(Icons.chevron_right, size: 12, color: c.textBody));
      crumbs.add(GestureDetector(
        onTap: () => _loadRows(_selectedShelf!),
        child: Text(
          _selectedShelf!.name,
          style: TextStyle(
            color: _level == 'rows' ? c.textBody : c.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ));
    }
    if (_selectedRow != null) {
      crumbs.add(Icon(Icons.chevron_right, size: 12, color: c.textBody));
      crumbs.add(Text(
        _selectedRow!.name,
        style: TextStyle(color: c.textBody, fontWeight: FontWeight.bold, fontSize: 12),
      ));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: crumbs),
      ),
    );
  }

  Widget _buildCurrentView(AppPalette c) {
    switch (_level) {
      case 'rooms':
        return _buildRoomsList(c);
      case 'shelves':
        return _buildShelvesList(c);
      case 'rows':
        return _buildRowsList(c);
      case 'slots':
        return _buildSlotsList(c);
      default:
        return const SizedBox();
    }
  }

  Widget _buildRoomsList(AppPalette c) {
    if (_rooms.isEmpty) return const Center(child: Text("No rooms configured"));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: _rooms.length,
      itemBuilder: (context, i) {
        final r = _rooms[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: c.border),
          ),
          child: ListTile(
            leading: Icon(Icons.meeting_room_rounded, color: c.primary),
            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${r.shelfCount ?? 0} shelves"),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _loadShelves(r),
          ),
        );
      },
    );
  }

  Widget _buildShelvesList(AppPalette c) {
    if (_shelves.isEmpty) return const Center(child: Text("No shelves configured"));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: _shelves.length,
      itemBuilder: (context, i) {
        final s = _shelves[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: c.border),
          ),
          child: ListTile(
            leading: Icon(Icons.dns_rounded, color: c.success),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Row count: ${s.rowCount ?? 0}"),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _loadRows(s),
          ),
        );
      },
    );
  }

  Widget _buildRowsList(AppPalette c) {
    if (_rows.isEmpty) return const Center(child: Text("No rows configured"));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: _rows.length,
      itemBuilder: (context, i) {
        final r = _rows[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: c.border),
          ),
          child: ListTile(
            leading: Icon(Icons.view_headline_rounded, color: c.primaryDark),
            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Slot count: ${r.slotCount ?? 0}"),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _loadSlots(r),
          ),
        );
      },
    );
  }

  Widget _buildSlotsList(AppPalette c) {
    if (_slots.isEmpty) return const Center(child: Text("No slots configured"));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: _slots.length,
      itemBuilder: (context, i) {
        final s = _slots[i];
        final box = s.boxes != null && s.boxes!.isNotEmpty ? s.boxes!.first : null;
        final isOccupied = box != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: isOccupied ? c.surface.withValues(alpha: 0.5) : c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isOccupied ? c.border : c.primary.withValues(alpha: 0.3),
              width: isOccupied ? 1 : 1.5,
            ),
          ),
          child: ListTile(
            enabled: !isOccupied,
            leading: Icon(
              isOccupied ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: isOccupied ? c.danger : c.success,
            ),
            title: Text(
              s.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOccupied ? c.textBody.withValues(alpha: 0.5) : c.primaryDark,
              ),
            ),
            subtitle: Text(
              isOccupied ? "Occupied by ${box.label}" : "Vacant / Available",
              style: TextStyle(
                color: isOccupied ? c.danger.withValues(alpha: 0.7) : c.success,
                fontWeight: isOccupied ? FontWeight.normal : FontWeight.bold,
                fontSize: 12,
              ),
            ),
            trailing: isOccupied
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Occupied",
                      style: TextStyle(color: c.danger, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Vacant",
                      style: TextStyle(color: c.success, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
            onTap: () {
              final path = "${_selectedRoom!.name} / ${_selectedShelf!.name} / ${_selectedRow!.name}";
              widget.onSlotSelected(s, path);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}

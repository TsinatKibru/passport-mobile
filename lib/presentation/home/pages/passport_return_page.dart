

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/passport_repository.dart';
import '../../../data/repositories/box_repository.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../data/models/passport.dart';
import '../../../data/models/box.dart' as models;
import '../../../data/models/room.dart';
import '../widgets/fingerprint_background.dart';

/// CENTRAL CONSTANTS - Single source of truth for all magic numbers
/// This prevents scattered hardcoded values and makes tuning easy
class _Constants {
  // SCAN TIMING (Step 1)
  /// Debounce delay for barcode detection (prevents rapid duplicate processing)
  /// MobileScanner fires on EVERY FRAME, so debouncing is critical
  static const int scanDebounceMs = 800;

  // FEEDBACK TIMING (Global)
  /// Throttle delay for snackbar display (prevents spam when scanning continuously)
  /// FIX: This was the main issue - snackbars showed every frame without throttling
  static const int feedbackThrottleMs = 500;

  /// How long to keep a QR code in "detected" set before allowing re-scan
  /// (gives user time to move camera away before code triggers again)
  static const int processingQrExpiryMs = 2000;

  // SEARCH TIMING (Step 2)
  /// Debounce delay for search input (prevents excessive API calls while typing)
  static const int searchDebounceMs = 500;

  // PAGINATION (Step 2)
  /// Items per page when loading available boxes
  static const int boxPaginationLimit = 20;

  // UI DIMENSIONS
  /// Width of the QR scan reticle overlay
  static const double scanReticleWidth = 220;
  /// Height of the QR scan reticle overlay
  static const double scanReticleHeight = 140;

  // LABELS
  /// Step names for the progress indicator
  static const List<String> stepLabels = ['Scan', 'Select Box', 'Scan Box', 'Scan Slot'];
}

class PassportReturnPage extends StatefulWidget {
  const PassportReturnPage({super.key});

  @override
  State<PassportReturnPage> createState() => _PassportReturnPageState();
}

class _PassportReturnPageState extends State<PassportReturnPage> {
  // ============================================================================
  // REPOSITORIES
  // ============================================================================
  final PassportRepository _passportRepo = PassportRepository();
  final BoxRepository _boxRepo = BoxRepository();
  final LocationRepository _locationRepo = LocationRepository();

  // ============================================================================
  // STEP & UI STATE
  // ============================================================================
  int _currentStep = 1;

  // ============================================================================
  // SCAN STATE (Step 1) - Passport QR Detection
  // ============================================================================
  final List<Passport> _scannedPassports = [];

  /// FIX #1: Prevents duplicate barcode processing in the same scan session.
  /// MobileScanner fires onDetect on EVERY FRAME while a barcode is visible,
  /// so we track detected codes to ignore repeated detections of the same QR.
  /// This set is cleared after 2 seconds to allow re-scanning if needed.
  final Set<String> _detectedBarcodes = {};

  /// FIX #2: CRITICAL - Throttles snackbar display to prevent spam.
  /// When you hold camera steady on a barcode, MobileScanner fires every frame.
  /// Without throttling, snackbar appears dozens of times per second.
  /// We only show a snackbar if 500ms has passed since the last one.
  DateTime? _lastFeedbackTime;

  // ============================================================================
  // BOX SELECTION STATE (Step 2) - Box Search & Selection
  // ============================================================================
  List<models.Box> _availableBoxes = [];
  models.Box? _selectedBox;
  bool _isLoadingBoxes = false;
  final TextEditingController _boxSearchController = TextEditingController();

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalBoxes = 0;
  bool _hasMoreBoxes = false;
  String _searchQuery = '';
  String? _selectedRoomId;
  List<Room> _rooms = [];
  bool _isLoadingRooms = false;

  // ============================================================================
  // VERIFICATION STATE (Steps 3 & 4) - Box & Slot QR Verification
  // ============================================================================
  bool _isSubmitting = false;
  String? _scannedSlotQr;
  String? _scannedBoxQr;
  String? _mismatchMessage;

  // ============================================================================
  // DEBOUNCE/THROTTLE TIMERS - Prevent rapid processing
  // ============================================================================
  /// FIX #3: Debounces barcode detection (800ms)
  /// Without this, rapid frame detection causes duplicate API calls
  Timer? _scanDebounceTimer;

  /// FIX #4: Debounces search input (500ms)
  /// Prevents excessive API calls while user is still typing
  Timer? _searchDebounceTimer;

  // ============================================================================
  // CONTROLLERS & SCROLL
  // ============================================================================
  final ScrollController _step3ScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _boxSearchController.dispose();
    _step3ScrollController.dispose();
    
    // FIX: Cancel all pending timers to prevent orphaned callbacks
    // If these fire after dispose, it could crash the app or leak memory
    _searchDebounceTimer?.cancel();
    _scanDebounceTimer?.cancel();
    
    super.dispose();
  }

  // ============================================================================
  // FEEDBACK & UX METHODS
  // ============================================================================

  /// FIX #2: Throttled snackbar to prevent spam.
  ///
  /// PROBLEM: When holding camera on a barcode, MobileScanner fires onDetect
  /// every frame (~60 fps). Without throttling, snackbars appear dozens of times.
  ///
  /// SOLUTION: Only show snackbar if 500ms has elapsed since the last one.
  /// This ensures smooth UX while preventing spam.
  ///
  /// Example:
  /// - Frame 1 (0ms): shows snackbar, sets _lastFeedbackTime = now
  /// - Frame 2 (16ms): suppressed (16 < 500)
  /// - Frame 3 (32ms): suppressed (32 < 500)
  /// - ...
  /// - Frame N (500ms+): shows snackbar
  void _showFeedback(String message, bool isError) {
    final now = DateTime.now();
    
    // Check if we've shown a snackbar recently
    if (_lastFeedbackTime != null &&
        now.difference(_lastFeedbackTime!).inMilliseconds < _Constants.feedbackThrottleMs) {
      return; // Suppress this feedback - too soon after last one
    }

    // Update the timestamp for next throttle check
    _lastFeedbackTime = now;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Raise mismatch: show in banner + snackbar + scroll to top
  void _raiseMismatch(String message) {
    if (!mounted) return;
    setState(() => _mismatchMessage = message);
    _showFeedback(message, true);
    if (_step3ScrollController.hasClients) {
      _step3ScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _clearMismatch() {
    if (mounted) {
      setState(() => _mismatchMessage = null);
    }
  }

  // === STEP NAVIGATION ===

  void _goToStep(int step) {
    if (!mounted) return;
    setState(() {
      _currentStep = step;
      _clearMismatch();

      // Clean up scanned data when moving backwards
      if (step < 4) _scannedSlotQr = null;
      if (step < 3) _scannedBoxQr = null;
    });
  }

  void _goBack() {
    if (_currentStep > 1) {
      _goToStep(_currentStep - 1);
    } else {
      context.pop();
    }
  }

  // === ROOM LOADING ===

  Future<void> _loadRooms() async {
    if (!mounted) return;
    setState(() => _isLoadingRooms = true);
    try {
      final rooms = await _locationRepo.getRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRooms = false);
        _showFeedback('Failed to load rooms', true);
      }
    }
  }

  // ============================================================================
  // PASSPORT SCANNING (Step 1) - QR Code Detection & Processing
  // ============================================================================

  /// FIX #1 & #3: Debounced barcode detection handler.
  ///
  /// PROBLEM: MobileScanner fires onDetect on EVERY FRAME (~60fps) while a
  /// barcode is visible. This would cause:
  /// 1. Duplicate API calls (looking up same passport repeatedly)
  /// 2. Snackbar spam (hundreds of "Added" messages per second)
  ///
  /// SOLUTION: Two-layer protection:
  /// 1. _detectedBarcodes set: If code is already detected, ignore it immediately
  /// 2. Debounce timer: Even if new code, wait 800ms before processing
  ///
  /// Flow:
  /// - Frame 1 (0ms): Code detected → _onBarcode called
  ///   → Code not in _detectedBarcodes, so set 800ms timer
  /// - Frame 2 (16ms): Code detected again → _onBarcode called
  ///   → Code not yet in _detectedBarcodes (added after processing)
  ///   → Cancel old timer, set new 800ms timer (resets the clock)
  /// - Frames 3-48: Same thing (timer keeps resetting)
  /// - After no new detections for 800ms: Timer fires → _addPassportByQr called
  void _onBarcode(String code) {
    // Ignore if already processed and added to stack
    if (_detectedBarcodes.contains(code)) {
      return;
    }

    // Cancel any pending timer from a previous scan
    _scanDebounceTimer?.cancel();
    
    // Set new debounce timer - only process after 800ms of stable detection
    _scanDebounceTimer = Timer(
      const Duration(milliseconds: _Constants.scanDebounceMs),
      () {
        if (mounted) {
          _addPassportByQr(code);
        }
      }
    );
  }

  /// Adds a scanned passport to the list after API lookup.
  /// Called by debounce timer in _onBarcode.
  Future<void> _addPassportByQr(String code) async {
    // Quick check: already in the scanned stack?
    if (_scannedPassports.any((p) => p.qrCode == code)) {
      return;
    }

    // Mark this code as detected (prevents duplicate processing)
    _detectedBarcodes.add(code);

    try {
      // Look up passport from API
      final passport = await _passportRepo.getByQr(code);
      if (passport == null) {
        _showFeedback('Passport not found: $code', true);
        return;
      }

      // Validate passport is in ISSUED status
      if (!passport.isIssued) {
        _showFeedback(
          '${passport.holderName} is ${passport.status} — only ISSUED passports can be returned',
          true,
        );
        return;
      }

      // Add to scanned stack
      if (!mounted) return;
      setState(() => _scannedPassports.add(passport));
      _showFeedback('Added: ${passport.holderName}', false);
    } catch (e) {
      _showFeedback('Error: $e', true);
    } finally {
      // FIX: Remove from detected set after 2 seconds
      // This allows user to re-scan the same passport if they want to undo + rescan
      // But prevents accidental re-scanning while camera is still pointed at the code
      Future.delayed(const Duration(milliseconds: _Constants.processingQrExpiryMs), () {
        if (mounted) {
          _detectedBarcodes.remove(code);
        }
      });
    }
  }

  void _clearScannedPassports() {
    setState(() {
      _scannedPassports.clear();
      _detectedBarcodes.clear();
    });
  }

  void _removePassport(int idx) {
    setState(() => _scannedPassports.removeAt(idx));
  }

  // === BOX SELECTION (Step 2) ===

  Future<void> _loadAvailableBoxes({bool resetPage = true}) async {
    if (resetPage) {
      setState(() {
        _currentPage = 1;
        _availableBoxes.clear();
      });
    }

    if (!mounted) return;
    setState(() {
      _isLoadingBoxes = true;
      _currentStep = 2;
    });

    try {
      final response = await _boxRepo.getAvailablePaginated(
        _scannedPassports.length,
        page: _currentPage,
        limit: _Constants.boxPaginationLimit,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        roomId: _selectedRoomId,
      );

      if (!mounted) return;
      setState(() {
        if (resetPage) {
          _availableBoxes = response.data;
        } else {
          _availableBoxes.addAll(response.data);
        }
        _totalPages = response.totalPages;
        _totalBoxes = response.total;
        _hasMoreBoxes = response.hasMore;
        _isLoadingBoxes = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBoxes = false);
        _showFeedback('Failed to load boxes', true);
      }
    }
  }

  void _selectBox(models.Box box) {
    setState(() {
      _selectedBox = box;
      _currentStep = 3;
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);

    // Cancel previous debounce
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: _Constants.searchDebounceMs), () {
      if (mounted && _searchQuery == query) {
        _loadAvailableBoxes(resetPage: true);
      }
    });
  }

  void _onRoomChanged(String? roomId) {
    setState(() => _selectedRoomId = roomId);
    _loadAvailableBoxes(resetPage: true);
  }

  void _loadNextPage() {
    if (_hasMoreBoxes && !_isLoadingBoxes) {
      setState(() => _currentPage++);
      _loadAvailableBoxes(resetPage: false);
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1 && !_isLoadingBoxes) {
      setState(() => _currentPage--);
      _loadAvailableBoxes(resetPage: true);
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages && !_isLoadingBoxes) {
      setState(() => _currentPage++);
      _loadAvailableBoxes(resetPage: true);
    }
  }

  // === BOX VERIFICATION (Steps 3 & 4) ===

  /// Handles box QR scan. If match: proceed to step 4. If mismatch: raise error.
  void _onBoxQrScanned(String scannedQr) {
    if (_selectedBox == null) return;

    if (scannedQr == _selectedBox!.qrCode) {
      if (!mounted) return;
      setState(() {
        _scannedBoxQr = scannedQr;
        _clearMismatch();
        _currentStep = 4;
      });
      _showFeedback('Box verified', false);
    } else {
      setState(() => _scannedBoxQr = null);
      _raiseMismatch('Wrong box — this is not the selected box. Please scan the correct QR code.');
    }
  }

  /// Handles slot QR scan. Just captures it; submit is separate.
  void _onSlotQrScanned(String scannedQr) {
    if (!mounted) return;
    setState(() {
      _scannedSlotQr = scannedQr;
      _clearMismatch();
    });
  }

  // === BATCH RETURN SUBMISSION ===

  Future<void> _executeBatchReturn() async {
    if (_selectedBox == null || _scannedBoxQr == null || _scannedSlotQr == null) {
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final passportIds = _scannedPassports.map((p) => p.id).toList();
      await _passportRepo.batchAssign(
        passportIds: passportIds,
        boxId: _selectedBox!.id,
        slotQrCode: _scannedSlotQr!,
        action: 'PASSPORT_RETURNED',
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSuccessDialog();
    } on DioException catch (dioErr) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _handleReturnError(dioErr);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showFeedback('Return failed: $e', true);
    }
  }

  void _handleReturnError(DioException dioErr) {
    final responseData = dioErr.response?.data;

    if (responseData is Map && responseData['error'] == 'LOCATION_MISMATCH') {
      setState(() => _scannedSlotQr = null);
      _raiseMismatch('Location mismatch — wrong slot for this box location.');
      return;
    }

    final message =
        (responseData is Map ? responseData['message'] : null) ?? 'Network error';
    _showFeedback(message, true);
  }

  // void _showSuccessDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (ctx) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //       icon: Container(
  //         width: 64,
  //         height: 64,
  //         decoration: BoxDecoration(
  //           shape: BoxShape.circle,
  //           color: AppColors.success.withValues(alpha: 0.1),
  //         ),
  //         child: const Icon(Icons.check_circle_rounded, size: 40, color: AppColors.success),
  //       ),
  //       title: const Text('Return Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
  //       content: Text(
  //         'Successfully returned ${_scannedPassports.length} passports to Box ${_selectedBox!.label}.',
  //         textAlign: TextAlign.center,
  //       ),
  //       actions: [
  //         SizedBox(
  //           width: double.infinity,
  //           child: ElevatedButton(
  //             style: _buttonStyle,
  //             onPressed: () {
  //               Navigator.pop(ctx);
  //               context.pop();
  //             },
  //             child: const Text('Back to Dashboard'),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
void _showSuccessDialog() {
  final count = _scannedPassports.length;

  showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Colored header band
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 32),
                const SizedBox(height: 10),
                Text(
                  '$count Passport${count == 1 ? '' : 's'} Returned',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stored in ${_selectedBox!.label}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Names row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: _scannedPassports
                  .map((p) => Chip(
                        label: Text(p.holderName, style: const TextStyle(fontSize: 11.5)),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: AppColors.border),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: _buttonStyle,
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pop();
                    },
                    child: const Text('Back to Dashboard'),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _resetForNewBatch();
                  },
                  child: const Text('Return Another Batch'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void _resetForNewBatch() {
  setState(() {
    _scannedPassports.clear();
    _detectedBarcodes.clear();
    _selectedBox = null;
    _scannedBoxQr = null;
    _scannedSlotQr = null;
    _mismatchMessage = null;
    _currentStep = 1;
  });
}
  // === UI BUILDERS ===

  static final _buttonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FingerprintBackground(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
                child: Row(
                  children: [
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.primaryDark, size: 20),
                        onPressed: _goBack,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Return Custody Flow',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildStepIndicator(),
            Expanded(child: _buildStepContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
      child: Row(
        children: List.generate(4, (idx) {
          final stepNum = idx + 1;
          final isDone = stepNum < _currentStep;
          final isCurrent = stepNum == _currentStep;
          final isActive = stepNum <= _currentStep;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? AppColors.primary : Colors.white,
                        border: Border.all(
                          color: isActive ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                            : Text(
                                '$stepNum',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.white : AppColors.textHint,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _Constants.stepLabels[idx],
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? AppColors.primaryDark : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                if (idx < 3)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: stepNum < _currentStep ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
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
      case 4:
        return _buildStep4();
      default:
        return const SizedBox();
    }
  }

  // ============================================================================
  // STEP 1: Scan Passports - QR Code Input
  // ============================================================================
  /// Builds the passport scanning step.
  ///
  /// IMPORTANT: The MobileScanner below fires onDetect on EVERY FRAME (~60fps)
  /// while a barcode is visible. This is normal behavior.
  ///
  /// The snackbar spam fix works like this:
  /// 1. MobileScanner detects barcode → calls onDetect (multiple times per second)
  /// 2. onDetect calls _onBarcode(code)
  /// 3. _onBarcode debounces with 800ms timer (resets timer each frame)
  /// 4. After 800ms stable, timer fires → calls _addPassportByQr
  /// 5. _addPassportByQr makes API call + shows snackbar (throttled to 500ms min)
  ///
  /// Result: Smooth scanning without spam!
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // The scanner camera feed
                  // NOTE: This fires onDetect EVERY FRAME - don't do heavy work here!
                  // Heavy work goes in _onBarcode → _addPassportByQr (debounced)
                  MobileScanner(
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      if (barcode?.rawValue != null) {
                        _onBarcode(barcode!.rawValue!); // ← Debounced gateway
                      }
                    },
                  ),
                  const _ScanReticle(),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _CountBadge(count: _scannedPassports.length, label: 'scanned'),
                  ),
                  const Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _ScanHint(text: 'Point camera at a passport QR code'),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    if (_scannedPassports.isNotEmpty)
                      TextButton(
                        onPressed: _clearScannedPassports,
                        child: const Text('Clear All', style: TextStyle(color: AppColors.danger)),
                      ),
                  ],
                ),
                Expanded(
                  child: _scannedPassports.isEmpty
                      ? const _EmptyState(
                          icon: Icons.qr_code_2_rounded,
                          message: 'No passports scanned yet',
                        )
                      : ListView.separated(
                          itemCount: _scannedPassports.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final passport = _scannedPassports[idx];
                            return _FlatCard(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  child: Icon(Icons.contact_mail_rounded, size: 18),
                                ),
                                title: Text(
                                  passport.holderName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('${passport.qrCode} • ID: ${passport.holderIdNo}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: AppColors.danger),
                                  onPressed: () => _removePassport(idx),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: _buttonStyle,
                    onPressed: _scannedPassports.isEmpty ? null : _loadAvailableBoxes,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Find Storage Box'),
                  ),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
          _buildRoomFilter(),
          const SizedBox(height: 8),
          _buildSearchField(),
          const SizedBox(height: 8),
          if (_totalBoxes > 0)
            Text(
              'Found $_totalBoxes boxes • Page $_currentPage of $_totalPages',
              style: const TextStyle(fontSize: 11, color: AppColors.textBody),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildBoxList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomFilter() {
    if (_isLoadingRooms) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (_rooms.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _selectedRoomId,
          hint: const Text('All rooms', style: TextStyle(fontSize: 14)),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('All rooms')),
            ..._rooms.map((room) => DropdownMenuItem<String?>(value: room.id, child: Text(room.name))),
          ],
          onChanged: _onRoomChanged,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _boxSearchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by box label or QR code...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _boxSearchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBoxList() {
    if (_isLoadingBoxes && _availableBoxes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableBoxes.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off,
        message: 'No suitable boxes found.\nTry different search terms.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: _availableBoxes.length + (_hasMoreBoxes ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              if (idx == _availableBoxes.length) {
                return Center(
                  child: _isLoadingBoxes
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        )
                      : OutlinedButton.icon(
                          onPressed: _loadNextPage,
                          icon: const Icon(Icons.expand_more),
                          label: Text('Load More (${_totalBoxes - _availableBoxes.length} remaining)'),
                        ),
                );
              }

              final box = _availableBoxes[idx];
              final vacantSlots = box.capacity - box.occupiedCount;
              final fits = vacantSlots >= _scannedPassports.length;

              return _buildBoxCard(box, vacantSlots, fits);
            },
          ),
        ),
        if (_totalPages > 1) _buildPaginationControls(),
      ],
    );
  }

  Widget _buildBoxCard(models.Box box, int vacantSlots, bool fits) {
    final spaceColor = fits ? AppColors.success : AppColors.danger;

    return _FlatCard(
      onTap: fits ? () => _selectBox(box) : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (fits ? AppColors.primary : AppColors.textHint).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: fits ? AppColors.primary : AppColors.textHint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(box.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  if (box.location != null)
                    Text(
                      box.location!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: spaceColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$vacantSlots vacant',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: spaceColor),
              ),
            ),
            if (fits) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _currentPage > 1 && !_isLoadingBoxes ? _goToPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Text(
            'Page $_currentPage of $_totalPages',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: _currentPage < _totalPages && !_isLoadingBoxes ? _goToNextPage : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: Scan Box QR Code ---
  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SingleChildScrollView(
        controller: _step3ScrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_mismatchMessage != null) ...[
              _MismatchBanner(
                message: _mismatchMessage!,
                onDismiss: _clearMismatch,
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Verify Physical Box',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark),
            ),
            const Text(
              'Scan the QR code on the physical box',
              style: TextStyle(color: AppColors.textBody, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _buildBoxInfoCard(),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Box QR Scanner - Step 3
                    // NOTE: Unlike Step 1, this does NOT debounce.
                    // Box QR scans should be immediate (single scan per box).
                    // The logic handles rapid detection by checking if QR matches.
                    MobileScanner(
                      onDetect: (capture) {
                        final barcode = capture.barcodes.firstOrNull;
                        if (barcode?.rawValue != null) {
                          _onBoxQrScanned(barcode!.rawValue!);
                        }
                      },
                    ),
                    const _ScanReticle(),
                    const Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(child: _ScanHint(text: 'Point camera at the box QR code')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Make sure you are scanning the QR code on the physical storage box',
              style: TextStyle(fontSize: 12, color: AppColors.textBody),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxInfoCard() {
    return _FlatCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Box: ${_selectedBox!.label}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Capacity: ${_selectedBox!.occupiedCount}/${_selectedBox!.capacity} slots',
                        style: const TextStyle(fontSize: 12, color: AppColors.textBody),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Expected QR: ${_selectedBox!.qrCode}',
              style: const TextStyle(fontSize: 13, color: AppColors.textBody, fontFamily: 'monospace'),
            ),
            Text(
              'Location: ${_selectedBox!.location ?? "Unassigned"}',
              style: const TextStyle(fontSize: 13, color: AppColors.textBody),
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 4: Scan Slot QR Code ---
  Widget _buildStep4() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_mismatchMessage != null) ...[
            _MismatchBanner(
              message: _mismatchMessage!,
              onDismiss: _clearMismatch,
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Select Storage Slot',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark),
          ),
          const Text(
            'Scan the QR code on the storage slot',
            style: TextStyle(color: AppColors.textBody, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _FlatCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check_circle, color: AppColors.success),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Box Verified: ${_selectedBox!.label}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Returning ${_scannedPassports.length} passports',
                              style: const TextStyle(fontSize: 12, color: AppColors.textBody),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    'Location: ${_selectedBox!.location ?? "Unassigned"}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textBody),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Slot QR Scanner - Step 4
                        // NOTE: Like Step 3, this does NOT debounce.
                        // Slot detection should be immediate and responsive.
                        // The UI immediately shows success feedback when detected.
                        MobileScanner(
                          onDetect: (capture) {
                            final barcode = capture.barcodes.firstOrNull;
                            if (barcode?.rawValue != null) {
                              _onSlotQrScanned(barcode!.rawValue!);
                            }
                          },
                        ),
                        const _ScanReticle(),
                        const Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(child: _ScanHint(text: 'Point camera at the slot QR code')),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_scannedSlotQr != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Slot scanned: $_scannedSlotQr',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _scannedSlotQr = null),
                          child: const Text('Rescan', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  const Text(
                    'Scan the QR code on the specific slot',
                    style: TextStyle(fontSize: 12, color: AppColors.textBody),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: _isSubmitting
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : ElevatedButton.icon(
                          style: _buttonStyle,
                          onPressed: _scannedSlotQr == null ? null : _executeBatchReturn,
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Complete Return'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// === HELPER WIDGETS ===

class _ScanReticle extends StatelessWidget {
  const _ScanReticle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _Constants.scanReticleWidth,
        height: _Constants.scanReticleHeight,
        child: Stack(
          children: [
            for (final alignment in [
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomLeft,
              Alignment.bottomRight,
            ])
              Align(alignment: alignment, child: _ReticleCorner(alignment: alignment)),
          ],
        ),
      ),
    );
  }
}

class _ReticleCorner extends StatelessWidget {
  final Alignment alignment;
  const _ReticleCorner({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}

class _ScanHint extends StatelessWidget {
  final String text;
  const _ScanHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final String label;
  const _CountBadge({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
      child: Text(
        '$count $label',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FlatCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _FlatCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: child),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textBody)),
        ],
      ),
    );
  }
}

class _MismatchBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _MismatchBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.warning),
            Expanded(
              child: Container(
                color: AppColors.warning.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onDismiss,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, size: 16, color: AppColors.textHint),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
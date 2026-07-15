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
class _Constants {
  static const int scanDebounceMs = 800;
  static const int feedbackThrottleMs = 500;
  static const int processingQrExpiryMs = 2000;
  static const int searchDebounceMs = 500;
  static const int boxPaginationLimit = 15;
  static const double scanReticleWidth = 220;
  static const double scanReticleHeight = 140;
  static const List<String> stepLabels = ['Scan', 'Select Box', 'Scan Box'];
}

class PassportReturnPage extends StatefulWidget {
  const PassportReturnPage({super.key});

  @override
  State<PassportReturnPage> createState() => _PassportReturnPageState();
}

class _PassportReturnPageState extends State<PassportReturnPage> {
  // Repositories
  final PassportRepository _passportRepo = PassportRepository();
  final BoxRepository _boxRepo = BoxRepository();
  final LocationRepository _locationRepo = LocationRepository();

  // Step and global status
  int _currentStep = 1;
  bool _isSubmitting = false;

  // Step 1: Passport Scan Stack
  final List<Passport> _scannedPassports = [];
  final Set<String> _detectedBarcodes = {};
  final Set<String> _failedQrs = {};
  DateTime? _lastFeedbackTime;
  Timer? _scanDebounceTimer;

  // Step 2: Box Selection & Pagination
  List<models.Box> _availableBoxes = [];
  models.Box? _selectedBox;
  bool _isLoadingBoxes = false;
  final TextEditingController _boxSearchController = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalBoxes = 0;
  bool _hasMoreBoxes = false;
  String _searchQuery = '';
  String? _selectedRoomId;
  List<Room> _rooms = [];
  bool _isLoadingRooms = false;
  Timer? _searchDebounceTimer;

  // Step 3: Physical Box Custody Verification
  String? _scannedBoxQr;
  String? _mismatchMessage;

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
    _searchDebounceTimer?.cancel();
    _scanDebounceTimer?.cancel();
    super.dispose();
  }

  // Feedback display helper
  void _showFeedback(String message, bool isError) {
    final now = DateTime.now();
    if (_lastFeedbackTime != null &&
        now.difference(_lastFeedbackTime!).inMilliseconds < _Constants.feedbackThrottleMs) {
      return;
    }
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

  void _raiseMismatch(String message) {
    if (!mounted) return;
    setState(() => _mismatchMessage = message);
    _showFeedback(message, true);
    if (_currentStep == 3 && _step3ScrollController.hasClients) {
      _step3ScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _clearMismatch() {
    if (mounted) {
      setState(() => _mismatchMessage = null);
    }
  }

  void _goToStep(int step) {
    if (!mounted) return;
    setState(() {
      _currentStep = step;
      _clearMismatch();
      if (step < 3) {
        _scannedBoxQr = null;
      }
    });
  }

  void _goBack() {
    if (_currentStep > 1) {
      _goToStep(_currentStep - 1);
    } else {
      context.pop();
    }
  }

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
  // STEP 1: SCAN PASSPORTS
  // ============================================================================
  void _onBarcode(String code) {
    if (_detectedBarcodes.contains(code) || _failedQrs.contains(code)) {
      return;
    }

    _scanDebounceTimer?.cancel();
    _scanDebounceTimer = Timer(
      const Duration(milliseconds: _Constants.scanDebounceMs),
      () {
        if (mounted) {
          _addPassportByQr(code);
        }
      }
    );
  }

  Future<void> _addPassportByQr(String code) async {
    if (_scannedPassports.any((p) => p.qrCode == code) || _failedQrs.contains(code)) {
      return;
    }

    _detectedBarcodes.add(code);

    try {
      final passport = await _passportRepo.getByQr(code);
      if (passport == null) {
        _failedQrs.add(code);
        _showFeedback('Passport not found: $code', true);
        return;
      }

      if (!passport.isIssued) {
        _failedQrs.add(code);
        _showFeedback(
          '${passport.holderName} is currently ${passport.status} — only ISSUED passports can be returned',
          true,
        );
        return;
      }

      if (!mounted) return;
      setState(() => _scannedPassports.add(passport));
      _showFeedback('Added: ${passport.holderName}', false);
    } catch (e) {
      _failedQrs.add(code);
      _showFeedback('Error looking up passport: $e', true);
    } finally {
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
      _failedQrs.clear();
    });
  }

  void _removePassport(int idx) {
    setState(() => _scannedPassports.removeAt(idx));
  }

  // ============================================================================
  // STEP 2: SELECT BOX (PAGINATED & ROOM FILTERED)
  // ============================================================================
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
        _showFeedback('Failed to load available boxes', true);
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

  // ============================================================================
  // STEP 3: SCAN & VERIFY BOX QR
  // ============================================================================
  void _onBoxQrScanned(String scannedQr) async {
    if (_selectedBox == null) return;
    if (_isSubmitting) return;

    if (scannedQr == _selectedBox!.qrCode) {
      if (!mounted) return;
      setState(() {
        _scannedBoxQr = scannedQr;
        _clearMismatch();
      });
      _showFeedback('Box QR verified', false);
    } else {
      setState(() => _isSubmitting = true);
      try {
        final scannedBox = await _boxRepo.getByQr(scannedQr);
        setState(() => _isSubmitting = false);

        if (scannedBox == null) {
          _raiseMismatch('Wrong box QR scanned. Expected ${_selectedBox!.label}, but scanned QR code is unrecognized in the system.');
          return;
        }

        _showMismatchOptionsDialog(scannedBox);
      } catch (e) {
        setState(() => _isSubmitting = false);
        _raiseMismatch('Error looking up scanned box: $e');
      }
    }
  }

  void _showMismatchOptionsDialog(models.Box scannedBox) {
    final fits = (scannedBox.capacity - scannedBox.occupiedCount) >= _scannedPassports.length;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                SizedBox(width: 12),
                Text(
                  'Physical Box Mismatch',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Expected Box: ${_selectedBox!.label}\nScanned Box: ${scannedBox.label} (${scannedBox.location ?? "Unassigned Location"})',
              style: const TextStyle(fontSize: 14, color: AppColors.primaryDark, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (!fits)
              const Text(
                'Note: The physically scanned box does not have enough capacity for your stack.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
              )
            else
              Text(
                'The physically scanned box has ${scannedBox.capacity - scannedBox.occupiedCount} vacant slots, which fits your ${_scannedPassports.length} passports.',
                style: const TextStyle(color: AppColors.textBody, fontSize: 13),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _goToStep(2);
                    },
                    child: const Text('Find Correct Box'),
                  ),
                ),
                const SizedBox(width: 12),
                if (fits)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedBox = scannedBox;
                          _scannedBoxQr = scannedBox.qrCode;
                          _clearMismatch();
                        });
                        _showFeedback('Switched to physically scanned box: ${scannedBox.label}', false);
                      },
                      child: Text('Use ${scannedBox.label}'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel & Rescan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // EXECUTE RETURN SUBMISSION
  // ============================================================================
  Future<void> _executeBatchReturn() async {
    if (_selectedBox == null || _scannedBoxQr == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final passportIds = _scannedPassports.map((p) => p.id).toList();
      await _passportRepo.batchAssign(
        passportIds: passportIds,
        boxId: _selectedBox!.id,
        action: 'PASSPORT_RETURNED',
      );

      setState(() => _isSubmitting = false);
      _showSuccessDialog();
    } on DioException catch (dioErr) {
      setState(() => _isSubmitting = false);
      _handleReturnError(dioErr);
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showFeedback('Return failed: $e', true);
    }
  }

  void _handleReturnError(DioException dioErr) {
    final responseData = dioErr.response?.data;
    final message = (responseData is Map ? responseData['message'] : null) ?? 'Network error';
    _showFeedback(message, true);
  }

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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: const BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
      _failedQrs.clear();
      _selectedBox = null;
      _scannedBoxQr = null;
      _mismatchMessage = null;
      _currentStep = 1;
    });
  }

  // ============================================================================
  // UI BUILDERS
  // ============================================================================
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
        children: List.generate(_Constants.stepLabels.length, (idx) {
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
                if (idx < _Constants.stepLabels.length - 1)
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
      default:
        return const SizedBox();
    }
  }

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
                  MobileScanner(
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      if (barcode?.rawValue != null) {
                        _onBarcode(barcode!.rawValue!);
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
                    onPressed: _scannedPassports.isEmpty ? null : () => _loadAvailableBoxes(resetPage: true),
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
        message: 'No suitable boxes found.\nTry changing your filters.',
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

  Widget _buildStep3() {
    final boxVerified = _scannedBoxQr != null;
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
            Text(
              boxVerified ? 'Confirm Return' : 'Verify Physical Box',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark),
            ),
            Text(
              boxVerified
                  ? 'Box verified. Review the details and complete the return.'
                  : 'Scan the QR code on the physical box to verify box custody identity.',
              style: const TextStyle(color: AppColors.textBody, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (!boxVerified) ...[
              _buildBoxInfoCard(),
              const SizedBox(height: 20),
              SizedBox(
                height: 280,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
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
                        child: Center(
                            child: _ScanHint(text: 'Point camera at Box QR code')),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              _buildVerifiedBoxCard(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _scannedBoxQr = null;
                            _clearMismatch();
                          });
                        },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Rescan Box'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: _buttonStyle,
                        onPressed: _executeBatchReturn,
                        child: const Text('Complete Return & Assign'),
                      ),
              ),
            ],
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
                        'Target Box: ${_selectedBox!.label}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Capacity: ${_selectedBox!.occupiedCount}/${_selectedBox!.capacity} occupied',
                        style: const TextStyle(fontSize: 12, color: AppColors.textBody),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Expected QR Code: ${_selectedBox!.qrCode}',
              style: const TextStyle(fontSize: 12, color: AppColors.textBody, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 4),
            Text(
              'Expected Location: ${_selectedBox!.location ?? "Unassigned"}',
              style: const TextStyle(fontSize: 12, color: AppColors.textBody),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedBoxCard() {
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
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified Box: ${_selectedBox!.label}',
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
              'Expected Location: ${_selectedBox!.location ?? "Unassigned"}',
              style: const TextStyle(fontSize: 12, color: AppColors.textBody),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================
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
            color: AppColors.primaryDark.withOpacity(0.04),
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
                color: AppColors.warning.withOpacity(0.1),
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
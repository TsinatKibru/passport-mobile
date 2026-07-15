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
import '../../../l10n/app_localizations.dart';
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
    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? c.danger : c.success,
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

  // Map a raw backend passport status onto its localised label.
  String _returnStatusLabel(AppLocalizations l, String status) {
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
        _showFeedback(AppLocalizations.of(context).returnFailedLoadRooms, true);
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

    final l = AppLocalizations.of(context);
    try {
      final passport = await _passportRepo.getByQr(code);
      if (passport == null) {
        _failedQrs.add(code);
        _showFeedback(l.scanPassportNotFound(code), true);
        return;
      }

      if (!passport.isIssued) {
        _failedQrs.add(code);
        _showFeedback(
          l.returnOnlyIssued(
              passport.holderName, _returnStatusLabel(l, passport.status)),
          true,
        );
        return;
      }

      if (!mounted) return;
      setState(() => _scannedPassports.add(passport));
      _showFeedback(l.returnAdded(passport.holderName), false);
    } catch (e) {
      _failedQrs.add(code);
      _showFeedback(l.returnErrLookupPassport('$e'), true);
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
        _showFeedback(AppLocalizations.of(context).returnFailedLoadBoxes, true);
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

    final l = AppLocalizations.of(context);
    if (scannedQr == _selectedBox!.qrCode) {
      if (!mounted) return;
      setState(() {
        _scannedBoxQr = scannedQr;
        _clearMismatch();
      });
      _showFeedback(l.returnBoxQrVerified, false);
    } else {
      setState(() => _isSubmitting = true);
      try {
        final scannedBox = await _boxRepo.getByQr(scannedQr);
        setState(() => _isSubmitting = false);

        if (scannedBox == null) {
          _raiseMismatch(l.returnWrongBoxQr(_selectedBox!.label));
          return;
        }

        _showMismatchOptionsDialog(scannedBox);
      } catch (e) {
        setState(() => _isSubmitting = false);
        _raiseMismatch(l.returnErrLookupBox('$e'));
      }
    }
  }

  void _showMismatchOptionsDialog(models.Box scannedBox) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final fits = (scannedBox.capacity - scannedBox.occupiedCount) >= _scannedPassports.length;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: c.card,
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
              children: [
                Icon(Icons.warning_amber_rounded, color: c.warning, size: 28),
                const SizedBox(width: 12),
                Text(
                  l.returnMismatchTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l.returnMismatchDetail(
                _selectedBox!.label,
                scannedBox.label,
                scannedBox.location ?? l.returnUnassignedLocation,
              ),
              style: TextStyle(fontSize: 14, color: c.primaryDark, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (!fits)
              Text(
                l.returnMismatchNoCapacity,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
              )
            else
              Text(
                l.returnMismatchFits(
                    scannedBox.capacity - scannedBox.occupiedCount, _scannedPassports.length),
                style: TextStyle(color: c.textBody, fontSize: 13),
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
                    child: Text(l.returnFindCorrectBox),
                  ),
                ),
                const SizedBox(width: 12),
                if (fits)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.onPrimary,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedBox = scannedBox;
                          _scannedBoxQr = scannedBox.qrCode;
                          _clearMismatch();
                        });
                        _showFeedback(l.returnSwitchedBox(scannedBox.label), false);
                      },
                      child: Text(l.returnUseBox(scannedBox.label)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.returnCancelRescan),
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
      _showFeedback(AppLocalizations.of(context).returnFailed('$e'), true);
    }
  }

  void _handleReturnError(DioException dioErr) {
    final responseData = dioErr.response?.data;
    final message = (responseData is Map ? responseData['message'] : null) ??
        AppLocalizations.of(context).returnNetworkError;
    _showFeedback(message, true);
  }

  void _showSuccessDialog() {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final count = _scannedPassports.length;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: c.card,
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
              decoration: BoxDecoration(
                color: c.success,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 32),
                  const SizedBox(height: 10),
                  Text(
                    l.returnPassportsReturned(count),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.returnStoredIn(_selectedBox!.label),
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
                          backgroundColor: c.surface,
                          side: BorderSide(color: c.border),
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
                      child: Text(l.returnBackToDashboard),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _resetForNewBatch();
                    },
                    child: Text(l.returnAnotherBatch),
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
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
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
                      color: c.card,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_rounded,
                            color: c.primaryDark, size: 20),
                        onPressed: _goBack,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).returnFlowTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: c.primaryDark,
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
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final stepLabels = [l.returnStepScan, l.returnStepSelectBox, l.returnStepScanBox];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
      child: Row(
        children: List.generate(stepLabels.length, (idx) {
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
                        color: isActive ? c.primary : c.card,
                        border: Border.all(
                          color: isActive ? c.primary : c.border,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? Icon(Icons.check_rounded, size: 15, color: c.onPrimary)
                            : Text(
                                '$stepNum',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? c.onPrimary : c.textHint,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stepLabels[idx],
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? c.primaryDark : c.textHint,
                      ),
                    ),
                  ],
                ),
                if (idx < stepLabels.length - 1)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: stepNum < _currentStep ? c.primary : c.border,
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
    final l = AppLocalizations.of(context);
    final c = context.colors;
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
                    child: _CountBadge(count: _scannedPassports.length, label: l.returnScannedLabel),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _ScanHint(text: l.returnScanPassportHint),
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
                      l.returnScannedStack(_scannedPassports.length),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: c.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    if (_scannedPassports.isNotEmpty)
                      TextButton(
                        onPressed: _clearScannedPassports,
                        child: Text(l.returnClearAll, style: TextStyle(color: c.danger)),
                      ),
                  ],
                ),
                Expanded(
                  child: _scannedPassports.isEmpty
                      ? _EmptyState(
                          icon: Icons.qr_code_2_rounded,
                          message: l.returnNoPassportsYet,
                        )
                      : ListView.separated(
                          itemCount: _scannedPassports.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final passport = _scannedPassports[idx];
                            return _FlatCard(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                leading: CircleAvatar(
                                  backgroundColor: c.primary,
                                  foregroundColor: c.onPrimary,
                                  child: const Icon(Icons.contact_mail_rounded, size: 18),
                                ),
                                title: Text(
                                  passport.holderName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(l.returnPassportSubtitle(passport.qrCode, passport.holderIdNo)),
                                trailing: IconButton(
                                  icon: Icon(Icons.remove_circle_outline,
                                      color: c.danger),
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
                    label: Text(l.returnFindStorageBox),
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
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.returnSelectTargetBox,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: c.primaryDark),
          ),
          Text(
            l.returnShowingBoxes(_scannedPassports.length),
            style: TextStyle(color: c.textBody, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildRoomFilter(),
          const SizedBox(height: 8),
          _buildSearchField(),
          const SizedBox(height: 8),
          if (_totalBoxes > 0)
            Text(
              l.returnFoundBoxes(_totalBoxes, _currentPage, _totalPages),
              style: TextStyle(fontSize: 11, color: c.textBody),
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
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (_isLoadingRooms) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (_rooms.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _selectedRoomId,
          hint: Text(l.returnAllRooms, style: const TextStyle(fontSize: 14)),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(l.returnAllRooms)),
            ..._rooms.map((room) => DropdownMenuItem<String?>(value: room.id, child: Text(room.name))),
          ],
          onChanged: _onRoomChanged,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.primaryDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _boxSearchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).returnSearchHint,
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
    final l = AppLocalizations.of(context);
    if (_isLoadingBoxes && _availableBoxes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableBoxes.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off,
        message: l.returnNoSuitableBoxes,
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
                          label: Text(l.returnLoadMoreRemaining(_totalBoxes - _availableBoxes.length)),
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
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final spaceColor = fits ? c.success : c.danger;

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
                color: (fits ? c.primary : c.textHint).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: fits ? c.primary : c.textHint,
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
                      style: TextStyle(fontSize: 11, color: c.textHint),
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
                l.returnVacant(vacantSlots),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: spaceColor),
              ),
            ),
            if (fits) ...[
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: c.textHint),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _currentPage > 1 && !_isLoadingBoxes ? _goToPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
            label: Text(l.returnPrevious),
          ),
          Text(
            l.returnPageOf(_currentPage, _totalPages),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: _currentPage < _totalPages && !_isLoadingBoxes ? _goToNextPage : null,
            icon: const Icon(Icons.chevron_right),
            label: Text(l.returnNext),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final l = AppLocalizations.of(context);
    final c = context.colors;
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
              boxVerified ? l.returnConfirmReturn : l.returnVerifyPhysicalBox,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: c.primaryDark),
            ),
            Text(
              boxVerified ? l.returnBoxVerifiedDesc : l.returnScanBoxDesc,
              style: TextStyle(color: c.textBody, fontSize: 12),
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
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                            child: _ScanHint(text: l.returnScanBoxHint)),
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
                  label: Text(l.returnRescanBox),
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
                        child: Text(l.returnCompleteAssign),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBoxInfoCard() {
    final l = AppLocalizations.of(context);
    final c = context.colors;
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
                    color: c.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: c.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.scanTargetBox(_selectedBox!.label),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        l.returnCapacity(_selectedBox!.occupiedCount, _selectedBox!.capacity),
                        style: TextStyle(fontSize: 12, color: c.textBody),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              l.returnExpectedQr(_selectedBox!.qrCode),
              style: TextStyle(fontSize: 12, color: c.textBody, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 4),
            Text(
              l.returnExpectedLocation(_selectedBox!.location ?? l.returnUnassigned),
              style: TextStyle(fontSize: 12, color: c.textBody),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedBoxCard() {
    final l = AppLocalizations.of(context);
    final c = context.colors;
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
                    color: c.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.check_circle_rounded, color: c.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.returnVerifiedBox(_selectedBox!.label),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        l.returnReturningCount(_scannedPassports.length),
                        style: TextStyle(fontSize: 12, color: c.textBody),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              l.returnExpectedLocation(_selectedBox!.location ?? l.returnUnassigned),
              style: TextStyle(fontSize: 12, color: c.textBody),
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
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(20)),
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
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.primaryDark.withOpacity(0.04),
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
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: c.textHint),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: c.textBody)),
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
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: c.warning),
            Expanded(
              child: Container(
                color: c.warning.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: c.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: c.primaryDark,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onDismiss,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, size: 16, color: c.textHint),
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
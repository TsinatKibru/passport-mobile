import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/passport_repository.dart';
import '../../../data/models/passport.dart';
import '../widgets/glass_card.dart';
import '../widgets/fingerprint_background.dart';

class PassportIssuePage extends StatefulWidget {
  const PassportIssuePage({super.key});

  @override
  State<PassportIssuePage> createState() => _PassportIssuePageState();
}

class _PassportIssuePageState extends State<PassportIssuePage> {
  final PassportRepository _passportRepo = PassportRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  List<Passport> _passports = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _page = 1;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPassports();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _fetchPassports({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _isLoading = true;
        _hasMore = true;
        _errorMessage = null;
        _passports = [];
      });
    }

    try {
      final results = await _passportRepo.getAll(
        status: 'IN_BOX',
        search: _searchQuery,
        page: _page,
        limit: 15,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _passports = results;
          } else {
            _passports.addAll(results);
          }
          _isLoading = false;
          _isLoadingMore = false;
          if (results.length < 15) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = 'Failed to fetch passports. Tap to retry.';
        });
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
      _page++;
    });
    await _fetchPassports(refresh: false);
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _fetchPassports(refresh: true);
  }

  void _startIssueVerification(Passport passport) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IssueScanSheet(
        passport: passport,
        onVerified: () async {
          Navigator.pop(context); // close sheet
          setState(() => _isLoading = true);
          final success = await _passportRepo.issue(passport.id);
          setState(() => _isLoading = false);

          if (success) {
            _showFeedback('Passport successfully issued to ${passport.holderName}', false);
            _fetchPassports(refresh: true);
          } else {
            _showFeedback('Failed to update backend. Try again.', true);
          }
        },
      ),
    );
  }

  void _showFeedback(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FingerprintBackground(
        child: RefreshIndicator(
          onRefresh: () => _fetchPassports(refresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  title: Text(
                    'Passport Issuance',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),

              // Search box
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _onSearch,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Search by Holder Name, ID, QR...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textBody, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearch('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        filled: false,
                      ),
                    ),
                  ),
                ),
              ),

              // Passports list
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, style: const TextStyle(color: AppColors.textBody)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _fetchPassports(refresh: true),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 40),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_passports.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No passports available for issuance.',
                      style: TextStyle(color: AppColors.textBody),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) {
                        if (idx == _passports.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final passport = _passports[idx];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildPassportCard(passport),
                        );
                      },
                      childCount: _passports.length + (_isLoadingMore ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassportCard(Passport passport) {
    final boxLocation = passport.box?.location ?? 'No registered location';
    final boxLabel = passport.box?.label ?? 'Unassigned Box';
    final boxQr = passport.box?.qrCode ?? 'N/A';

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    passport.holderName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    passport.qrCode,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Holder ID: ${passport.holderIdNo}',
              style: const TextStyle(fontSize: 13, color: AppColors.textBody),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.textBody),
                const SizedBox(width: 6),
                Text(
                  '$boxLabel ($boxQr)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textBody),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    boxLocation,
                    style: const TextStyle(fontSize: 12, color: AppColors.textBody),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _startIssueVerification(passport),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Confirm Identity & Issue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueScanSheet extends StatefulWidget {
  final Passport passport;
  final VoidCallback onVerified;

  const _IssueScanSheet({
    required this.passport,
    required this.onVerified,
  });

  @override
  State<_IssueScanSheet> createState() => _IssueScanSheetState();
}

class _IssueScanSheetState extends State<_IssueScanSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = true;
  String? _errorMsg;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      _verifyCode(barcode!.rawValue!);
    }
  }

  void _verifyCode(String code) {
    setState(() {
      _isScanning = false;
    });

    if (code == widget.passport.qrCode) {
      widget.onVerified();
    } else {
      setState(() {
        _errorMsg = 'Incorrect passport QR scanned: $code\nExpected: ${widget.passport.qrCode}';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorMsg = null;
            _isScanning = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan Passport QR Code',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Confirming: ${widget.passport.holderName}',
            style: const TextStyle(fontSize: 13, color: AppColors.textBody),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 250,
              width: double.infinity,
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_errorMsg != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            )
          else
            const Text(
              'Align the passport QR code inside the camera preview.',
              style: TextStyle(color: AppColors.textBody, fontSize: 12),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.border,
              foregroundColor: AppColors.onSurface,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/passport_repository.dart';
import '../../../data/models/passport.dart';
import '../widgets/fingerprint_background.dart';

// ─── Status filter options ────────────────────────────────────────────────────
enum _StatusFilter { inBox, issued, all }

extension _StatusFilterExt on _StatusFilter {
  String get label => switch (this) {
    _StatusFilter.inBox   => 'In Box',
    _StatusFilter.issued  => 'Issued',
    _StatusFilter.all     => 'All',
  };
  String? get apiValue => switch (this) {
    _StatusFilter.inBox  => 'IN_BOX',
    _StatusFilter.issued => 'ISSUED',
    _StatusFilter.all    => null,
  };
}

class PassportIssuePage extends StatefulWidget {
  const PassportIssuePage({super.key});

  @override
  State<PassportIssuePage> createState() => _PassportIssuePageState();
}

class _PassportIssuePageState extends State<PassportIssuePage> {
  final PassportRepository _passportRepo = PassportRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  _StatusFilter _activeFilter = _StatusFilter.inBox;
  bool _compactView = false;
  String _searchQuery = '';
  List<Passport> _passports = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _page = 1;
  int _total = 0;
  bool _hasMore = true;
  String? _errorMessage;

  // Debounce search
  DateTime? _lastSearchTime;

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
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300 &&
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
        _total = 0;
      });
    }

    try {
      final results = await _passportRepo.getAll(
        status: _activeFilter.apiValue,
        search: _searchQuery,
        page: _page,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _passports = results;
        } else {
          _passports.addAll(results);
        }
        _isLoading = false;
        _isLoadingMore = false;
        if (results.length < 20) _hasMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'Failed to load passports. Tap to retry.';
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
      _page++;
    });
    await _fetchPassports(refresh: false);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    final now = DateTime.now();
    _lastSearchTime = now;
    Future.delayed(const Duration(milliseconds: 450), () {
      if (_lastSearchTime == now) _fetchPassports(refresh: true);
    });
  }

  void _setFilter(_StatusFilter filter) {
    if (filter == _activeFilter) return;
    setState(() => _activeFilter = filter);
    _fetchPassports(refresh: true);
  }

  void _startIssueVerification(Passport passport) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IssueScanSheet(
        passport: passport,
        onVerified: () async {
          Navigator.pop(context);
          setState(() => _isLoading = true);
          final success = await _passportRepo.issue(passport.id);
          setState(() => _isLoading = false);
          if (success) {
            _showFeedback('Issued to ${passport.holderName}', false);
            _fetchPassports(refresh: true);
          } else {
            _showFeedback('Issue failed — please try again.', true);
          }
        },
      ),
    );
  }

  void _showFeedback(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
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
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Pinned header ──────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: Colors.white,
                elevation: 0,
                expandedHeight: 100,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  title: const Text(
                    'Passport Issuance',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),

              // ── Search bar ─────────────────────────────────────────────
              SliverToBoxAdapter(child: _SearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )),

              // ── Filter chips ───────────────────────────────────────────
              SliverToBoxAdapter(child: _FilterChipRow(
                active: _activeFilter,
                onChanged: _setFilter,
                total: _total,
                loaded: _passports.length,
                compactView: _compactView,
                onToggleView: () => setState(() => _compactView = !_compactView),
              )),

              // ── Body ───────────────────────────────────────────────────
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(child: _ErrorState(
                  message: _errorMessage!,
                  onRetry: () => _fetchPassports(refresh: true),
                ))
              else if (_passports.isEmpty)
                SliverFillRemaining(child: _EmptyState(
                  filter: _activeFilter,
                  hasSearch: _searchQuery.isNotEmpty,
                ))
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20, 4, 20, _compactView ? 80 : 110,
                  ),
                  sliver: _compactView
                      ? _CompactListSliver(
                          passports: _passports,
                          hasMore: _hasMore,
                          isLoadingMore: _isLoadingMore,
                          onIssue: _startIssueVerification,
                          onLoadMore: _loadMore,
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, idx) {
                              if (idx == _passports.length) {
                                return _isLoadingMore
                                    ? const _LoadMoreIndicator()
                                    : _hasMore
                                        ? _LoadMoreButton(onTap: _loadMore)
                                        : const _EndOfListLabel();
                              }
                              final p = _passports[idx];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _PassportCard(
                                  passport: p,
                                  onIssue: () => _startIssueVerification(p),
                                ),
                              );
                            },
                            childCount: _passports.length + 1,
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search bar widget ────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
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
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Name, ID number, or QR code…',
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textHint,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textBody, size: 20),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textBody),
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

// ─── Filter chip row ──────────────────────────────────────────────────────────
class _FilterChipRow extends StatelessWidget {
  final _StatusFilter active;
  final ValueChanged<_StatusFilter> onChanged;
  final int total;
  final int loaded;
  final bool compactView;
  final VoidCallback onToggleView;

  const _FilterChipRow({
    required this.active,
    required this.onChanged,
    required this.total,
    required this.loaded,
    required this.compactView,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          ..._StatusFilter.values.map((f) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Chip(
              label: f.label,
              isActive: f == active,
              onTap: () => onChanged(f),
            ),
          )),
          const Spacer(),
          if (loaded > 0)
            Text(
              '$loaded loaded',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(width: 10),
          // View toggle
          GestureDetector(
            onTap: onToggleView,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: compactView
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: compactView ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Icon(
                compactView
                    ? Icons.view_list_rounded
                    : Icons.view_agenda_rounded,
                size: 16,
                color: compactView ? AppColors.primary : AppColors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textBody,
          ),
        ),
      ),
    );
  }
}

// ─── Passport card ────────────────────────────────────────────────────────────
class _PassportCard extends StatelessWidget {
  final Passport passport;
  final VoidCallback onIssue;

  const _PassportCard({required this.passport, required this.onIssue});

  @override
  Widget build(BuildContext context) {
    final isInBox = passport.status == 'IN_BOX';
    final statusColor = isInBox ? AppColors.primary : AppColors.warning;
    final statusLabel = isInBox ? 'In Box' : 'Issued';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: avatar + name + status ──────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(name: passport.holderName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passport.holderName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${passport.holderIdNo}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 12),
              // ── QR code row ───────────────────────────────────────────
              _QrRow(qr: passport.qrCode),
              const SizedBox(height: 8),
              // ── Location breadcrumb ───────────────────────────────────
              if (passport.box != null)
                _LocationBreadcrumb(
                  box: passport.box!,
                  fullLocation: passport.location,
                ),
              const SizedBox(height: 14),
              // ── Action button (only for IN_BOX passports) ─────────────
              if (isInBox)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onIssue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                    label: const Text('Confirm Identity & Issue'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Small reusable sub-widgets ───────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _QrRow extends StatelessWidget {
  final String qr;
  const _QrRow({required this.qr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.qr_code_rounded, size: 14, color: AppColors.textHint),
        const SizedBox(width: 6),
        Text(
          qr,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textBody,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _LocationBreadcrumb extends StatelessWidget {
  final BoxSummary box;
  final String? fullLocation; // top-level passport.location from API

  const _LocationBreadcrumb({
    required this.box,
    required this.fullLocation,
  });

  @override
  Widget build(BuildContext context) {
    // Prefer the full location path from the passport root field.
    // Fall back to box.location if somehow missing.
    final locationStr = fullLocation ?? box.location;
    final parts = locationStr?.split(' / ') ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Box label row
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 13, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                '${box.label}  ·  ${box.qrCode}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          // Full location path
          if (parts.isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textHint),
                const SizedBox(width: 5),
                Expanded(
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (int i = 0; i < parts.length; i++) ...[
                        Text(
                          parts[i],
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: i == parts.length - 1
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: i == parts.length - 1
                                ? AppColors.textBody
                                : AppColors.textHint,
                          ),
                        ),
                        if (i < parts.length - 1)
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 11,
                            color: AppColors.textHint,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── List state widgets ───────────────────────────────────────────────────────

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LoadMoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.expand_more_rounded, size: 16),
          label: const Text('Load more'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }
}

class _EndOfListLabel extends StatelessWidget {
  const _EndOfListLabel();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          '— End of list —',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textBody),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final _StatusFilter filter;
  final bool hasSearch;
  const _EmptyState({required this.filter, required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    final message = hasSearch
        ? 'No passports match your search.'
        : filter == _StatusFilter.inBox
            ? 'All passports have been issued.'
            : filter == _StatusFilter.issued
                ? 'No issued passports at the moment.'
                : 'No passports found.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.badge_outlined, size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact row (dense list view) ───────────────────────────────────────────
class _PassportCompactRow extends StatelessWidget {
  final Passport passport;
  final VoidCallback onTap;
  final bool isLast;

  const _PassportCompactRow({
    required this.passport,
    required this.onTap,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isInBox = passport.status == 'IN_BOX';
    final statusColor = isInBox ? AppColors.primary : AppColors.warning;

    // Build a short location string: last 2 parts of the path or box label
    final locationParts = (passport.location ?? passport.box?.location)?.split(' / ') ?? [];
    final shortLocation = locationParts.length >= 2
        ? '${locationParts[locationParts.length - 2]} › ${locationParts.last}'
        : passport.box?.label ?? '—';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: isInBox ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Status dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Name + ID
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passport.holderName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      passport.holderIdNo,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Location pill
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    shortLocation,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: AppColors.textBody,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Issue icon (only IN_BOX)
              if (isInBox)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textHint,
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Compact list wrapper (card with dividers) ────────────────────────────────
// Note: rows are wrapped in a rounded card by the sliver padding.
// The dividers are handled via isLast flag on each row.
class _CompactListSliver extends StatelessWidget {
  final List<Passport> passports;
  final bool hasMore;
  final bool isLoadingMore;
  final void Function(Passport) onIssue;
  final VoidCallback onLoadMore;

  const _CompactListSliver({
    required this.passports,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onIssue,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // All passport rows grouped in one card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < passports.length; i++) ...[
                _PassportCompactRow(
                  passport: passports[i],
                  onTap: () => onIssue(passports[i]),
                  isLast: i == passports.length - 1,
                ),
                if (i < passports.length - 1)
                  const Divider(height: 1, indent: 36, endIndent: 0),
              ],
            ],
          ),
        ),
        // Footer
        if (isLoadingMore)
          const _LoadMoreIndicator()
        else if (hasMore)
          _LoadMoreButton(onTap: onLoadMore)
        else
          const _EndOfListLabel(),
      ]),
    );
  }
}

// ─── QR scan confirmation sheet ───────────────────────────────────────────────
class _IssueScanSheet extends StatefulWidget {
  final Passport passport;
  final VoidCallback onVerified;

  const _IssueScanSheet({required this.passport, required this.onVerified});

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
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null) _verifyCode(code);
  }

  void _verifyCode(String code) {
    setState(() => _isScanning = false);
    if (code == widget.passport.qrCode) {
      widget.onVerified();
    } else {
      setState(() => _errorMsg = 'Wrong QR — expected ${widget.passport.qrCode}');
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() { _errorMsg = null; _isScanning = true; });
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Scan to Confirm',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.passport.holderName,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 240,
              width: double.infinity,
              child: MobileScanner(controller: _controller, onDetect: _onDetect),
            ),
          ),
          const SizedBox(height: 16),
          if (_errorMsg != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            )
          else
            const Text(
              'Point the camera at the passport QR code to confirm identity.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textBody),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textBody,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/box_repository.dart';
import '../../../data/models/box.dart' as models;
import '../../../l10n/app_localizations.dart';
import '../widgets/glass_card.dart';
import '../widgets/fingerprint_background.dart';

class BoxesPage extends StatefulWidget {
  const BoxesPage({super.key});

  @override
  State<BoxesPage> createState() => _BoxesPageState();
}

class _BoxesPageState extends State<BoxesPage> {
  final BoxRepository _boxRepo = BoxRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _activeFilter = 'ALL'; // 'ALL', 'ACTIVE', 'FULL', 'INACTIVE'
  bool _isLoading = false;
  String? _errorMessage;

  List<models.Box> _boxes = [];
  bool _isGridView = false;

  // Backend pagination (infinite scroll)
  static const int _pageLimit = 20;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchBoxes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  // First page / pull-to-refresh.
  Future<void> _fetchBoxes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _page = 1;
    });
    try {
      final results = await _boxRepo.getAll(
        status: _activeFilter == 'ALL' ? null : _activeFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: 1,
        limit: _pageLimit,
      );
      if (mounted) {
        setState(() {
          _boxes = results;
          _hasMore = results.length == _pageLimit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context).boxesLoadFailed;
        });
      }
    }
  }

  // Append the next page (infinite scroll).
  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    final next = _page + 1;
    try {
      final results = await _boxRepo.getAll(
        status: _activeFilter == 'ALL' ? null : _activeFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: next,
        limit: _pageLimit,
      );
      if (mounted) {
        setState(() {
          _boxes.addAll(results);
          _page = next;
          _hasMore = results.length == _pageLimit;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onFilterChanged(String filter) async {
    setState(() => _activeFilter = filter);
    await _fetchBoxes();
  }

  Future<void> _onSearch(String query) async {
    setState(() => _searchQuery = query);
    // If it looks like a QR code, use single-item QR lookup for speed
    if (query.toUpperCase().startsWith('BOX-')) {
      setState(() {
        _isLoading = true;
        _hasMore = false;
      });
      try {
        final box = await _boxRepo.getByQr(query.toUpperCase());
        if (mounted) {
          setState(() {
            _boxes = box != null ? [box] : [];
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }
    await _fetchBoxes();
  }

  // Scan a box QR and drop it into the search (reuses the QR-lookup path).
  void _openScanSearch() {
    bool handled = false;
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.5,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  AppLocalizations.of(context).boxesScanToSearch,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: c.primaryDark),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MobileScanner(
                      onDetect: (capture) {
                        if (handled) return;
                        final barcode = capture.barcodes.firstOrNull;
                        final code = barcode?.rawValue?.trim();
                        if (code != null && code.isNotEmpty) {
                          handled = true;
                          Navigator.pop(ctx);
                          _searchController.text = code;
                          _onSearch(code);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      body: FingerprintBackground(
        child: RefreshIndicator(
          onRefresh: _fetchBoxes,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
            // Premium Large Header
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: c.appBar,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                title: Text(
                  l.boxesTitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: c.primaryDark,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  tooltip: _isGridView ? l.boxesListView : l.boxesGridView,
                  icon: Icon(
                    _isGridView
                        ? Icons.view_agenda_outlined
                        : Icons.grid_view_rounded,
                    color: c.primary,
                  ),
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                ),
                IconButton(
                  tooltip: l.boxesScanToSearch,
                  icon: Icon(Icons.qr_code_scanner_rounded,
                      color: c.primary),
                  onPressed: _openScanSearch,
                ),
                const SizedBox(width: 4),
              ],
            ),

            // Search Bar & Filter chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  children: [
                    // Search box
                    Container(
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border),
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
                          hintText: l.boxesSearchHint,
                          prefixIcon: Icon(Icons.search_rounded, color: c.textBody, size: 20),
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
                    const SizedBox(height: 16),

                    // Filter chips row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', l.boxesFilterAll),
                          const SizedBox(width: 8),
                          _buildFilterChip('ACTIVE', l.boxesFilterActive),
                          const SizedBox(width: 8),
                          _buildFilterChip('FULL', l.boxStatusFull),
                          const SizedBox(width: 8),
                          _buildFilterChip('INACTIVE', l.boxStatusInactive),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Boxes List Grid
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 48, color: c.textBody),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center,
                            style: TextStyle(color: c.textBody)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchBoxes,
                          icon: const Icon(Icons.refresh),
                          label: Text(l.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_boxes.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_rounded, size: 64,
                          color: c.primary.withOpacity(0.15)),
                      const SizedBox(height: 16),
                      Text(l.boxesNoneFound,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                              color: c.primaryDark)),
                      const SizedBox(height: 4),
                      Text(l.boxesNoneHint,
                          style: TextStyle(fontSize: 12, color: c.textBody)),
                    ],
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                sliver: _isGridView
                    ? SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 184,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, idx) => _buildBoxGridCard(_boxes[idx]),
                          childCount: _boxes.length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, idx) {
                            final box = _boxes[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: _buildBoxCard(box),
                            );
                          },
                          childCount: _boxes.length,
                        ),
                      ),
              ),
              // Infinite-scroll footer: spinner while loading more, total at the end.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  child: Center(
                    child: _isLoadingMore
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : (!_hasMore
                            ? Text(
                                '${_boxes.length} ${_boxes.length == 1 ? l.roomBoxSingular : l.roomBoxPlural}',
                                style: TextStyle(
                                    fontSize: 11, color: c.textBody),
                              )
                            : const SizedBox.shrink()),
                  ),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isActive = _activeFilter == filter;
    final c = context.colors;
    return GestureDetector(
      onTap: () => _onFilterChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? c.primary : c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? c.primary : c.border,
            width: 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: c.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? c.onPrimary : c.textBody,
          ),
        ),
      ),
    );
  }

  // Map a raw backend box status onto its localised label.
  String _statusLabel(AppLocalizations l, String status) {
    switch (status.toUpperCase()) {
      case 'FULL':
        return l.boxStatusFull;
      case 'INACTIVE':
        return l.boxStatusInactive;
      case 'ACTIVE':
        return l.boxStatusActive;
      default:
        return status;
    }
  }

  Widget _buildBoxCard(models.Box box) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    Color statusColor;
    switch (box.status.toUpperCase()) {
      case 'FULL':
        statusColor = c.danger;
        break;
      case 'INACTIVE':
        statusColor = c.textSecondary;
        break;
      case 'ACTIVE':
      default:
        statusColor = c.success;
        break;
    }

    final double utilizationPercent = box.capacity > 0 ? (box.occupiedCount / box.capacity) : 0;

    // Color of occupancy bar based on how full it is
    Color utilizationColor = c.success;
    if (utilizationPercent > 0.85) {
      utilizationColor = c.danger;
    } else if (utilizationPercent > 0.5) {
      utilizationColor = c.warning;
    }

    return GlassCard(
      padding: const EdgeInsets.all(14.0),
      borderRadius: 16,
      backgroundColor: c.card,
      borderColor: c.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Label + QR code | Status chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      box.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: c.primaryDark,
                      ),
                    ),
                    Text(
                      box.qrCode,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: c.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _statusLabel(l, box.status),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Location + occupancy count on one line (no separate label row)
          Row(
            children: [
              Icon(Icons.place_rounded, size: 13, color: c.textBody),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  box.location ?? l.boxesUnallocatedSlot,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: c.textBody,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${box.occupiedCount}/${box.capacity}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: c.primaryDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: utilizationPercent,
              minHeight: 6,
              backgroundColor: c.border,
              valueColor: AlwaysStoppedAnimation<Color>(utilizationColor),
            ),
          ),

          const SizedBox(height: 8),

          // Action button row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  _showBoxDetailSheet(context, box);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary.withValues(alpha: 0.08),
                  foregroundColor: c.primary,
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l.boxesViewPassports,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Compact card for the grid view (2 columns).
  Widget _buildBoxGridCard(models.Box box) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    Color statusColor;
    switch (box.status.toUpperCase()) {
      case 'FULL':
        statusColor = c.danger;
        break;
      case 'INACTIVE':
        statusColor = c.textSecondary;
        break;
      case 'ACTIVE':
      default:
        statusColor = c.success;
        break;
    }
    final double utilizationPercent =
        box.capacity > 0 ? (box.occupiedCount / box.capacity) : 0;
    Color utilizationColor = c.success;
    if (utilizationPercent > 0.85) {
      utilizationColor = c.danger;
    } else if (utilizationPercent > 0.5) {
      utilizationColor = c.warning;
    }

    return GlassCard(
      padding: const EdgeInsets.all(12.0),
      borderRadius: 16,
      backgroundColor: c.card,
      borderColor: c.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  box.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            box.qrCode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: c.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.place_rounded, size: 12, color: c.textBody),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  box.location ?? l.boxesUnallocated,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 10, color: c.textBody),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _statusLabel(l, box.status),
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor),
              ),
              Text(
                '${box.occupiedCount}/${box.capacity}',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: c.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: utilizationPercent,
              minHeight: 6,
              backgroundColor: c.border,
              valueColor: AlwaysStoppedAnimation<Color>(utilizationColor),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showBoxDetailSheet(context, box),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary.withValues(alpha: 0.08),
                foregroundColor: c.primary,
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                shadowColor: Colors.transparent,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l.boxesViewPassports,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showBoxDetailSheet(BuildContext context, models.Box box) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    box.label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    '${box.occupiedCount}/${box.capacity} ${l.boxesSlots}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: c.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${l.boxesLocationLabel}: ${box.location ?? l.boxesDefaultLocation}',
                style: TextStyle(color: c.textBody, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                l.boxesPassportsInside,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: c.textBody, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              // The list endpoint (/boxes) omits the passports array — fetch the
              // full box (with its passports) on demand when the sheet opens.
              // Expanded so the list fills the remaining sheet height and
              // scrolls (rather than overflowing a fixed-height box).
              Expanded(
                child: FutureBuilder<models.Box?>(
                  future: _boxRepo.getByQr(box.qrCode),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final passports =
                        snapshot.data?.passports ?? <models.PassportSummary>[];
                    if (passports.isEmpty) {
                      return Center(
                        child: Text(
                          l.boxesNoPassports,
                          style: TextStyle(color: c.textBody, fontSize: 13),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: passports.length,
                      itemBuilder: (context, idx) {
                        final p = passports[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: c.primary.withValues(alpha: 0.08),
                            child: Icon(Icons.person, color: c.primary, size: 16),
                          ),
                          title: Text(p.holderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('${l.boxesIdNo}: ${p.holderIdNo} • QR: ${p.qrCode}', style: const TextStyle(fontSize: 11)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/box_repository.dart';
import '../../../data/models/box.dart' as models;
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

  String _searchQuery = '';
  String _activeFilter = 'ALL'; // 'ALL', 'ACTIVE', 'FULL', 'INACTIVE'
  bool _isLoading = false;
  String? _errorMessage;

  List<models.Box> _boxes = [];

  @override
  void initState() {
    super.initState();
    _fetchBoxes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBoxes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await _boxRepo.getAll(
        status: _activeFilter == 'ALL' ? null : _activeFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (mounted) {
        setState(() {
          _boxes = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load boxes. Check your connection.';
        });
      }
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
      setState(() => _isLoading = true);
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FingerprintBackground(
        child: RefreshIndicator(
          onRefresh: _fetchBoxes,
          child: CustomScrollView(
            slivers: [
            // Premium Large Header
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                title: Text(
                  'Box Inventory',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                  onPressed: () {
                    context.push('/scan?mode=move_box');
                  },
                ),
                const SizedBox(width: 8),
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
                          hintText: 'Enter Box QR Code (e.g. BOX-0001)...',
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
                    const SizedBox(height: 16),

                    // Filter chips row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', 'All Boxes'),
                          const SizedBox(width: 8),
                          _buildFilterChip('ACTIVE', 'Active (Space available)'),
                          const SizedBox(width: 8),
                          _buildFilterChip('FULL', 'Full'),
                          const SizedBox(width: 8),
                          _buildFilterChip('INACTIVE', 'Inactive'),
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
                        const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textBody),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textBody)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchBoxes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
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
                          color: AppColors.primary.withOpacity(0.15)),
                      const SizedBox(height: 16),
                      const Text('No Boxes Found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark)),
                      const SizedBox(height: 4),
                      const Text('Try a different filter or search term',
                          style: TextStyle(fontSize: 12, color: AppColors.textBody)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      final box = _boxes[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildBoxCard(box),
                      );
                    },
                    childCount: _boxes.length,
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => _onFilterChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
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
            color: isActive ? Colors.white : AppColors.textBody,
          ),
        ),
      ),
    );
  }

  Widget _buildBoxCard(models.Box box) {
    Color statusColor;
    switch (box.status.toUpperCase()) {
      case 'FULL':
        statusColor = AppColors.danger;
        break;
      case 'INACTIVE':
        statusColor = AppColors.textSecondary;
        break;
      case 'ACTIVE':
      default:
        statusColor = AppColors.success;
        break;
    }

    final double utilizationPercent = box.capacity > 0 ? (box.occupiedCount / box.capacity) : 0;
    
    // Color of occupancy bar based on how full it is
    Color utilizationColor = AppColors.success;
    if (utilizationPercent > 0.85) {
      utilizationColor = AppColors.danger;
    } else if (utilizationPercent > 0.5) {
      utilizationColor = AppColors.warning;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16.0),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Label, QR code and Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    box.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    box.qrCode,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Text(
                  box.status,
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
          
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Location details
          Row(
            children: [
              const Icon(Icons.place_rounded, size: 14, color: AppColors.textBody),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  box.location ?? 'HQ Storage / Unallocated Slot',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBody,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14),

          // Occupancy bar & Capacity Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Occupancy Rate',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBody.withOpacity(0.8),
                ),
              ),
              Text(
                '${box.occupiedCount} / ${box.capacity} Passports',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: utilizationPercent,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(utilizationColor),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Action button row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  context.push('/scan?mode=move_box');
                },
                icon: const Icon(Icons.drive_file_move_outlined, size: 14),
                label: const Text('Move Box', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  _showBoxDetailSheet(context, box);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: const Text('View Passports', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBoxDetailSheet(BuildContext context, models.Box box) {
    showModalBottomSheet(
      context: context,
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
                    '${box.occupiedCount}/${box.capacity} slots',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Location: ${box.location ?? "HQ Storage"}',
                style: const TextStyle(color: AppColors.textBody, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'PASSPORTS INSIDE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textBody, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: box.passports == null || box.passports!.isEmpty
                    ? const Center(
                        child: Text(
                          'No passports are currently assigned to this box.',
                          style: TextStyle(color: AppColors.textBody, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        itemCount: box.passports!.length,
                        itemBuilder: (context, idx) {
                          final p = box.passports![idx];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.08),
                              child: const Icon(Icons.person, color: AppColors.primary, size: 16),
                            ),
                            title: Text(p.holderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('ID No: ${p.holderIdNo} • QR: ${p.qrCode}', style: const TextStyle(fontSize: 11)),
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

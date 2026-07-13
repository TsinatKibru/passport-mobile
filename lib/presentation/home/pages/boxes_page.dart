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
  
  // List of active/cached boxes on shift
  final List<models.Box> _localBoxes = [
    models.Box(
      id: 'box1',
      qrCode: 'BOX-0001',
      label: 'Box 001',
      capacity: 10,
      occupiedCount: 7,
      status: 'ACTIVE',
      location: 'HQ Building / Room A / Shelf 01 / Row B / Slot 3',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    models.Box(
      id: 'box2',
      qrCode: 'BOX-0002',
      label: 'Box 002',
      capacity: 10,
      occupiedCount: 10,
      status: 'FULL',
      location: 'HQ Building / Room A / Shelf 02 / Row A / Slot 1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    models.Box(
      id: 'box3',
      qrCode: 'BOX-0003',
      label: 'Box 003',
      capacity: 15,
      occupiedCount: 3,
      status: 'ACTIVE',
      location: 'HQ Building / Room B / Shelf 01 / Row C / Slot 5',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    models.Box(
      id: 'box4',
      qrCode: 'BOX-0004',
      label: 'Box 004',
      capacity: 10,
      occupiedCount: 0,
      status: 'INACTIVE',
      location: 'HQ Building / Storage / Unassigned',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  List<models.Box> _searchResult = [];

  @override
  void initState() {
    super.initState();
    _searchResult = List.from(_localBoxes);
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResult = List.from(_localBoxes);
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // If it looks like a QR code or full label, query the API
      if (query.toUpperCase().startsWith('BOX-')) {
        final box = await _boxRepo.getByQr(query.toUpperCase());
        if (mounted) {
          setState(() {
            if (box != null) {
              _searchResult = [box];
            } else {
              _searchResult = [];
            }
            _isLoading = false;
          });
        }
        return;
      }
      
      // Local fallback filter
      final filtered = _localBoxes.where((b) {
        final label = b.label.toLowerCase();
        final qr = b.qrCode.toLowerCase();
        final loc = (b.location ?? '').toLowerCase();
        final q = query.toLowerCase();
        return label.contains(q) || qr.contains(q) || loc.contains(q);
      }).toList();

      setState(() {
        _searchResult = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<models.Box> _getFilteredBoxes() {
    if (_activeFilter == 'ALL') return _searchResult;
    return _searchResult.where((b) => b.status == _activeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayBoxes = _getFilteredBoxes();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FingerprintBackground(
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
                        onSubmitted: _performSearch,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Enter Box QR Code (e.g. BOX-0001)...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textBody, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch('');
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
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (displayBoxes.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 64,
                        color: AppColors.primary.withOpacity(0.15),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Boxes Found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Try searching for BOX-0001 or BOX-0002',
                        style: TextStyle(fontSize: 12, color: AppColors.textBody),
                      ),
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
                      final box = displayBoxes[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildBoxCard(box),
                      );
                    },
                    childCount: displayBoxes.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filter;
        });
      },
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

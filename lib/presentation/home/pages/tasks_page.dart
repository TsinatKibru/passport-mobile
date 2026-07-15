import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/fingerprint_background.dart';
import '../widgets/glass_card.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../data/repositories/box_repository.dart';
import '../../../data/models/room.dart' as room_models;
import '../../../data/models/box.dart' as box_models;
import '../../../l10n/app_localizations.dart';

// Localised labels for backend status enums (no BuildContext on the models).
String _boxStatusLabel(AppLocalizations l, String status) => switch (status.toUpperCase()) {
  'FULL'     => l.boxStatusFull,
  'INACTIVE' => l.boxStatusInactive,
  'ACTIVE'   => l.boxStatusActive,
  _          => status,
};

String _passportStatusLabel(AppLocalizations l, String status) => switch (status.toUpperCase()) {
  'ISSUED'   => l.psIssued,
  'IN_BOX'   => l.psInBox,
  'RETURNED' => l.psReturned,
  _          => status,
};

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final LocationRepository _locationRepo = LocationRepository();
  final BoxRepository _boxRepo = BoxRepository();

  bool _isLoading = false;
  List<room_models.Room> _rooms = [];
  List<room_models.Shelf> _shelves = [];
  List<room_models.VaultRow> _rows = [];
  List<room_models.VaultSlot> _slots = [];

  String _currentLevel = 'rooms';
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
    final list = await _locationRepo.getRooms();
    setState(() {
      _rooms = list;
      _currentLevel = 'rooms';
      _selectedRoom = null;
      _selectedShelf = null;
      _selectedRow = null;
      _isLoading = false;
    });
  }

  Future<void> _loadShelves(room_models.Room room) async {
    setState(() => _isLoading = true);
    final list = await _locationRepo.getShelves(room.id);
    setState(() {
      _shelves = list;
      _selectedRoom = room;
      _currentLevel = 'shelves';
      _selectedShelf = null;
      _selectedRow = null;
      _isLoading = false;
    });
  }

  Future<void> _loadRows(room_models.Shelf shelf) async {
    setState(() => _isLoading = true);
    final list = await _locationRepo.getRows(shelf.id);
    setState(() {
      _rows = list;
      _selectedShelf = shelf;
      _currentLevel = 'rows';
      _selectedRow = null;
      _isLoading = false;
    });
  }

  Future<void> _loadSlots(room_models.VaultRow row) async {
    setState(() => _isLoading = true);
    final list = await _locationRepo.getSlots(row.id);
    setState(() {
      _slots = list;
      _selectedRow = row;
      _currentLevel = 'slots';
      _isLoading = false;
    });
  }

  void _navigateBack() {
    if (_currentLevel == 'slots') {
      _loadRows(_selectedShelf!);
    } else if (_currentLevel == 'rows') {
      _loadShelves(_selectedRoom!);
    } else if (_currentLevel == 'shelves') {
      _loadRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      body: FingerprintBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildBreadcrumbs(),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(c.primary)))
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0), end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _buildCurrentView(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.vaultTitle,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 24,
                      fontWeight: FontWeight.w800, color: c.primaryDark)),
              const SizedBox(height: 4),
              Text(l.vaultSubtitle,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                      color: c.textBody.withOpacity(0.7))),
            ],
          ),
          if (_currentLevel != 'rooms')
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.primary),
              onPressed: _navigateBack,
            ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    final c = context.colors;
    final crumbs = <Widget>[
      GestureDetector(
        onTap: _loadRooms,
        child: Text(AppLocalizations.of(context).vaultRooms,
            style: TextStyle(color: c.primary, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    ];

    if (_selectedRoom != null) {
      crumbs.add(Icon(Icons.chevron_right, size: 14, color: c.textBody));
      crumbs.add(GestureDetector(
        onTap: () => _loadShelves(_selectedRoom!),
        child: Text(_selectedRoom!.name,
            style: TextStyle(
              color: _currentLevel == 'shelves' ? c.textBody : c.primary,
              fontWeight: FontWeight.bold, fontSize: 13)),
      ));
    }
    if (_selectedShelf != null) {
      crumbs.add(Icon(Icons.chevron_right, size: 14, color: c.textBody));
      crumbs.add(GestureDetector(
        onTap: () => _loadRows(_selectedShelf!),
        child: Text(_selectedShelf!.name,
            style: TextStyle(
              color: _currentLevel == 'rows' ? c.textBody : c.primary,
              fontWeight: FontWeight.bold, fontSize: 13)),
      ));
    }
    if (_selectedRow != null) {
      crumbs.add(Icon(Icons.chevron_right, size: 14, color: c.textBody));
      crumbs.add(Text(_selectedRow!.name,
          style: TextStyle(color: c.textBody, fontWeight: FontWeight.bold, fontSize: 13)));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: crumbs),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentLevel) {
      case 'rooms': return _buildRoomsGrid();
      case 'shelves': return _buildShelvesList();
      case 'rows': return _buildRowsList();
      case 'slots': return _buildSlotsGrid();
      default: return const SizedBox();
    }
  }

  Widget _buildRoomsGrid() {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (_rooms.isEmpty) return _emptyState(l.vaultNoRooms);
    return GridView.builder(
      key: const ValueKey('rooms'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1),
      itemCount: _rooms.length,
      itemBuilder: (_, i) {
        final room = _rooms[i];
        return GestureDetector(
          onTap: () => _loadShelves(room),
          child: GlassCard(
            backgroundColor: c.card,
            borderColor: c.border,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.meeting_room_rounded, color: c.primary, size: 24),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(room.name, style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: c.primaryDark)),
                  const SizedBox(height: 4),
                  Text(l.vaultShelvesCount(room.shelfCount ?? 0),
                      style: TextStyle(fontSize: 12, color: c.textBody.withOpacity(0.6))),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShelvesList() {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (_shelves.isEmpty) return _emptyState(l.vaultNoShelves);
    return ListView.builder(
      key: const ValueKey('shelves'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _shelves.length,
      itemBuilder: (_, i) {
        final shelf = _shelves[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _loadRows(shelf),
            child: GlassCard(
              backgroundColor: c.card,
              borderColor: c.border,
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                _iconBox(Icons.dns_rounded, c.success),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(shelf.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: c.primaryDark)),
                  Text(l.vaultPosition(shelf.position), style: TextStyle(fontSize: 12, color: c.textBody.withOpacity(0.5))),
                ])),
                _badge(l.vaultRowsCount(shelf.rowCount ?? 0)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: c.textBody, size: 20),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRowsList() {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (_rows.isEmpty) return _emptyState(l.vaultNoRows);
    return ListView.builder(
      key: const ValueKey('rows'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _rows.length,
      itemBuilder: (_, i) {
        final row = _rows[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _loadSlots(row),
            child: GlassCard(
              backgroundColor: c.card,
              borderColor: c.border,
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                _iconBox(Icons.view_headline_rounded, c.primaryDark),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(row.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: c.primaryDark)),
                  Text(l.vaultPosition(row.position), style: TextStyle(fontSize: 12, color: c.textBody.withOpacity(0.5))),
                ])),
                _badge(l.vaultSlotsCount(row.slotCount ?? 0)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: c.textBody, size: 20),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotsGrid() {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    if (_slots.isEmpty) return _emptyState(l.vaultNoSlots);
    return GridView.builder(
      key: const ValueKey('slots'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.88),
      itemCount: _slots.length,
      itemBuilder: (_, i) {
        final slot = _slots[i];
        final box = slot.boxes != null && slot.boxes!.isNotEmpty ? slot.boxes!.first : null;
        return GestureDetector(
          onTap: box != null ? () => _showBoxDetailsSheet(box.qrCode) : null,
          child: Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: box != null ? c.primary.withOpacity(0.2) : c.border, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(slot.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: c.textBody)),
                Icon(box != null ? Icons.inventory_2_rounded : Icons.crop_free_rounded,
                    color: box != null ? c.primary : c.textBody.withOpacity(0.3), size: 16),
              ]),
              const Spacer(),
              if (box != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (box.status == 'FULL' ? c.danger : c.success).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_boxStatusLabel(l, box.status),
                      style: TextStyle(color: box.status == 'FULL' ? c.danger : c.success,
                          fontWeight: FontWeight.bold, fontSize: 9)),
                ),
                const SizedBox(height: 8),
                Text(box.label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: c.primaryDark)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: box.capacity > 0 ? box.occupiedCount / box.capacity : 0,
                    backgroundColor: c.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        box.occupiedCount >= box.capacity ? c.danger : c.primary),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(l.vaultOccupied, style: TextStyle(fontSize: 10, color: c.textBody.withOpacity(0.5))),
                  Text('${box.occupiedCount}/${box.capacity}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.primaryDark)),
                ]),
              ] else
                Center(child: Text(l.vaultEmptySlot,
                    style: TextStyle(fontSize: 11, color: c.textBody, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
            ]),
          ),
        );
      },
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _badge(String label) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: c.primary, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _emptyState(String msg) {
    final c = context.colors;
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inventory_2_outlined, size: 64, color: c.textBody.withOpacity(0.15)),
      const SizedBox(height: 16),
      Text(msg, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.primaryDark)),
    ]));
  }

  void _showBoxDetailsSheet(String boxQr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BoxDetailsSheet(boxQrCode: boxQr, boxRepo: _boxRepo),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Box Details Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _BoxDetailsSheet extends StatefulWidget {
  final String boxQrCode;
  final BoxRepository boxRepo;
  const _BoxDetailsSheet({required this.boxQrCode, required this.boxRepo});

  @override
  State<_BoxDetailsSheet> createState() => _BoxDetailsSheetState();
}

class _BoxDetailsSheetState extends State<_BoxDetailsSheet> {
  bool _loading = true;
  box_models.Box? _box;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final b = await widget.boxRepo.getByQr(widget.boxQrCode);
      setState(() { _box = b; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 48, height: 5,
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 16),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: TextStyle(color: c.danger)))
                : _buildContent()),
      ]),
    );
  }

  Widget _buildContent() {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final box = _box!;
    final passports = box.passports ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(box.label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c.primaryDark)),
            Text(l.vaultQrLabel(box.qrCode), style: TextStyle(fontSize: 12, color: c.textBody)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: c.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('${box.occupiedCount}/${box.capacity}',
                style: TextStyle(color: c.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border)),
          child: Row(children: [
            Icon(Icons.location_on_rounded, color: c.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(box.location ?? l.returnUnassignedLocation,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: c.primaryDark))),
          ]),
        ),
        const SizedBox(height: 24),
        Text(l.vaultContainedPassports,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.primaryDark)),
        const SizedBox(height: 12),
        Expanded(
          child: passports.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.assignment_turned_in_rounded, size: 48, color: c.textBody.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text(l.vaultNoPassportsInside, style: TextStyle(fontWeight: FontWeight.bold, color: c.textBody)),
                ]))
              : ListView.builder(
                  itemCount: passports.length,
                  itemBuilder: (_, i) {
                    final p = passports[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.border)),
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: c.primary.withOpacity(0.08), shape: BoxShape.circle),
                            child: Icon(Icons.badge_rounded, color: c.primary, size: 20)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.holderName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: c.primaryDark)),
                          Text(l.issueIdLabel(p.holderIdNo),
                              style: TextStyle(fontSize: 11, color: c.textBody.withOpacity(0.6))),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: c.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(_passportStatusLabel(l, p.status),
                              style: TextStyle(color: c.success, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

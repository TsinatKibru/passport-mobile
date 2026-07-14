// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:mobile_scanner/mobile_scanner.dart';
// // import 'package:dio/dio.dart';
// // import '../../../core/theme/app_theme.dart';
// // import '../../../data/repositories/passport_repository.dart';
// // import '../../../data/repositories/box_repository.dart';
// // import '../../../data/repositories/location_repository.dart';
// // import '../../../data/models/passport.dart';
// // import '../../../data/models/box.dart' as models;
// // import '../../../data/models/room.dart';
// // import '../widgets/glass_card.dart';
// // import '../widgets/fingerprint_background.dart';

// // class PassportReturnPage extends StatefulWidget {
// //   const PassportReturnPage({super.key});

// //   @override
// //   State<PassportReturnPage> createState() => _PassportReturnPageState();
// // }

// // class _PassportReturnPageState extends State<PassportReturnPage> {
// //   final PassportRepository _passportRepo = PassportRepository();
// //   final BoxRepository _boxRepo = BoxRepository();
// //   final LocationRepository _locationRepo = LocationRepository();

// //   // Step state
// //   int _currentStep = 1; // 1: Scan Passports, 2: Select Box, 3: Verify & Confirm

// //   // Scanned Passports Stack
// //   final List<Passport> _scannedPassports = [];

// //   // Storage Box State
// //   List<models.Box> _availableBoxes = [];
// //   models.Box? _selectedBox;
// //   bool _isLoadingBoxes = false;
// //   final TextEditingController _boxSearchController = TextEditingController();
  
// //   // Pagination State
// //   int _currentPage = 1;
// //   int _totalPages = 1;
// //   int _totalBoxes = 0;
// //   bool _hasMoreBoxes = false;
// //   String _searchQuery = '';
// //   String? _selectedRoomId;
// //   List<Room> _rooms = [];
// //   bool _isLoadingRooms = false;

// //   // Verification state
// //   bool _isSubmitting = false;
// //   String? _scannedSlotQr;
// //   String? _scannedBoxQr;

// //   // Track currently processing QR codes to prevent spam/duplicate API calls
// //   final Set<String> _processingQrs = {};

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadRooms();
// //   }

// //   Future<void> _loadRooms() async {
// //     setState(() => _isLoadingRooms = true);
// //     final rooms = await _locationRepo.getRooms();
// //     if (mounted) {
// //       setState(() {
// //         _rooms = rooms;
// //         _isLoadingRooms = false;
// //       });
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     _boxSearchController.dispose();
// //     super.dispose();
// //   }

// //   void _addPassportByQr(String code) async {
// //     // If already in the stack, ignore silently (prevents screen flooding with errors)
// //     if (_scannedPassports.any((p) => p.qrCode == code)) {
// //       return;
// //     }

// //     // Prevent duplicate parallel api requests
// //     if (_processingQrs.contains(code)) {
// //       return;
// //     }

// //     _processingQrs.add(code);

// //     try {
// //       final passport = await _passportRepo.getByQr(code);
// //       if (passport == null) {
// //         _showFeedback('Passport not found in system: $code', true);
// //         return;
// //       }

// //       if (!passport.isIssued) {
// //         _showFeedback(
// //           '${passport.holderName} is ${passport.status} — only ISSUED passports can be returned',
// //           true,
// //         );
// //         return;
// //       }

// //       setState(() {
// //         _scannedPassports.add(passport);
// //       });
// //       _showFeedback('Added: ${passport.holderName}', false);
// //     } catch (e) {
// //       _showFeedback('Error looking up passport: $e', true);
// //     } finally {
// //       // Keep in processing set for 2 seconds to let the user move the camera away
// //       Future.delayed(const Duration(seconds: 2), () {
// //         if (mounted) {
// //           _processingQrs.remove(code);
// //         }
// //       });
// //     }
// //   }

// //   void _loadAvailableBoxes({bool resetPage = true}) async {
// //     if (resetPage) {
// //       setState(() {
// //         _currentPage = 1;
// //         _availableBoxes.clear();
// //       });
// //     }
    
// //     setState(() {
// //       _isLoadingBoxes = true;
// //       _currentStep = 2;
// //     });

// //     try {
// //       final response = await _boxRepo.getAvailablePaginated(
// //         _scannedPassports.length,
// //         page: _currentPage,
// //         limit: 20,
// //         search: _searchQuery.isNotEmpty ? _searchQuery : null,
// //         roomId: _selectedRoomId,
// //       );
      
// //       setState(() {
// //         if (resetPage) {
// //           _availableBoxes = response.data;
// //         } else {
// //           _availableBoxes.addAll(response.data);
// //         }
// //         _totalPages = response.totalPages;
// //         _totalBoxes = response.total;
// //         _hasMoreBoxes = response.hasMore;
// //         _isLoadingBoxes = false;
// //       });
// //     } catch (e) {
// //       setState(() => _isLoadingBoxes = false);
// //       _showFeedback('Failed to load matching boxes', true);
// //     }
// //   }
  
// //   void _loadNextPage() async {
// //     if (_hasMoreBoxes && !_isLoadingBoxes) {
// //       setState(() => _currentPage++);
// //       _loadAvailableBoxes(resetPage: false);
// //     }
// //   }
  
// //   void _onSearchChanged(String query) {
// //     setState(() => _searchQuery = query);
// //     // Debounce search by 500ms
// //     Future.delayed(const Duration(milliseconds: 500), () {
// //       if (_searchQuery == query) {
// //         _loadAvailableBoxes(resetPage: true);
// //       }
// //     });
// //   }

// //   void _lookupBoxManually(String qrCode) async {
// //     setState(() => _isLoadingBoxes = true);
// //     try {
// //       final box = await _boxRepo.getByQr(qrCode);
// //       setState(() {
// //         _isLoadingBoxes = false;
// //         if (box != null) {
// //           _selectedBox = box;
// //           _currentStep = 3;
// //         } else {
// //           _showFeedback('Box not found: $qrCode', true);
// //         }
// //       });
// //     } catch (e) {
// //       setState(() => _isLoadingBoxes = false);
// //       _showFeedback('Box lookup failed', true);
// //     }
// //   }

// //   Future<void> _executeBatchReturn({
// //     required models.Box box,
// //     bool overrideLocation = false,
// //     void Function(models.Box box)? onSuccess,
// //   }) async {
// //     setState(() => _isSubmitting = true);

// //     try {
// //       final passportIds = _scannedPassports.map((p) => p.id).toList();
// //       await _passportRepo.batchAssign(
// //         passportIds: passportIds,
// //         boxId: box.id,
// //         slotQrCode: _scannedSlotQr,
// //         overrideLocation: overrideLocation,
// //         action: 'PASSPORT_RETURNED',
// //       );

// //       if (!mounted) return;
// //       setState(() => _isSubmitting = false);

// //       if (onSuccess != null) {
// //         onSuccess(box);
// //       } else {
// //         _showSuccessDialog();
// //       }
// //     } on DioException catch (dioErr) {
// //       if (!mounted) return;
// //       setState(() => _isSubmitting = false);
// //       _handleBatchAssignError(
// //         dioErr,
// //         box: box,
// //         onOverride: () => _executeBatchReturn(
// //           box: box,
// //           overrideLocation: true,
// //           onSuccess: onSuccess,
// //         ),
// //       );
// //     } catch (e) {
// //       if (!mounted) return;
// //       setState(() => _isSubmitting = false);
// //       _showFeedback('Return transaction failed: $e', true);
// //     }
// //   }

// //   void _handleBatchAssignError(
// //     DioException dioErr, {
// //     required models.Box box,
// //     required VoidCallback onOverride,
// //   }) {
// //     final responseData = dioErr.response?.data;
// //     if (responseData is Map && responseData['error'] == 'LOCATION_MISMATCH') {
// //       setState(() => _selectedBox = box);
// //       _handleLocationMismatch(
// //         currentLocation: responseData['currentLocation'] ?? 'Unknown',
// //         scannedLocation: responseData['scannedLocation'] ?? 'Unknown',
// //         onOverride: onOverride,
// //       );
// //       return;
// //     }

// //     final message = responseData is Map
// //         ? (responseData['message'] as String? ?? 'Network submission error')
// //         : 'Network submission error';
// //     _showFeedback(message, true);
// //   }

// //   void _submitReturnWithVerification() async {
// //     if (_selectedBox == null || _scannedBoxQr == null || _scannedSlotQr == null) return;

// //     setState(() {
// //       _isSubmitting = true;
// //     });

// //     // Check if scanned box matches selected box
// //     if (_scannedBoxQr != _selectedBox!.qrCode) {
// //       setState(() => _isSubmitting = false);
// //       _handleBoxMismatch();
// //       return;
// //     }

// //     await _executeBatchReturn(box: _selectedBox!);
// //   }

// //   void _handleBoxMismatch() {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (ctx) => AlertDialog(
// //         title: Row(
// //           children: const [
// //             Icon(Icons.warning_amber_rounded, color: AppColors.warning),
// //             SizedBox(width: 8),
// //             Text('Box Mismatch', style: TextStyle(fontWeight: FontWeight.bold)),
// //           ],
// //         ),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text('You selected: ${_selectedBox!.label}', 
// //                  style: const TextStyle(fontWeight: FontWeight.bold)),
// //             Text('Expected QR: ${_selectedBox!.qrCode}', 
// //                  style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
// //             const SizedBox(height: 12),
// //             Text('But scanned: $_scannedBoxQr', 
// //                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
// //             const SizedBox(height: 16),
// //             const Text('You have found a different box than selected. Please:',
// //                        style: TextStyle(fontSize: 14)),
// //           ],
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () {
// //               Navigator.pop(ctx);
// //               setState(() {
// //                 _scannedBoxQr = null;
// //                 _scannedSlotQr = null;
// //               });
// //             },
// //             child: const Text('Scan Again', style: TextStyle(color: AppColors.textBody)),
// //           ),
// //           ElevatedButton(
// //             onPressed: () {
// //               Navigator.pop(ctx);
// //               _usePhysicalBox();
// //             },
// //             style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
// //             child: const Text('Use This Box'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _usePhysicalBox() async {
// //     // Find the box by scanned QR
// //     setState(() => _isSubmitting = true);
    
// //     try {
// //       final physicalBox = await _boxRepo.getByQr(_scannedBoxQr!);
      
// //       if (physicalBox == null) {
// //         setState(() => _isSubmitting = false);
// //         _showFeedback('Scanned box not found in system: $_scannedBoxQr', true);
// //         return;
// //       }

// //       // Check capacity
// //       final needed = _scannedPassports.length;
// //       final available = physicalBox.capacity - physicalBox.occupiedCount;
      
// //       if (available < needed) {
// //         setState(() => _isSubmitting = false);
// //         _showFeedback(
// //           'Box ${physicalBox.label} only has $available vacant slots, but you need $needed',
// //           true,
// //         );
// //         return;
// //       }

// //       // Use the physical box for assignment
// //       setState(() => _selectedBox = physicalBox);
// //       await _executeBatchReturn(
// //         box: physicalBox,
// //         onSuccess: (box) => _showSuccessDialogWithBox(box),
// //       );
// //     } catch (e) {
// //       if (!mounted) return;
// //       setState(() => _isSubmitting = false);
// //       _showFeedback('Failed to use physical box: $e', true);
// //     }
// //   }

// //   void _handleLocationMismatch({
// //     required String currentLocation,
// //     required String scannedLocation,
// //     required VoidCallback onOverride,
// //   }) {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (ctx) => AlertDialog(
// //         title: Row(
// //           children: const [
// //             Icon(Icons.warning_amber_rounded, color: AppColors.warning),
// //             SizedBox(width: 8),
// //             Text('Location Mismatch', style: TextStyle(fontWeight: FontWeight.bold)),
// //           ],
// //         ),
// //         content: Text(
// //           'Box ${_selectedBox!.label} is registered at:\n"$currentLocation"\n\nBut physically found at:\n"$scannedLocation"\n\nWould you like to correct the box\'s storage address and assign these passports?',
// //           style: const TextStyle(fontSize: 14, height: 1.4),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(ctx),
// //             child: const Text('Cancel', style: TextStyle(color: AppColors.textBody)),
// //           ),
// //           ElevatedButton(
// //             onPressed: () {
// //               Navigator.pop(ctx);
// //               onOverride();
// //             },
// //             style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
// //             child: const Text('Update & Assign'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _showSuccessDialog() {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (ctx) => AlertDialog(
// //         icon: const Icon(Icons.check_circle_rounded, size: 54, color: AppColors.success),
// //         title: const Text('Return Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
// //         content: Text(
// //           'Successfully returned ${_scannedPassports.length} passports to Box ${_selectedBox!.label}. All custody locations updated.',
// //           textAlign: TextAlign.center,
// //         ),
// //         actions: [
// //           ElevatedButton(
// //             onPressed: () {
// //               Navigator.pop(ctx);
// //               context.pop(); // Go back to dashboard
// //             },
// //             child: const Text('Back to Dashboard'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _showSuccessDialogWithBox(models.Box box) {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (ctx) => AlertDialog(
// //         icon: const Icon(Icons.check_circle_rounded, size: 54, color: AppColors.success),
// //         title: const Text('Return Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
// //         content: Text(
// //           'Successfully returned ${_scannedPassports.length} passports to Box ${box.label}. All custody locations updated.',
// //           textAlign: TextAlign.center,
// //         ),
// //         actions: [
// //           ElevatedButton(
// //             onPressed: () {
// //               Navigator.pop(ctx);
// //               context.pop(); // Go back to dashboard
// //             },
// //             child: const Text('Back to Dashboard'),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _showFeedback(String message, bool isError) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
// //         backgroundColor: isError ? AppColors.danger : AppColors.success,
// //         behavior: SnackBarBehavior.floating,
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: AppColors.surface,
// //       body: FingerprintBackground(
// //         child: Column(
// //           children: [
// //             // AppBar area
// //             SafeArea(
// //               bottom: false,
// //               child: Padding(
// //                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //                 child: Row(
// //                   children: [
// //                     IconButton(
// //                       icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark),
// //                       onPressed: () {
// //                         if (_currentStep > 1) {
// //                           setState(() => _currentStep--);
// //                         } else {
// //                           context.pop();
// //                         }
// //                       },
// //                     ),
// //                     Expanded(
// //                       child: Text(
// //                         'Return Custody Flow',
// //                         style: TextStyle(
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.bold,
// //                           color: AppColors.primaryDark,
// //                         ),
// //                       ),
// //                     ),
// //                     Text(
// //                       'Step $_currentStep of 3',
// //                       style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textBody),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),

// //             // Step Indicator progress bar
// //             Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
// //               child: Row(
// //                 children: List.generate(3, (idx) {
// //                   final stepNum = idx + 1;
// //                   final isActive = stepNum <= _currentStep;
// //                   return Expanded(
// //                     child: Container(
// //                       height: 4,
// //                       margin: const EdgeInsets.symmetric(horizontal: 4),
// //                       decoration: BoxDecoration(
// //                         color: isActive ? AppColors.primary : AppColors.border,
// //                         borderRadius: BorderRadius.circular(2),
// //                       ),
// //                     ),
// //                   );
// //                 }),
// //               ),
// //             ),

// //             // Main body steps
// //             Expanded(
// //               child: _buildStepContent(),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildStepContent() {
// //     switch (_currentStep) {
// //       case 1:
// //         return _buildStep1();
// //       case 2:
// //         return _buildStep2();
// //       case 3:
// //         return _buildStep3();
// //       default:
// //         return const SizedBox();
// //     }
// //   }

// //   // --- STEP 1: Scan Passports ---
// //   Widget _buildStep1() {
// //     return Padding(
// //       padding: const EdgeInsets.all(20.0),
// //       child: Column(
// //         children: [
// //           Expanded(
// //             flex: 2,
// //             child: ClipRRect(
// //               borderRadius: BorderRadius.circular(20),
// //               child: Stack(
// //                 children: [
// //                   MobileScanner(
// //                     onDetect: (capture) {
// //                       final barcode = capture.barcodes.firstOrNull;
// //                       if (barcode?.rawValue != null) {
// //                         _addPassportByQr(barcode!.rawValue!);
// //                       }
// //                     },
// //                   ),
// //                   Container(
// //                     decoration: BoxDecoration(
// //                       border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
// //                       borderRadius: BorderRadius.circular(20),
// //                     ),
// //                   ),
// //                   const Positioned(
// //                     bottom: 16,
// //                     left: 0,
// //                     right: 0,
// //                     child: Center(
// //                       child: Card(
// //                         color: Colors.black54,
// //                         child: Padding(
// //                           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //                           child: Text(
// //                             'Scan Passport QR Codes to Stack',
// //                             style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //           const SizedBox(height: 16),
// //           Expanded(
// //             flex: 3,
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Row(
// //                   children: [
// //                     Text(
// //                       'Scanned Stack (${_scannedPassports.length})',
// //                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
// //                     ),
// //                     const Spacer(),
// //                     if (_scannedPassports.isNotEmpty)
// //                       TextButton(
// //                         onPressed: () => setState(() => _scannedPassports.clear()),
// //                         child: const Text('Clear All', style: TextStyle(color: AppColors.danger)),
// //                       ),
// //                   ],
// //                 ),
// //                 Expanded(
// //                   child: _scannedPassports.isEmpty
// //                       ? Center(
// //                           child: Column(
// //                             mainAxisAlignment: MainAxisAlignment.center,
// //                             children: const [
// //                               Icon(Icons.qr_code_2_rounded, size: 48, color: AppColors.textHint),
// //                               SizedBox(height: 8),
// //                               Text('No passports scanned yet', style: TextStyle(color: AppColors.textBody)),
// //                             ],
// //                           ),
// //                         )
// //                       : ListView.builder(
// //                           itemCount: _scannedPassports.length,
// //                           itemBuilder: (ctx, idx) {
// //                             final passport = _scannedPassports[idx];
// //                             return Card(
// //                               margin: const EdgeInsets.only(bottom: 8),
// //                               color: Colors.white,
// //                               child: ListTile(
// //                                 leading: const Icon(Icons.contact_mail_rounded, color: AppColors.primary),
// //                                 title: Text(passport.holderName, style: const TextStyle(fontWeight: FontWeight.bold)),
// //                                 subtitle: Text('${passport.qrCode} • ID: ${passport.holderIdNo}'),
// //                                 trailing: IconButton(
// //                                   icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
// //                                   onPressed: () {
// //                                     setState(() {
// //                                       _scannedPassports.removeAt(idx);
// //                                     });
// //                                   },
// //                                 ),
// //                               ),
// //                             );
// //                           },
// //                         ),
// //                 ),
// //                 const SizedBox(height: 12),
// //                 ElevatedButton(
// //                   onPressed: _scannedPassports.isEmpty ? null : _loadAvailableBoxes,
// //                   child: const Text('Find Storage Box'),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // --- STEP 2: Select Box ---
// //   Widget _buildStep2() {
// //     return Padding(
// //       padding: const EdgeInsets.all(20.0),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           const Text(
// //             'Select Target Storage Box',
// //             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark),
// //           ),
// //           Text(
// //             'Showing boxes with at least ${_scannedPassports.length} available slots',
// //             style: const TextStyle(color: AppColors.textBody, fontSize: 12),
// //           ),
// //           const SizedBox(height: 16),

// //           // Room filter
// //           if (_isLoadingRooms)
// //             const Padding(
// //               padding: EdgeInsets.only(bottom: 8),
// //               child: LinearProgressIndicator(minHeight: 2),
// //             )
// //           else if (_rooms.isNotEmpty)
// //             Container(
// //               margin: const EdgeInsets.only(bottom: 8),
// //               padding: const EdgeInsets.symmetric(horizontal: 12),
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(12),
// //                 border: Border.all(color: AppColors.border),
// //               ),
// //               child: DropdownButtonHideUnderline(
// //                 child: DropdownButton<String?>(
// //                   isExpanded: true,
// //                   value: _selectedRoomId,
// //                   hint: const Text('All rooms', style: TextStyle(fontSize: 14)),
// //                   items: [
// //                     const DropdownMenuItem<String?>(
// //                       value: null,
// //                       child: Text('All rooms'),
// //                     ),
// //                     ..._rooms.map(
// //                       (room) => DropdownMenuItem<String?>(
// //                         value: room.id,
// //                         child: Text(room.name),
// //                       ),
// //                     ),
// //                   ],
// //                   onChanged: (roomId) {
// //                     setState(() => _selectedRoomId = roomId);
// //                     _loadAvailableBoxes(resetPage: true);
// //                   },
// //                 ),
// //               ),
// //             ),
          
// //           // Search input field
// //           Container(
// //             decoration: BoxDecoration(
// //               color: Colors.white,
// //               borderRadius: BorderRadius.circular(12),
// //               border: Border.all(color: AppColors.border),
// //             ),
// //             child: TextField(
// //               controller: _boxSearchController,
// //               onChanged: _onSearchChanged,
// //               onSubmitted: _lookupBoxManually,
// //               decoration: InputDecoration(
// //                 hintText: 'Search by box label or QR code...',
// //                 prefixIcon: const Icon(Icons.search_rounded),
// //                 suffixIcon: _searchQuery.isNotEmpty 
// //                     ? IconButton(
// //                         icon: const Icon(Icons.clear),
// //                         onPressed: () {
// //                           _boxSearchController.clear();
// //                           _onSearchChanged('');
// //                         },
// //                       )
// //                     : null,
// //                 border: InputBorder.none,
// //                 enabledBorder: InputBorder.none,
// //                 focusedBorder: InputBorder.none,
// //                 filled: false,
// //                 contentPadding: const EdgeInsets.symmetric(vertical: 12),
// //               ),
// //             ),
// //           ),
// //           const SizedBox(height: 8),
          
// //           // Results summary
// //           if (_totalBoxes > 0)
// //             Text(
// //               'Found $_totalBoxes boxes • Page $_currentPage of $_totalPages',
// //               style: const TextStyle(fontSize: 11, color: AppColors.textBody),
// //             ),
// //           const SizedBox(height: 16),
          
// //           // Box list with pagination
// //           Expanded(
// //             child: _isLoadingBoxes && _availableBoxes.isEmpty
// //                 ? const Center(child: CircularProgressIndicator())
// //                 : _availableBoxes.isEmpty
// //                     ? Center(
// //                         child: Column(
// //                           mainAxisAlignment: MainAxisAlignment.center,
// //                           children: const [
// //                             Icon(Icons.search_off, size: 48, color: AppColors.textHint),
// //                             SizedBox(height: 8),
// //                             Text(
// //                               'No suitable boxes found.\nTry different search terms or scan a box QR code.',
// //                               textAlign: TextAlign.center,
// //                               style: TextStyle(color: AppColors.textBody),
// //                             ),
// //                           ],
// //                         ),
// //                       )
// //                     : Column(
// //                         children: [
// //                           // Box list
// //                           Expanded(
// //                             child: ListView.builder(
// //                               itemCount: _availableBoxes.length + (_hasMoreBoxes ? 1 : 0),
// //                               itemBuilder: (ctx, idx) {
// //                                 // Load more button
// //                                 if (idx == _availableBoxes.length) {
// //                                   return Padding(
// //                                     padding: const EdgeInsets.symmetric(vertical: 16),
// //                                     child: Center(
// //                                       child: _isLoadingBoxes
// //                                           ? const CircularProgressIndicator()
// //                                           : ElevatedButton.icon(
// //                                               onPressed: _loadNextPage,
// //                                               icon: const Icon(Icons.expand_more),
// //                                               label: Text('Load More (${_totalBoxes - _availableBoxes.length} remaining)'),
// //                                               style: ElevatedButton.styleFrom(
// //                                                 backgroundColor: AppColors.primary.withValues(alpha: 0.1),
// //                                                 foregroundColor: AppColors.primary,
// //                                               ),
// //                                             ),
// //                                     ),
// //                                   );
// //                                 }
                                
// //                                 // Box item
// //                                 final box = _availableBoxes[idx];
// //                                 final vacantSlots = box.capacity - box.occupiedCount;
// //                                 return Card(
// //                                   margin: const EdgeInsets.only(bottom: 12),
// //                                   color: Colors.white,
// //                                   child: ListTile(
// //                                     leading: Icon(
// //                                       Icons.inventory_2_outlined, 
// //                                       color: vacantSlots >= _scannedPassports.length 
// //                                           ? AppColors.primary 
// //                                           : AppColors.textHint,
// //                                     ),
// //                                     title: Text(
// //                                       box.label, 
// //                                       style: const TextStyle(fontWeight: FontWeight.bold),
// //                                     ),
// //                                     subtitle: Column(
// //                                       crossAxisAlignment: CrossAxisAlignment.start,
// //                                       children: [
// //                                         Text(
// //                                           'Space: ${box.occupiedCount}/${box.capacity} occupied • $vacantSlots vacant',
// //                                           style: TextStyle(
// //                                             color: vacantSlots >= _scannedPassports.length 
// //                                                 ? AppColors.textBody 
// //                                                 : AppColors.danger,
// //                                           ),
// //                                         ),
// //                                         if (box.location != null)
// //                                           Text(
// //                                             'Location: ${box.location}',
// //                                             style: const TextStyle(fontSize: 11, color: AppColors.textHint),
// //                                           ),
// //                                       ],
// //                                     ),
// //                                     trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
// //                                     enabled: vacantSlots >= _scannedPassports.length,
// //                                     onTap: vacantSlots >= _scannedPassports.length
// //                                         ? () {
// //                                             setState(() {
// //                                               _selectedBox = box;
// //                                               _currentStep = 3;
// //                                             });
// //                                           }
// //                                         : null,
// //                                   ),
// //                                 );
// //                               },
// //                             ),
// //                           ),
                          
// //                           // Pagination controls (alternative to load more)
// //                           if (_totalPages > 1)
// //                             Container(
// //                               padding: const EdgeInsets.symmetric(vertical: 8),
// //                               child: Row(
// //                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                                 children: [
// //                                   TextButton.icon(
// //                                     onPressed: _currentPage > 1 && !_isLoadingBoxes
// //                                         ? () {
// //                                             setState(() => _currentPage--);
// //                                             _loadAvailableBoxes(resetPage: true);
// //                                           }
// //                                         : null,
// //                                     icon: const Icon(Icons.chevron_left),
// //                                     label: const Text('Previous'),
// //                                   ),
// //                                   Text(
// //                                     'Page $_currentPage of $_totalPages',
// //                                     style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
// //                                   ),
// //                                   TextButton.icon(
// //                                     onPressed: _currentPage < _totalPages && !_isLoadingBoxes
// //                                         ? () {
// //                                             setState(() => _currentPage++);
// //                                             _loadAvailableBoxes(resetPage: true);
// //                                           }
// //                                         : null,
// //                                     icon: const Icon(Icons.chevron_right),
// //                                     label: const Text('Next'),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                         ],
// //                       ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // --- STEP 3: Verify Location & Confirm ---
// //   // --- STEP 3: Verify Box Identity & Location ---
// // // --- STEP 3: Verify Box Identity & Location ---
// // Widget _buildStep3() {
// //   return SingleChildScrollView(
// //     padding: const EdgeInsets.all(20.0),
// //     child: Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         const Text(
// //           'Verify Box & Location',
// //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark),
// //         ),
// //         const Text(
// //           'Scan both box and slot QR codes to verify identity and location',
// //           style: TextStyle(fontSize: 12, color: AppColors.textBody),
// //         ),
// //         const SizedBox(height: 12),
        
// //         // Selected Box Info Card
// //         GlassCard(
// //           child: Padding(
// //             padding: const EdgeInsets.all(16.0),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Row(
// //                   children: [
// //                     const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
// //                     const SizedBox(width: 8),
// //                     Text('Selected: ${_selectedBox!.label}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
// //                     const Spacer(),
// //                     Chip(
// //                       label: Text('${_scannedPassports.length} passports', style: const TextStyle(fontSize: 10)),
// //                       padding: EdgeInsets.zero,
// //                     ),
// //                   ],
// //                 ),
// //                 const Divider(height: 16),
// //                 Text('Expected Location: ${_selectedBox!.location ?? "Unassigned"}', 
// //                      style: const TextStyle(fontSize: 13, color: AppColors.textBody)),
// //               ],
// //             ),
// //           ),
// //         ),
// //         const SizedBox(height: 24),
        
// //         // Step 1: Scan Box QR
// //         const Text(
// //           '1. Scan Physical Box QR Code',
// //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
// //         ),
// //         const Text(
// //           'First, scan the QR code on the physical box to verify its identity',
// //           style: TextStyle(fontSize: 12, color: AppColors.textBody),
// //         ),
// //         const SizedBox(height: 12),
        
// //         ClipRRect(
// //           borderRadius: BorderRadius.circular(16),
// //           child: Container(
// //             height: 160,
// //             width: double.infinity,
// //             color: Colors.black12,
// //             child: _scannedBoxQr != null
// //                 ? Container(
// //                     color: AppColors.success.withOpacity(0.08),
// //                     child: Column(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         const Icon(Icons.check_circle, color: AppColors.success, size: 36),
// //                         const SizedBox(height: 8),
// //                         Text('Box: $_scannedBoxQr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
// //                         TextButton(
// //                           onPressed: () => setState(() => _scannedBoxQr = null),
// //                           child: const Text('Scan Different Box', style: TextStyle(fontSize: 11)),
// //                         ),
// //                       ],
// //                     ),
// //                   )
// //                 : MobileScanner(
// //                     onDetect: (capture) {
// //                       final barcode = capture.barcodes.firstOrNull;
// //                       if (barcode?.rawValue != null) {
// //                         setState(() {
// //                           _scannedBoxQr = barcode!.rawValue;
// //                         });
// //                       }
// //                     },
// //                   ),
// //           ),
// //         ),
        
// //         if (_scannedBoxQr != null) ...[
// //           const SizedBox(height: 24),
          
// //           // Step 2: Scan Slot QR  
// //           const Text(
// //             '2. Scan Physical Slot QR Code',
// //             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
// //           ),
// //           const Text(
// //             'Now scan the QR code of the slot where the box is located',
// //             style: TextStyle(fontSize: 12, color: AppColors.textBody),
// //           ),
// //           const SizedBox(height: 12),
          
// //           ClipRRect(
// //             borderRadius: BorderRadius.circular(16),
// //             child: Container(
// //               height: 160,
// //               width: double.infinity,
// //               color: Colors.black12,
// //               child: _scannedSlotQr != null
// //                   ? Container(
// //                       color: AppColors.success.withOpacity(0.08),
// //                       child: Column(
// //                         mainAxisAlignment: MainAxisAlignment.center,
// //                         children: [
// //                           const Icon(Icons.check_circle, color: AppColors.success, size: 36),
// //                           const SizedBox(height: 8),
// //                           Text('Slot: $_scannedSlotQr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
// //                           TextButton(
// //                             onPressed: () => setState(() => _scannedSlotQr = null),
// //                             child: const Text('Scan Different Slot', style: TextStyle(fontSize: 11)),
// //                           ),
// //                         ],
// //                       ),
// //                     )
// //                   : MobileScanner(
// //                       onDetect: (capture) {
// //                         final barcode = capture.barcodes.firstOrNull;
// //                         if (barcode?.rawValue != null) {
// //                           setState(() {
// //                             _scannedSlotQr = barcode!.rawValue;
// //                           });
// //                         }
// //                       },
// //                     ),
// //             ),
// //           ),
// //         ],
        
// //         const SizedBox(height: 24),
        
// //         // Submit Button
// //         _isSubmitting
// //             ? const Center(child: CircularProgressIndicator())
// //             : ElevatedButton(
// //                 onPressed: _scannedBoxQr == null || _scannedSlotQr == null 
// //                     ? null 
// //                     : () => _submitReturnWithVerification(),
// //                 child: const Text('Verify & Complete Return'),
// //               ),
// //       ],
// //     ),
// //   );
// // }
// // }
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:dio/dio.dart';
// import '../../../core/theme/app_theme.dart';
// import '../../../data/repositories/passport_repository.dart';
// import '../../../data/repositories/box_repository.dart';
// import '../../../data/repositories/location_repository.dart';
// import '../../../data/models/passport.dart';
// import '../../../data/models/box.dart' as models;
// import '../../../data/models/room.dart';
// import '../widgets/glass_card.dart';
// import '../widgets/fingerprint_background.dart';

// class PassportReturnPage extends StatefulWidget {
//   const PassportReturnPage({super.key});

//   @override
//   State<PassportReturnPage> createState() => _PassportReturnPageState();
// }

// class _PassportReturnPageState extends State<PassportReturnPage> {
//   final PassportRepository _passportRepo = PassportRepository();
//   final BoxRepository _boxRepo = BoxRepository();
//   final LocationRepository _locationRepo = LocationRepository();

//   static const _stepLabels = ['Scan', 'Select Box', 'Verify'];

//   // Step state
//   int _currentStep = 1; // 1: Scan Passports, 2: Select Box, 3: Verify & Confirm

//   // Scanned Passports Stack
//   final List<Passport> _scannedPassports = [];

//   // Storage Box State
//   List<models.Box> _availableBoxes = [];
//   models.Box? _selectedBox;
//   bool _isLoadingBoxes = false;
//   final TextEditingController _boxSearchController = TextEditingController();

//   // Pagination State
//   int _currentPage = 1;
//   int _totalPages = 1;
//   int _totalBoxes = 0;
//   bool _hasMoreBoxes = false;
//   String _searchQuery = '';
//   String? _selectedRoomId;
//   List<Room> _rooms = [];
//   bool _isLoadingRooms = false;

//   // Verification state
//   bool _isSubmitting = false;
//   String? _scannedSlotQr;
//   String? _scannedBoxQr;

//   // Inline mismatch banner (replaces modal failover dialogs)
//   String? _mismatchMessage;
//   final ScrollController _step3ScrollController = ScrollController();

//   // Track currently processing QR codes to prevent spam/duplicate API calls
//   final Set<String> _processingQrs = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadRooms();
//   }

//   Future<void> _loadRooms() async {
//     setState(() => _isLoadingRooms = true);
//     final rooms = await _locationRepo.getRooms();
//     if (mounted) {
//       setState(() {
//         _rooms = rooms;
//         _isLoadingRooms = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _boxSearchController.dispose();
//     _step3ScrollController.dispose();
//     super.dispose();
//   }

//   /// Surfaces a mismatch both as a snackbar (guaranteed visible immediately)
//   /// and as a persistent banner at the top of step 3, scrolling it into view
//   /// so it isn't missed if the person is scrolled down at the slot scanner.
//   void _raiseMismatch(String message) {
//     setState(() => _mismatchMessage = message);
//     _showFeedback(message, true);
//     if (_step3ScrollController.hasClients) {
//       _step3ScrollController.animateTo(
//         0,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   void _addPassportByQr(String code) async {
//     // If already in the stack, ignore silently (prevents screen flooding with errors)
//     if (_scannedPassports.any((p) => p.qrCode == code)) {
//       return;
//     }

//     // Prevent duplicate parallel api requests
//     if (_processingQrs.contains(code)) {
//       return;
//     }

//     _processingQrs.add(code);

//     try {
//       final passport = await _passportRepo.getByQr(code);
//       if (passport == null) {
//         _showFeedback('Passport not found in system: $code', true);
//         return;
//       }

//       if (!passport.isIssued) {
//         _showFeedback(
//           '${passport.holderName} is ${passport.status} — only ISSUED passports can be returned',
//           true,
//         );
//         return;
//       }

//       setState(() {
//         _scannedPassports.add(passport);
//       });
//       _showFeedback('Added: ${passport.holderName}', false);
//     } catch (e) {
//       _showFeedback('Error looking up passport: $e', true);
//     } finally {
//       // Keep in processing set for 2 seconds to let the user move the camera away
//       Future.delayed(const Duration(seconds: 2), () {
//         if (mounted) {
//           _processingQrs.remove(code);
//         }
//       });
//     }
//   }

//   void _loadAvailableBoxes({bool resetPage = true}) async {
//     if (resetPage) {
//       setState(() {
//         _currentPage = 1;
//         _availableBoxes.clear();
//       });
//     }

//     setState(() {
//       _isLoadingBoxes = true;
//       _currentStep = 2;
//     });

//     try {
//       final response = await _boxRepo.getAvailablePaginated(
//         _scannedPassports.length,
//         page: _currentPage,
//         limit: 20,
//         search: _searchQuery.isNotEmpty ? _searchQuery : null,
//         roomId: _selectedRoomId,
//       );

//       setState(() {
//         if (resetPage) {
//           _availableBoxes = response.data;
//         } else {
//           _availableBoxes.addAll(response.data);
//         }
//         _totalPages = response.totalPages;
//         _totalBoxes = response.total;
//         _hasMoreBoxes = response.hasMore;
//         _isLoadingBoxes = false;
//       });
//     } catch (e) {
//       setState(() => _isLoadingBoxes = false);
//       _showFeedback('Failed to load matching boxes', true);
//     }
//   }

//   void _loadNextPage() async {
//     if (_hasMoreBoxes && !_isLoadingBoxes) {
//       setState(() => _currentPage++);
//       _loadAvailableBoxes(resetPage: false);
//     }
//   }

//   void _onSearchChanged(String query) {
//     setState(() => _searchQuery = query);
//     // Debounce search by 500ms
//     Future.delayed(const Duration(milliseconds: 500), () {
//       if (_searchQuery == query) {
//         _loadAvailableBoxes(resetPage: true);
//       }
//     });
//   }

//   void _lookupBoxManually(String qrCode) async {
//     setState(() => _isLoadingBoxes = true);
//     try {
//       final box = await _boxRepo.getByQr(qrCode);
//       setState(() {
//         _isLoadingBoxes = false;
//         if (box != null) {
//           _selectedBox = box;
//           _currentStep = 3;
//         } else {
//           _showFeedback('Box not found: $qrCode', true);
//         }
//       });
//     } catch (e) {
//       setState(() => _isLoadingBoxes = false);
//       _showFeedback('Box lookup failed', true);
//     }
//   }

//   Future<void> _executeBatchReturn() async {
//     if (_selectedBox == null) return;
//     setState(() => _isSubmitting = true);

//     try {
//       final passportIds = _scannedPassports.map((p) => p.id).toList();
//       await _passportRepo.batchAssign(
//         passportIds: passportIds,
//         boxId: _selectedBox!.id,
//         slotQrCode: _scannedSlotQr,
//         action: 'PASSPORT_RETURNED',
//       );

//       if (!mounted) return;
//       setState(() => _isSubmitting = false);
//       _showSuccessDialog();
//     } on DioException catch (dioErr) {
//       if (!mounted) return;
//       setState(() => _isSubmitting = false);
//       _handleReturnError(dioErr);
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _isSubmitting = false);
//       _showFeedback('Return transaction failed: $e', true);
//     }
//   }

//   /// Surfaces any failure inline and resets the scan state so the user can
//   /// simply rescan, rather than routing through a modal override flow.
//   void _handleReturnError(DioException dioErr) {
//     final responseData = dioErr.response?.data;

//     if (responseData is Map && responseData['error'] == 'LOCATION_MISMATCH') {
//       final current = responseData['currentLocation'] ?? 'Unknown';
//       final scanned = responseData['scannedLocation'] ?? 'Unknown';
//       setState(() => _scannedSlotQr = null);
//       _raiseMismatch(
//         'This box is registered at "$current" but the slot you scanned '
//         'is "$scanned". Move the box to its registered location, or scan '
//         'the correct slot, then try again.',
//       );
//       return;
//     }

//     final message = responseData is Map
//         ? (responseData['message'] as String? ?? 'Network submission error')
//         : 'Network submission error';
//     _showFeedback(message, true);
//   }

//   void _submitReturnWithVerification() async {
//     if (_selectedBox == null || _scannedBoxQr == null || _scannedSlotQr == null) {
//       return;
//     }

//     if (_scannedBoxQr != _selectedBox!.qrCode) {
//       final scanned = _scannedBoxQr;
//       setState(() {
//         _scannedBoxQr = null;
//         _scannedSlotQr = null;
//       });
//       _raiseMismatch(
//         'The scanned box ($scanned) doesn\'t match the box you selected '
//         '(${_selectedBox!.label}). Rescan the correct box to continue.',
//       );
//       return;
//     }

//     setState(() {
//       _isSubmitting = true;
//       _mismatchMessage = null;
//     });

//     await _executeBatchReturn();
//   }

//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => AlertDialog(
//         icon: const Icon(Icons.check_circle_rounded, size: 54, color: AppColors.success),
//         title: const Text('Return Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
//         content: Text(
//           'Successfully returned ${_scannedPassports.length} passports to Box ${_selectedBox!.label}. All custody locations updated.',
//           textAlign: TextAlign.center,
//         ),
//         actions: [
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               context.pop(); // Go back to dashboard
//             },
//             child: const Text('Back to Dashboard'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showFeedback(String message, bool isError) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: isError ? AppColors.danger : AppColors.success,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.surface,
//       body: FingerprintBackground(
//         child: Column(
//           children: [
//             // AppBar area
//             SafeArea(
//               bottom: false,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark),
//                       onPressed: () {
//                         if (_currentStep > 1) {
//                           setState(() {
//                             _currentStep--;
//                             _mismatchMessage = null;
//                           });
//                         } else {
//                           context.pop();
//                         }
//                       },
//                     ),
//                     const Expanded(
//                       child: Text(
//                         'Return Custody Flow',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.primaryDark,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             _buildStepIndicator(),

//             // Main body steps
//             Expanded(
//               child: _buildStepContent(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStepIndicator() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
//       child: Row(
//         children: List.generate(3, (idx) {
//           final stepNum = idx + 1;
//           final isActive = stepNum <= _currentStep;
//           final isCurrent = stepNum == _currentStep;
//           return Expanded(
//             child: Padding(
//               padding: EdgeInsets.only(right: idx < 2 ? 8 : 0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   AnimatedContainer(
//                     duration: const Duration(milliseconds: 200),
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: isActive ? AppColors.primary : AppColors.border,
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     _stepLabels[idx],
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
//                       color: isActive ? AppColors.primaryDark : AppColors.textHint,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }

//   Widget _buildStepContent() {
//     switch (_currentStep) {
//       case 1:
//         return _buildStep1();
//       case 2:
//         return _buildStep2();
//       case 3:
//         return _buildStep3();
//       default:
//         return const SizedBox();
//     }
//   }

//   // --- STEP 1: Scan Passports ---
//   Widget _buildStep1() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//       child: Column(
//         children: [
//           Expanded(
//             flex: 2,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(20),
//               child: Stack(
//                 children: [
//                   MobileScanner(
//                     onDetect: (capture) {
//                       final barcode = capture.barcodes.firstOrNull;
//                       if (barcode?.rawValue != null) {
//                         _addPassportByQr(barcode!.rawValue!);
//                       }
//                     },
//                   ),
//                   const _ScanReticle(),
//                   Positioned(
//                     top: 12,
//                     left: 12,
//                     child: _CountBadge(count: _scannedPassports.length, label: 'scanned'),
//                   ),
//                   const Positioned(
//                     bottom: 16,
//                     left: 0,
//                     right: 0,
//                     child: Center(
//                       child: _ScanHint(text: 'Point camera at a passport QR code'),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Expanded(
//             flex: 3,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(
//                       'Scanned Stack (${_scannedPassports.length})',
//                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
//                     ),
//                     const Spacer(),
//                     if (_scannedPassports.isNotEmpty)
//                       TextButton(
//                         onPressed: () => setState(() => _scannedPassports.clear()),
//                         child: const Text('Clear All', style: TextStyle(color: AppColors.danger)),
//                       ),
//                   ],
//                 ),
//                 Expanded(
//                   child: _scannedPassports.isEmpty
//                       ? const _EmptyState(
//                           icon: Icons.qr_code_2_rounded,
//                           message: 'No passports scanned yet',
//                         )
//                       : ListView.separated(
//                           itemCount: _scannedPassports.length,
//                           separatorBuilder: (_, __) => const SizedBox(height: 8),
//                           itemBuilder: (ctx, idx) {
//                             final passport = _scannedPassports[idx];
//                             return _FlatCard(
//                               child: ListTile(
//                                 contentPadding: const EdgeInsets.symmetric(horizontal: 12),
//                                 leading: const CircleAvatar(
//                                   backgroundColor: AppColors.primary,
//                                   foregroundColor: Colors.white,
//                                   child: Icon(Icons.contact_mail_rounded, size: 18),
//                                 ),
//                                 title: Text(passport.holderName, style: const TextStyle(fontWeight: FontWeight.bold)),
//                                 subtitle: Text('${passport.qrCode} • ID: ${passport.holderIdNo}'),
//                                 trailing: IconButton(
//                                   icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
//                                   onPressed: () {
//                                     setState(() {
//                                       _scannedPassports.removeAt(idx);
//                                     });
//                                   },
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                 ),
//                 const SizedBox(height: 12),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     onPressed: _scannedPassports.isEmpty ? null : _loadAvailableBoxes,
//                     icon: const Icon(Icons.inventory_2_outlined),
//                     label: const Text('Find Storage Box'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- STEP 2: Select Box ---
//   Widget _buildStep2() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Select Target Storage Box',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark),
//           ),
//           Text(
//             'Showing boxes with at least ${_scannedPassports.length} available slots',
//             style: const TextStyle(color: AppColors.textBody, fontSize: 12),
//           ),
//           const SizedBox(height: 16),

//           // Room filter
//           if (_isLoadingRooms)
//             const Padding(
//               padding: EdgeInsets.only(bottom: 8),
//               child: LinearProgressIndicator(minHeight: 2),
//             )
//           else if (_rooms.isNotEmpty)
//             Container(
//               margin: const EdgeInsets.only(bottom: 8),
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: AppColors.border),
//               ),
//               child: DropdownButtonHideUnderline(
//                 child: DropdownButton<String?>(
//                   isExpanded: true,
//                   value: _selectedRoomId,
//                   hint: const Text('All rooms', style: TextStyle(fontSize: 14)),
//                   items: [
//                     const DropdownMenuItem<String?>(
//                       value: null,
//                       child: Text('All rooms'),
//                     ),
//                     ..._rooms.map(
//                       (room) => DropdownMenuItem<String?>(
//                         value: room.id,
//                         child: Text(room.name),
//                       ),
//                     ),
//                   ],
//                   onChanged: (roomId) {
//                     setState(() => _selectedRoomId = roomId);
//                     _loadAvailableBoxes(resetPage: true);
//                   },
//                 ),
//               ),
//             ),

//           // Search input field
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: AppColors.border),
//             ),
//             child: TextField(
//               controller: _boxSearchController,
//               onChanged: _onSearchChanged,
//               onSubmitted: _lookupBoxManually,
//               decoration: InputDecoration(
//                 hintText: 'Search by box label or QR code...',
//                 prefixIcon: const Icon(Icons.search_rounded),
//                 suffixIcon: _searchQuery.isNotEmpty
//                     ? IconButton(
//                         icon: const Icon(Icons.clear),
//                         onPressed: () {
//                           _boxSearchController.clear();
//                           _onSearchChanged('');
//                         },
//                       )
//                     : null,
//                 border: InputBorder.none,
//                 enabledBorder: InputBorder.none,
//                 focusedBorder: InputBorder.none,
//                 filled: false,
//                 contentPadding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),

//           // Results summary
//           if (_totalBoxes > 0)
//             Text(
//               'Found $_totalBoxes boxes • Page $_currentPage of $_totalPages',
//               style: const TextStyle(fontSize: 11, color: AppColors.textBody),
//             ),
//           const SizedBox(height: 16),

//           // Box list with pagination
//           Expanded(
//             child: _isLoadingBoxes && _availableBoxes.isEmpty
//                 ? const Center(child: CircularProgressIndicator())
//                 : _availableBoxes.isEmpty
//                     ? const _EmptyState(
//                         icon: Icons.search_off,
//                         message: 'No suitable boxes found.\nTry different search terms or scan a box QR code.',
//                       )
//                     : Column(
//                         children: [
//                           Expanded(
//                             child: ListView.separated(
//                               itemCount: _availableBoxes.length + (_hasMoreBoxes ? 1 : 0),
//                               separatorBuilder: (_, __) => const SizedBox(height: 10),
//                               itemBuilder: (ctx, idx) {
//                                 if (idx == _availableBoxes.length) {
//                                   return Center(
//                                     child: _isLoadingBoxes
//                                         ? const Padding(
//                                             padding: EdgeInsets.symmetric(vertical: 8),
//                                             child: CircularProgressIndicator(),
//                                           )
//                                         : OutlinedButton.icon(
//                                             onPressed: _loadNextPage,
//                                             icon: const Icon(Icons.expand_more),
//                                             label: Text('Load More (${_totalBoxes - _availableBoxes.length} remaining)'),
//                                           ),
//                                   );
//                                 }

//                                 final box = _availableBoxes[idx];
//                                 final vacantSlots = box.capacity - box.occupiedCount;
//                                 final fits = vacantSlots >= _scannedPassports.length;
//                                 final spaceColor = fits ? AppColors.success : AppColors.danger;

//                                 return _FlatCard(
//                                   onTap: fits
//                                       ? () {
//                                           setState(() {
//                                             _selectedBox = box;
//                                             _currentStep = 3;
//                                           });
//                                         }
//                                       : null,
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(14),
//                                     child: Row(
//                                       children: [
//                                         Container(
//                                           width: 40,
//                                           height: 40,
//                                           decoration: BoxDecoration(
//                                             color: (fits ? AppColors.primary : AppColors.textHint).withValues(alpha: 0.1),
//                                             borderRadius: BorderRadius.circular(10),
//                                           ),
//                                           child: Icon(
//                                             Icons.inventory_2_outlined,
//                                             color: fits ? AppColors.primary : AppColors.textHint,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 12),
//                                         Expanded(
//                                           child: Column(
//                                             crossAxisAlignment: CrossAxisAlignment.start,
//                                             children: [
//                                               Text(box.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
//                                               const SizedBox(height: 2),
//                                               if (box.location != null)
//                                                 Text(
//                                                   box.location!,
//                                                   style: const TextStyle(fontSize: 11, color: AppColors.textHint),
//                                                   maxLines: 1,
//                                                   overflow: TextOverflow.ellipsis,
//                                                 ),
//                                             ],
//                                           ),
//                                         ),
//                                         const SizedBox(width: 8),
//                                         Container(
//                                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                           decoration: BoxDecoration(
//                                             color: spaceColor.withValues(alpha: 0.1),
//                                             borderRadius: BorderRadius.circular(8),
//                                           ),
//                                           child: Text(
//                                             '$vacantSlots vacant',
//                                             style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: spaceColor),
//                                           ),
//                                         ),
//                                         if (fits) ...[
//                                           const SizedBox(width: 4),
//                                           const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
//                                         ],
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                           if (_totalPages > 1)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 8),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   TextButton.icon(
//                                     onPressed: _currentPage > 1 && !_isLoadingBoxes
//                                         ? () {
//                                             setState(() => _currentPage--);
//                                             _loadAvailableBoxes(resetPage: true);
//                                           }
//                                         : null,
//                                     icon: const Icon(Icons.chevron_left),
//                                     label: const Text('Previous'),
//                                   ),
//                                   Text(
//                                     'Page $_currentPage of $_totalPages',
//                                     style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//                                   ),
//                                   TextButton.icon(
//                                     onPressed: _currentPage < _totalPages && !_isLoadingBoxes
//                                         ? () {
//                                             setState(() => _currentPage++);
//                                             _loadAvailableBoxes(resetPage: true);
//                                           }
//                                         : null,
//                                     icon: const Icon(Icons.chevron_right),
//                                     label: const Text('Next'),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                         ],
//                       ),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- STEP 3: Verify Box Identity & Location ---
//   Widget _buildStep3() {
//     return SingleChildScrollView(
//       controller: _step3ScrollController,
//       padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Verify Box & Location',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark),
//           ),
//           const Text(
//             'Scan both the box and the slot to confirm they match',
//             style: TextStyle(fontSize: 12, color: AppColors.textBody),
//           ),
//           const SizedBox(height: 12),

//           if (_mismatchMessage != null) ...[
//             TweenAnimationBuilder<double>(
//               tween: Tween(begin: 0.85, end: 1.0),
//               duration: const Duration(milliseconds: 220),
//               curve: Curves.easeOut,
//               builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
//               child: _MismatchBanner(
//                 message: _mismatchMessage!,
//                 onDismiss: () => setState(() => _mismatchMessage = null),
//               ),
//             ),
//             const SizedBox(height: 12),
//           ],

//           // Selected Box Info Card
//           _FlatCard(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         width: 36,
//                         height: 36,
//                         decoration: BoxDecoration(
//                           color: AppColors.primary.withValues(alpha: 0.1),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 20),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: Text(_selectedBox!.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                       ),
//                       Chip(
//                         label: Text('${_scannedPassports.length} passports', style: const TextStyle(fontSize: 10)),
//                         backgroundColor: AppColors.primary.withValues(alpha: 0.08),
//                         padding: EdgeInsets.zero,
//                         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                       ),
//                     ],
//                   ),
//                   const Divider(height: 24),
//                   Text(
//                     'Expected location: ${_selectedBox!.location ?? "Unassigned"}',
//                     style: const TextStyle(fontSize: 13, color: AppColors.textBody),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Verification checklist
//           _VerifyScanTile(
//             stepNumber: 1,
//             title: 'Scan Physical Box QR Code',
//             subtitle: 'Confirm this is the correct physical box',
//             scannedValue: _scannedBoxQr,
//             valueLabel: 'Box',
//             onClear: () => setState(() => _scannedBoxQr = null),
//             scanner: MobileScanner(
//               onDetect: (capture) {
//                 final barcode = capture.barcodes.firstOrNull;
//                 if (barcode?.rawValue != null) {
//                   setState(() {
//                     _scannedBoxQr = barcode!.rawValue;
//                     _mismatchMessage = null;
//                   });
//                 }
//               },
//             ),
//           ),

//           if (_scannedBoxQr != null) ...[
//             const SizedBox(height: 16),
//             _VerifyScanTile(
//               stepNumber: 2,
//               title: 'Scan Physical Slot QR Code',
//               subtitle: 'Confirm where the box is physically located',
//               scannedValue: _scannedSlotQr,
//               valueLabel: 'Slot',
//               onClear: () => setState(() => _scannedSlotQr = null),
//               scanner: MobileScanner(
//                 onDetect: (capture) {
//                   final barcode = capture.barcodes.firstOrNull;
//                   if (barcode?.rawValue != null) {
//                     setState(() {
//                       _scannedSlotQr = barcode!.rawValue;
//                       _mismatchMessage = null;
//                     });
//                   }
//                 },
//               ),
//             ),
//           ],

//           const SizedBox(height: 24),

//           SizedBox(
//             width: double.infinity,
//             child: _isSubmitting
//                 ? const Center(child: CircularProgressIndicator())
//                 : ElevatedButton.icon(
//                     onPressed: _scannedBoxQr == null || _scannedSlotQr == null
//                         ? null
//                         : _submitReturnWithVerification,
//                     icon: const Icon(Icons.check_circle_outline_rounded),
//                     label: const Text('Verify & Complete Return'),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Corner-bracket scan reticle, replaces the plain border overlay.
// class _ScanReticle extends StatelessWidget {
//   const _ScanReticle();

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: SizedBox(
//         width: 220,
//         height: 140,
//         child: Stack(
//           children: [
//             for (final alignment in [
//               Alignment.topLeft,
//               Alignment.topRight,
//               Alignment.bottomLeft,
//               Alignment.bottomRight,
//             ])
//               Align(
//                 alignment: alignment,
//                 child: _ReticleCorner(alignment: alignment),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ReticleCorner extends StatelessWidget {
//   final Alignment alignment;
//   const _ReticleCorner({required this.alignment});

//   @override
//   Widget build(BuildContext context) {
//     final isTop = alignment.y < 0;
//     final isLeft = alignment.x < 0;
//     return Container(
//       width: 28,
//       height: 28,
//       decoration: BoxDecoration(
//         border: Border(
//           top: isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
//           bottom: !isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
//           left: isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
//           right: !isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
//         ),
//       ),
//     );
//   }
// }

// class _ScanHint extends StatelessWidget {
//   final String text;
//   const _ScanHint({required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.black54,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         text,
//         style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }

// class _CountBadge extends StatelessWidget {
//   final int count;
//   final String label;
//   const _CountBadge({required this.count, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: AppColors.primary,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         '$count $label',
//         style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }

// /// Flat, bordered card used throughout — matches the flat design language
// /// instead of relying on drop shadows.
// class _FlatCard extends StatelessWidget {
//   final Widget child;
//   final VoidCallback? onTap;
//   const _FlatCard({required this.child, this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(14),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(14),
//         onTap: onTap,
//         child: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: AppColors.border),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

// class _EmptyState extends StatelessWidget {
//   final IconData icon;
//   final String message;
//   const _EmptyState({required this.icon, required this.message});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 48, color: AppColors.textHint),
//           const SizedBox(height: 8),
//           Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textBody)),
//         ],
//       ),
//     );
//   }
// }

// /// Inline warning shown when a scanned box/slot doesn't match expectations.
// /// Replaces the old blocking AlertDialog "override" flow: the person just
// /// dismisses it and rescans — no override path exists anymore.
// class _MismatchBanner extends StatelessWidget {
//   final String message;
//   final VoidCallback onDismiss;
//   const _MismatchBanner({required this.message, required this.onDismiss});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: AppColors.warning.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               message,
//               style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.primaryDark),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.close_rounded, size: 18),
//             color: AppColors.textHint,
//             padding: EdgeInsets.zero,
//             constraints: const BoxConstraints(),
//             onPressed: onDismiss,
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// A single numbered scan step used in the verification screen — shows
// /// either the live scanner or a confirmed result state.
// class _VerifyScanTile extends StatelessWidget {
//   final int stepNumber;
//   final String title;
//   final String subtitle;
//   final String? scannedValue;
//   final String valueLabel;
//   final VoidCallback onClear;
//   final Widget scanner;

//   const _VerifyScanTile({
//     required this.stepNumber,
//     required this.title,
//     required this.subtitle,
//     required this.scannedValue,
//     required this.valueLabel,
//     required this.onClear,
//     required this.scanner,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isDone = scannedValue != null;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               width: 22,
//               height: 22,
//               margin: const EdgeInsets.only(top: 1),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: isDone ? AppColors.success : AppColors.primary,
//               ),
//               child: Center(
//                 child: isDone
//                     ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
//                     : Text('$stepNumber', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark)),
//                   Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         ClipRRect(
//           borderRadius: BorderRadius.circular(16),
//           child: Container(
//             height: 150,
//             width: double.infinity,
//             color: Colors.black12,
//             child: isDone
//                 ? Container(
//                     color: AppColors.success.withValues(alpha: 0.08),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.check_circle, color: AppColors.success, size: 32),
//                         const SizedBox(height: 6),
//                         Text('$valueLabel: $scannedValue', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
//                         TextButton(
//                           onPressed: onClear,
//                           child: Text('Rescan $valueLabel', style: const TextStyle(fontSize: 11)),
//                         ),
//                       ],
//                     ),
//                   )
//                 : Stack(
//                     children: [
//                       scanner,
//                       const _ScanReticle(),
//                     ],
//                   ),
//           ),
//         ),
//       ],
//     );
//   }
// }
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
import '../widgets/glass_card.dart';
import '../widgets/fingerprint_background.dart';

class PassportReturnPage extends StatefulWidget {
  const PassportReturnPage({super.key});

  @override
  State<PassportReturnPage> createState() => _PassportReturnPageState();
}

class _PassportReturnPageState extends State<PassportReturnPage> {
  final PassportRepository _passportRepo = PassportRepository();
  final BoxRepository _boxRepo = BoxRepository();
  final LocationRepository _locationRepo = LocationRepository();

  static const _stepLabels = ['Scan', 'Select Box', 'Verify'];

  static final _pillButtonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
  );

  // Step state
  int _currentStep = 1; // 1: Scan Passports, 2: Select Box, 3: Verify & Confirm

  // Scanned Passports Stack
  final List<Passport> _scannedPassports = [];

  // Storage Box State
  List<models.Box> _availableBoxes = [];
  models.Box? _selectedBox;
  bool _isLoadingBoxes = false;
  final TextEditingController _boxSearchController = TextEditingController();

  // Pagination State
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalBoxes = 0;
  bool _hasMoreBoxes = false;
  String _searchQuery = '';
  String? _selectedRoomId;
  List<Room> _rooms = [];
  bool _isLoadingRooms = false;

  // Verification state
  bool _isSubmitting = false;
  String? _scannedSlotQr;
  String? _scannedBoxQr;

  // Inline mismatch banner (replaces modal failover dialogs)
  String? _mismatchMessage;
  final ScrollController _step3ScrollController = ScrollController();

  // Track currently processing QR codes to prevent spam/duplicate API calls
  final Set<String> _processingQrs = {};

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoadingRooms = true);
    final rooms = await _locationRepo.getRooms();
    if (mounted) {
      setState(() {
        _rooms = rooms;
        _isLoadingRooms = false;
      });
    }
  }

  @override
  void dispose() {
    _boxSearchController.dispose();
    _step3ScrollController.dispose();
    super.dispose();
  }

  /// Surfaces a mismatch both as a snackbar (guaranteed visible immediately)
  /// and as a persistent banner at the top of step 3, scrolling it into view
  /// so it isn't missed if the person is scrolled down at the slot scanner.
  void _raiseMismatch(String message) {
    setState(() => _mismatchMessage = message);
    _showFeedback(message, true);
    if (_step3ScrollController.hasClients) {
      _step3ScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _addPassportByQr(String code) async {
    // If already in the stack, ignore silently (prevents screen flooding with errors)
    if (_scannedPassports.any((p) => p.qrCode == code)) {
      return;
    }

    // Prevent duplicate parallel api requests
    if (_processingQrs.contains(code)) {
      return;
    }

    _processingQrs.add(code);

    try {
      final passport = await _passportRepo.getByQr(code);
      if (passport == null) {
        _showFeedback('Passport not found in system: $code', true);
        return;
      }

      if (!passport.isIssued) {
        _showFeedback(
          '${passport.holderName} is ${passport.status} — only ISSUED passports can be returned',
          true,
        );
        return;
      }

      setState(() {
        _scannedPassports.add(passport);
      });
      _showFeedback('Added: ${passport.holderName}', false);
    } catch (e) {
      _showFeedback('Error looking up passport: $e', true);
    } finally {
      // Keep in processing set for 2 seconds to let the user move the camera away
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _processingQrs.remove(code);
        }
      });
    }
  }

  void _loadAvailableBoxes({bool resetPage = true}) async {
    if (resetPage) {
      setState(() {
        _currentPage = 1;
        _availableBoxes.clear();
      });
    }

    setState(() {
      _isLoadingBoxes = true;
      _currentStep = 2;
    });

    try {
      final response = await _boxRepo.getAvailablePaginated(
        _scannedPassports.length,
        page: _currentPage,
        limit: 20,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        roomId: _selectedRoomId,
      );

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
      setState(() => _isLoadingBoxes = false);
      _showFeedback('Failed to load matching boxes', true);
    }
  }

  void _loadNextPage() async {
    if (_hasMoreBoxes && !_isLoadingBoxes) {
      setState(() => _currentPage++);
      _loadAvailableBoxes(resetPage: false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    // Debounce search by 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        _loadAvailableBoxes(resetPage: true);
      }
    });
  }

  void _lookupBoxManually(String qrCode) async {
    setState(() => _isLoadingBoxes = true);
    try {
      final box = await _boxRepo.getByQr(qrCode);
      setState(() {
        _isLoadingBoxes = false;
        if (box != null) {
          _selectedBox = box;
          _currentStep = 3;
        } else {
          _showFeedback('Box not found: $qrCode', true);
        }
      });
    } catch (e) {
      setState(() => _isLoadingBoxes = false);
      _showFeedback('Box lookup failed', true);
    }
  }

  Future<void> _executeBatchReturn() async {
    if (_selectedBox == null) return;
    setState(() => _isSubmitting = true);

    try {
      final passportIds = _scannedPassports.map((p) => p.id).toList();
      await _passportRepo.batchAssign(
        passportIds: passportIds,
        boxId: _selectedBox!.id,
        slotQrCode: _scannedSlotQr,
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
      _showFeedback('Return transaction failed: $e', true);
    }
  }

  /// Surfaces any failure inline and resets the scan state so the user can
  /// simply rescan, rather than routing through a modal override flow.
  void _handleReturnError(DioException dioErr) {
    final responseData = dioErr.response?.data;

    if (responseData is Map && responseData['error'] == 'LOCATION_MISMATCH') {
      setState(() => _scannedSlotQr = null);
      _raiseMismatch('Wrong slot — this box belongs at a different location. Rescan the correct slot.');
      return;
    }

    final message = responseData is Map
        ? (responseData['message'] as String? ?? 'Network submission error')
        : 'Network submission error';
    _showFeedback(message, true);
  }

  void _submitReturnWithVerification() async {
    if (_selectedBox == null || _scannedBoxQr == null || _scannedSlotQr == null) {
      return;
    }

    if (_scannedBoxQr != _selectedBox!.qrCode) {
      setState(() {
        _scannedBoxQr = null;
        _scannedSlotQr = null;
      });
      _raiseMismatch('Wrong box — that\'s not the box you selected. Rescan the correct one.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _mismatchMessage = null;
    });

    await _executeBatchReturn();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.1),
          ),
          child: const Icon(Icons.check_circle_rounded, size: 40, color: AppColors.success),
        ),
        title: const Text('Return Confirmed', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Successfully returned ${_scannedPassports.length} passports to Box ${_selectedBox!.label}. All custody locations updated.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: _pillButtonStyle,
              onPressed: () {
                Navigator.pop(ctx);
                context.pop(); // Go back to dashboard
              },
              child: const Text('Back to Dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedback(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FingerprintBackground(
        child: Column(
          children: [
            // AppBar area
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
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark, size: 20),
                        onPressed: () {
                          if (_currentStep > 1) {
                            setState(() {
                              _currentStep--;
                              _mismatchMessage = null;
                            });
                          } else {
                            context.pop();
                          }
                        },
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

            // Main body steps
            Expanded(
              child: _buildStepContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
      child: Row(
        children: List.generate(3, (idx) {
          final stepNum = idx + 1;
          final isDone = stepNum < _currentStep;
          final isCurrent = stepNum == _currentStep;
          final isActive = stepNum <= _currentStep;
          final circle = AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primary : Colors.white,
              border: Border.all(color: isActive ? AppColors.primary : AppColors.border, width: 1.5),
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
          );
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    circle,
                    const SizedBox(height: 6),
                    Text(
                      _stepLabels[idx],
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? AppColors.primaryDark : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                if (idx < 2)
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

  // --- STEP 1: Scan Passports ---
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
                        _addPassportByQr(barcode!.rawValue!);
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
                    ),
                    const Spacer(),
                    if (_scannedPassports.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _scannedPassports.clear()),
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
                                title: Text(passport.holderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${passport.qrCode} • ID: ${passport.holderIdNo}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                                  onPressed: () {
                                    setState(() {
                                      _scannedPassports.removeAt(idx);
                                    });
                                  },
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
                    style: _pillButtonStyle,
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

          // Room filter
          if (_isLoadingRooms)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else if (_rooms.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
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
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All rooms'),
                    ),
                    ..._rooms.map(
                      (room) => DropdownMenuItem<String?>(
                        value: room.id,
                        child: Text(room.name),
                      ),
                    ),
                  ],
                  onChanged: (roomId) {
                    setState(() => _selectedRoomId = roomId);
                    _loadAvailableBoxes(resetPage: true);
                  },
                ),
              ),
            ),

          // Search input field
          Container(
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
              onSubmitted: _lookupBoxManually,
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
          ),
          const SizedBox(height: 8),

          // Results summary
          if (_totalBoxes > 0)
            Text(
              'Found $_totalBoxes boxes • Page $_currentPage of $_totalPages',
              style: const TextStyle(fontSize: 11, color: AppColors.textBody),
            ),
          const SizedBox(height: 16),

          // Box list with pagination
          Expanded(
            child: _isLoadingBoxes && _availableBoxes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _availableBoxes.isEmpty
                    ? const _EmptyState(
                        icon: Icons.search_off,
                        message: 'No suitable boxes found.\nTry different search terms or scan a box QR code.',
                      )
                    : Column(
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
                                final spaceColor = fits ? AppColors.success : AppColors.danger;

                                return _FlatCard(
                                  onTap: fits
                                      ? () {
                                          setState(() {
                                            _selectedBox = box;
                                            _currentStep = 3;
                                          });
                                        }
                                      : null,
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
                                              const SizedBox(height: 2),
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
                              },
                            ),
                          ),
                          if (_totalPages > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    onPressed: _currentPage > 1 && !_isLoadingBoxes
                                        ? () {
                                            setState(() => _currentPage--);
                                            _loadAvailableBoxes(resetPage: true);
                                          }
                                        : null,
                                    icon: const Icon(Icons.chevron_left),
                                    label: const Text('Previous'),
                                  ),
                                  Text(
                                    'Page $_currentPage of $_totalPages',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  TextButton.icon(
                                    onPressed: _currentPage < _totalPages && !_isLoadingBoxes
                                        ? () {
                                            setState(() => _currentPage++);
                                            _loadAvailableBoxes(resetPage: true);
                                          }
                                        : null,
                                    icon: const Icon(Icons.chevron_right),
                                    label: const Text('Next'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: Verify Box Identity & Location ---
  Widget _buildStep3() {
    return SingleChildScrollView(
      controller: _step3ScrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verify Box & Location',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryDark),
          ),
          const Text(
            'Scan both the box and the slot to confirm they match',
            style: TextStyle(fontSize: 12, color: AppColors.textBody),
          ),
          const SizedBox(height: 12),

          if (_mismatchMessage != null) ...[
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: _MismatchBanner(
                message: _mismatchMessage!,
                onDismiss: () => setState(() => _mismatchMessage = null),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Selected Box Info Card
          _FlatCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_selectedBox!.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Chip(
                        label: Text('${_scannedPassports.length} passports', style: const TextStyle(fontSize: 10)),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    'Expected location: ${_selectedBox!.location ?? "Unassigned"}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textBody),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Verification checklist
          _VerifyScanTile(
            stepNumber: 1,
            title: 'Scan Physical Box QR Code',
            subtitle: 'Confirm this is the correct physical box',
            scannedValue: _scannedBoxQr,
            valueLabel: 'Box',
            onClear: () => setState(() => _scannedBoxQr = null),
            scanner: MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.firstOrNull;
                if (barcode?.rawValue != null) {
                  setState(() {
                    _scannedBoxQr = barcode!.rawValue;
                    _mismatchMessage = null;
                  });
                }
              },
            ),
          ),

          if (_scannedBoxQr != null) ...[
            const SizedBox(height: 16),
            _VerifyScanTile(
              stepNumber: 2,
              title: 'Scan Physical Slot QR Code',
              subtitle: 'Confirm where the box is physically located',
              scannedValue: _scannedSlotQr,
              valueLabel: 'Slot',
              onClear: () => setState(() => _scannedSlotQr = null),
              scanner: MobileScanner(
                onDetect: (capture) {
                  final barcode = capture.barcodes.firstOrNull;
                  if (barcode?.rawValue != null) {
                    setState(() {
                      _scannedSlotQr = barcode!.rawValue;
                      _mismatchMessage = null;
                    });
                  }
                },
              ),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: _isSubmitting
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ElevatedButton.icon(
                    style: _pillButtonStyle,
                    onPressed: _scannedBoxQr == null || _scannedSlotQr == null
                        ? null
                        : _submitReturnWithVerification,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Verify & Complete Return'),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Corner-bracket scan reticle, replaces the plain border overlay.
class _ScanReticle extends StatelessWidget {
  const _ScanReticle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 220,
        height: 140,
        child: Stack(
          children: [
            for (final alignment in [
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomLeft,
              Alignment.bottomRight,
            ])
              Align(
                alignment: alignment,
                child: _ReticleCorner(alignment: alignment),
              ),
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
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
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
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Card used throughout — soft shadow for depth, subtle border to keep the
/// flat, saturated design language rather than heavy material elevation.
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
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: child,
        ),
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

/// Inline warning shown when a scanned box/slot doesn't match expectations.
/// Replaces the old blocking AlertDialog "override" flow: the person just
/// dismisses it and rescans — no override path exists anymore.
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

/// A single numbered scan step used in the verification screen — shows
/// either the live scanner or a confirmed result state.
class _VerifyScanTile extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String subtitle;
  final String? scannedValue;
  final String valueLabel;
  final VoidCallback onClear;
  final Widget scanner;

  const _VerifyScanTile({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.scannedValue,
    required this.valueLabel,
    required this.onClear,
    required this.scanner,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = scannedValue != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppColors.success : AppColors.primary,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : Text('$stepNumber', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 150,
            width: double.infinity,
            color: Colors.black12,
            child: isDone
                ? Container(
                    color: AppColors.success.withValues(alpha: 0.08),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 32),
                        const SizedBox(height: 6),
                        Text('$valueLabel: $scannedValue', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        TextButton(
                          onPressed: onClear,
                          child: Text('Rescan $valueLabel', style: const TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      scanner,
                      const _ScanReticle(),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
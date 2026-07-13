import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/pending_task_card.dart';
import '../widgets/fingerprint_background.dart';
import '../widgets/glass_card.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock list of tasks based on real-world passport custody cases
  final List<Map<String, dynamic>> _allTasks = [
    {
      'id': '1',
      'applicant': 'Abebe Kebede',
      'type': 'Issue Passport',
      'mode': 'issue',
      'priority': 'HIGH',
      'time': 'ETA: 5 mins',
    },
    {
      'id': '2',
      'applicant': 'Sarah Yilma',
      'type': 'Return Custody',
      'mode': 'return',
      'priority': 'HIGH',
      'time': 'ETA: 10 mins',
    },
    {
      'id': '3',
      'applicant': 'Dawit Lemma',
      'type': 'Assign Box',
      'mode': 'assign',
      'priority': 'HIGH',
      'time': 'ETA: 12 mins',
    },
    {
      'id': '4',
      'applicant': 'Fatuma Ahmed',
      'type': 'Issue Passport',
      'mode': 'issue',
      'priority': 'MEDIUM',
      'time': 'ETA: 20 mins',
    },
    {
      'id': '5',
      'applicant': 'Yonas Assefa',
      'type': 'Assign Box',
      'mode': 'assign',
      'priority': 'MEDIUM',
      'time': 'ETA: 25 mins',
    },
    {
      'id': '6',
      'applicant': 'Helen Taye',
      'type': 'Return Custody',
      'mode': 'return',
      'priority': 'MEDIUM',
      'time': 'ETA: 30 mins',
    },
    {
      'id': '7',
      'applicant': 'Zenebech Abera',
      'type': 'Issue Passport',
      'mode': 'issue',
      'priority': 'LOW',
      'time': 'ETA: 45 mins',
    },
    {
      'id': '8',
      'applicant': 'Kidus Solomon',
      'type': 'Assign Box',
      'mode': 'assign',
      'priority': 'LOW',
      'time': 'ETA: 1 hr',
    },
    {
      'id': '9',
      'applicant': 'Marta Hagos',
      'type': 'Return Custody',
      'mode': 'return',
      'priority': 'LOW',
      'time': 'ETA: 1.5 hrs',
    },
    {
      'id': '10',
      'applicant': 'Samuel Tesfaye',
      'type': 'Issue Passport',
      'mode': 'issue',
      'priority': 'LOW',
      'time': 'ETA: 2 hrs',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterTasks(String tab) {
    List<Map<String, dynamic>> list = _allTasks;
    
    // Filter by tab
    if (tab == 'High') {
      list = _allTasks.where((t) => t['priority'] == 'HIGH').toList();
    } else if (tab == 'Medium') {
      list = _allTasks.where((t) => t['priority'] == 'MEDIUM').toList();
    } else if (tab == 'Low') {
      list = _allTasks.where((t) => t['priority'] == 'LOW').toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      list = list.where((t) {
        final name = t['applicant'].toString().toLowerCase();
        final type = t['type'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || type.contains(query);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: FingerprintBackground(
        child: CustomScrollView(
          slivers: [
            // Large Premium Header
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                title: Text(
                  'Today\'s Tasks',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            
            // Search Bar & Priority Tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    // Search Bar
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
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Search applicant name or task type...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textBody, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
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

                    // Priority Tabs Indicator
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textBody.withOpacity(0.6),
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3.0,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, fontFamily: 'Inter'),
                      tabs: const [
                        Tab(text: 'All'),
                        Tab(text: 'High'),
                        Tab(text: 'Medium'),
                        Tab(text: 'Low'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tasks List
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTasksList('All'),
                  _buildTasksList('High'),
                  _buildTasksList('Medium'),
                  _buildTasksList('Low'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList(String tabName) {
    final tasks = _filterTasks(tabName);
    
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.done_all_rounded,
              size: 64,
              color: AppColors.primary.withOpacity(0.15),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Tasks Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 4),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try refining your search terms'
                  : 'All tasks under this category are completed!',
              style: const TextStyle(fontSize: 12, color: AppColors.textBody),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), // padding bottom to avoid floating nav overlap
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: PendingTaskCard(
            applicantName: task['applicant'],
            taskType: task['type'],
            priority: task['priority'],
            timeText: task['time'],
            onTap: () {
              // Route directly to scan screen with correct mode parameters
              context.push('/scan?mode=${task['mode']}');
            },
          ),
        );
      },
    );
  }
}

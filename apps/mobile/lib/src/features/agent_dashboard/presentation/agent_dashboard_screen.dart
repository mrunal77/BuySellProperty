import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../search/data/properties_api.dart';
import '../../../core/browse_widgets.dart';

class AgentDashboardScreen extends ConsumerStatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  ConsumerState<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends ConsumerState<AgentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final props = ref.watch(propertySearchProvider(const PropertyQuery(mine: true, pageSize: 50)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Portal'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(propertySearchProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.business_center), text: 'Listings'),
            Tab(icon: Icon(Icons.mark_email_unread), text: 'Leads'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Visits'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/owner/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Client Listing'),
      ),
      body: Column(
        children: [
          // Agent Header & RERA Badge Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade700,
                      child: const Icon(Icons.verified_user, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Apex Realty Partners',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.verified, color: Colors.blue.shade700, size: 16),
                            ],
                          ),
                          Text(
                            'RERA: PRM/KA/RERA/1251/310/PR/171015/000456',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Verified Agent',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('12', 'Active Listings', Colors.blue.shade900),
                    _statItem('28', 'Total Leads', Colors.green.shade900),
                    _statItem('5', 'Visits Today', Colors.orange.shade900),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Client Listings
                _buildListingsTab(props),
                // TAB 2: Lead Enquiries
                _buildLeadsTab(),
                // TAB 3: Site Visit Calendar
                _buildVisitsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }

  Widget _buildListingsTab(AsyncValue<Map<String, dynamic>> props) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(propertySearchProvider),
      child: props.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => BrowseError(error: e, onRetry: () => ref.invalidate(propertySearchProvider)),
        data: (json) {
          final items = (json['data'] as List).cast<Map<String, dynamic>>();
          if (items.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 60),
              Center(child: Text('No client listings yet. Tap + to publish a listing.')),
            ]);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final p = items[i];
              final status = (p['status'] as String?) ?? 'Active';
              final propId = p['id'].toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(p['title'] ?? 'Untitled Property', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${p['city'] ?? 'Property'} • ₹${p['price'] ?? 0}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'Active' ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: status == 'Active' ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                  ),
                  onTap: () => context.push('/p/$propId'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLeadsTab() {
    final mockLeads = [
      {'name': 'Rajesh Sharma', 'phone': '+91 98765 43210', 'property': ' Luxury 3 BHK Villa in Whitefield', 'status': 'New Lead', 'time': '10 mins ago'},
      {'name': 'Priya Nair', 'phone': '+91 98123 45678', 'property': '2 BHK Apartment in Koramangala', 'status': 'Contacted', 'time': '2 hours ago'},
      {'name': 'Amit Kumar', 'phone': '+91 97654 32109', 'property': 'Commercial Office Space in HSR', 'status': 'Visit Scheduled', 'time': 'Yesterday'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: mockLeads.length,
      itemBuilder: (ctx, i) {
        final lead = mockLeads[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lead['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        lead['status']!,
                        style: TextStyle(fontSize: 10, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(lead['property']!, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(lead['phone']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(lead['time']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisitsTab() {
    final mockVisits = [
      {'client': 'Sunil Verma', 'time': 'Today, 4:00 PM', 'property': '3 BHK Apartment in Indiranagar', 'status': 'Confirmed'},
      {'client': 'Anita Roy', 'time': 'Tomorrow, 11:30 AM', 'property': 'Plot in Devanahalli', 'status': 'Pending'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: mockVisits.length,
      itemBuilder: (ctx, i) {
        final visit = mockVisits[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.event_available, color: Colors.blue.shade900),
            ),
            title: Text(visit['client']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${visit['property']}\nTime: ${visit['time']}'),
            isThreeLine: true,
            trailing: Chip(
              label: Text(visit['status']!, style: const TextStyle(fontSize: 10)),
              backgroundColor: visit['status'] == 'Confirmed' ? Colors.green.shade100 : Colors.orange.shade100,
            ),
          ),
        );
      },
    );
  }
}

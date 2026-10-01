import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../search/data/properties_api.dart';
import '../../../core/browse_widgets.dart';
import '../../../core/validators.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final props = ref.watch(propertySearchProvider(const PropertyQuery(mine: true, pageSize: 50)));
    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/owner/new'),
        icon: const Icon(Icons.add),
        label: const Text('New listing'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(propertySearchProvider),
        child: props.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => BrowseError(error: e, onRetry: () => ref.invalidate(propertySearchProvider)),
          data: (json) {
            final items = (json['data'] as List).cast<Map<String, dynamic>>();
            if (items.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 80),
                Center(child: Text('No listings yet. Tap + to post your first property — it’s free.')),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final p = items[i];
                final published = (p['status'] as String?) == 'Active';
                return Card(
                  child: ListTile(
                    title: Text(p['title'] ?? ''),
                    subtitle: Text("${p['status'] ?? ''} • ${formatINR((p['price'] as num?) ?? 0)}"),
                    trailing: published
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : TextButton(
                            child: const Text('Publish'),
                            onPressed: () async {
                              try {
                                await publishProperty(ref, p['id'].toString());
                                ref.invalidate(propertySearchProvider);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(apiErrorMessage(e, 'Publish failed.'))),
                                  );
                                }
                              }
                            },
                          ),
                    onTap: () => context.push("/p/${p['id']}"),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

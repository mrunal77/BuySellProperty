import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../search/data/properties_api.dart';
import '../../../core/browse_widgets.dart';
import '../../../core/validators.dart';

import '../../../core/network.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final props = ref.watch(propertySearchProvider(const PropertyQuery(mine: true, pageSize: 50)));
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
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
              itemBuilder: (ctx, i) {
                final p = items[i];
                final status = (p['status'] as String?) ?? 'Draft';
                final propId = p['id'].toString();
                final rawImgs = p['imageUrls'] ?? p['image_urls'];
                final imgUrl = (rawImgs is List && rawImgs.isNotEmpty) ? rawImgs.first.toString() : null;

                Color statusBgColor = Colors.orange.shade100;
                Color statusTextColor = Colors.orange.shade900;
                if (status == 'Active') {
                  statusBgColor = Colors.green.shade100;
                  statusTextColor = Colors.green.shade900;
                } else if (status == 'Sold') {
                  statusBgColor = Colors.red.shade100;
                  statusTextColor = Colors.red.shade900;
                } else if (status == 'Rented') {
                  statusBgColor = Colors.blue.shade100;
                  statusTextColor = Colors.blue.shade900;
                } else if (status == 'Paused') {
                  statusBgColor = Colors.grey.shade200;
                  statusTextColor = Colors.grey.shade800;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: Container(
                      width: 54, height: 54,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade200,
                      ),
                      child: imgUrl != null && imgUrl.isNotEmpty
                          ? Image.network(
                              normalizeImageUrl(imgUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.apartment),
                            )
                          : const Icon(Icons.apartment),
                    ),
                    title: Text(p['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusTextColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(formatINR((p['price'] as num?) ?? 0), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) async {
                        try {
                          if (action == 'publish') {
                            await publishProperty(ref, propId);
                          } else if (action == 'sold') {
                            await markPropertySold(ref, propId);
                          } else if (action == 'rented') {
                            await markPropertyRented(ref, propId);
                          } else if (action == 'pause') {
                            await pauseProperty(ref, propId);
                          } else if (action == 'delete') {
                            await deleteProperty(ref, propId);
                          }
                          ref.invalidate(propertySearchProvider);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Listing updated successfully.')),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(apiErrorMessage(e, 'Action failed.'))),
                            );
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        if (status == 'Draft' || status == 'Paused')
                          const PopupMenuItem(value: 'publish', child: Row(children: [Icon(Icons.publish, color: Colors.green, size: 18), SizedBox(width: 8), Text('Publish Listing')])),
                        if (status == 'Active' || status == 'Paused') ...[
                          const PopupMenuItem(value: 'sold', child: Row(children: [Icon(Icons.check_circle_outline, color: Colors.red, size: 18), SizedBox(width: 8), Text('Mark as Sold')])),
                          const PopupMenuItem(value: 'rented', child: Row(children: [Icon(Icons.key, color: Colors.blue, size: 18), SizedBox(width: 8), Text('Mark as Rented')])),
                          const PopupMenuItem(value: 'pause', child: Row(children: [Icon(Icons.pause_circle_outline, color: Colors.grey, size: 18), SizedBox(width: 8), Text('Pause Listing')])),
                        ],
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete Listing')])),
                      ],
                    ),
                    onTap: () => context.push("/p/$propId"),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: 3),
    );
  }
}

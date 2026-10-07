import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../search/data/properties_api.dart';
import '../../../core/browse_widgets.dart';
import '../../../core/validators.dart';

import '../../../core/network.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  static Future<bool> _confirmAction(
    BuildContext context, String action, String propertyTitle,
  ) async {
    String title, message, confirmLabel;
    switch (action) {
      case 'delete':
        title = 'Delete Listing';
        message = 'Are you sure you want to delete "$propertyTitle"? This cannot be undone.';
        confirmLabel = 'Delete';
        break;
      case 'sold':
        title = 'Mark as Sold';
        message = 'Mark "$propertyTitle" as sold? This will hide it from public search.';
        confirmLabel = 'Mark Sold';
        break;
      case 'rented':
        title = 'Mark as Rented';
        message = 'Mark "$propertyTitle" as rented? This will hide it from public search.';
        confirmLabel = 'Mark Rented';
        break;
      case 'pause':
        title = 'Pause Listing';
        message = 'Pause "$propertyTitle"? It will be hidden from public search until republished.';
        confirmLabel = 'Pause';
        break;
      case 'publish':
        title = 'Publish Listing';
        message = 'Publish "$propertyTitle"? It will be visible to buyers.';
        confirmLabel = 'Publish';
        break;
      default:
        return true;
    }
    final result = await showGeneralDialog<bool?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).dialogTheme.titleTextStyle),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: Theme.of(context).dialogTheme.contentTextStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(confirmLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: child,
      ),
    );
    return result ?? false;
  }

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
                        final confirmed = await _confirmAction(ctx, action, p['title'] ?? '');
                        if (!confirmed) return;
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
                          } else if (action == 'edit') {
                            context.push('/owner/edit/$propId');
                            return;
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
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, color: Colors.blue, size: 18), SizedBox(width: 8), Text('Edit Listing')])),
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'validators.dart';

/// Shared browse UI: property cards, section titles, bottom nav.

import 'network.dart';

const _grads = [
  [Color(0xFF006244), Color(0xFF014434)],
  [Color(0xFF0369A1), Color(0xFF312E81)],
  [Color(0xFFF59E0B), Color(0xFFC2410C)],
  [Color(0xFFF43F5E), Color(0xFF9D174D)],
  [Color(0xFF7C3AED), Color(0xFF4C1D95)],
];

List<Color> _gradFor(String id) {
  var h = 0;
  for (final c in id.codeUnits) {
    h = (h * 31 + c) % 997;
  }
  return _grads[h % _grads.length];
}

class PropertyCard extends StatelessWidget {
  final Map<String, dynamic> p;
  final double width;
  const PropertyCard({super.key, required this.p, this.width = 260});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = p['id'].toString();
    final title = (p['title'] ?? '') as String;
    final g = _gradFor(id);

    final rawImages = p['imageUrls'] ?? p['image_urls'];
    List<String> images = [];
    if (rawImages is List) {
      images = rawImages.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }

    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/p/$id'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (images.isNotEmpty)
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          normalizeImageUrl(images.first),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildFallbackHeader(title, g),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                        ),
                      ),
                      if (images.length > 1)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_library, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text('${images.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                _buildFallbackHeader(title, g),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatINR((p['price'] as num?) ?? 0),
                        style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${p['propertyType'] ?? ''}${p['bedrooms'] != null ? ' • ${p['bedrooms']} BHK' : ''} • ${p['areaSqft'] ?? ''} sqft',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackHeader(String title, List<Color> g) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(gradient: LinearGradient(colors: g)),
      child: Center(
        child: CircleAvatar(
          backgroundColor: Colors.white24,
          child: Text(
            title.isEmpty ? 'B' : title[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionTitle({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final int current;
  const AppBottomNav({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: current,
      onDestinationSelected: (i) => context.go(['/home', '/search', '/saved', '/profile'][i]),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
        NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'Saved'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

/// Friendly error block with retry, used by all browse screens.
class BrowseError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const BrowseError({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 8),
            Text(apiErrorMessage(error, 'Could not load properties.'),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

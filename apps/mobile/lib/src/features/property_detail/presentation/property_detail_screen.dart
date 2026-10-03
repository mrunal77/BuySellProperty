import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../search/data/properties_api.dart';
import '../../../core/browse_widgets.dart';
import '../../../core/auth_store.dart';
import '../../../core/network.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const PropertyDetailScreen({super.key, required this.id});

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  int _activeImageIndex = 0;

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Owner Phone Number: $phone')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp Owner Number: $phone')),
        );
      }
    }
  }

  void _showEnquirySheet(BuildContext context, PropertyDto p) {
    final auth = ref.read(authStoreProvider);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to contact property owners.')),
      );
      return;
    }

    final ownerPhone = p.ownerPhone ?? '+91 9876543210';
    final msgCtrl = TextEditingController(text: 'Hi, I am interested in this property. Please contact me.');
    final phoneCtrl = TextEditingController(text: '');
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact Owner for ${p.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Owner Phone Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_circle, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Property Owner Contact', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(ownerPhone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
                            onPressed: () => _makeCall(ownerPhone),
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Call Owner'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                            onPressed: () => _openWhatsApp(ownerPhone),
                            icon: const Icon(Icons.chat, size: 18),
                            label: const Text('WhatsApp'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('OR SEND MESSAGE', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Your Contact Phone', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          setSheetState(() => sending = true);
                          try {
                            await createEnquiry(ref, p.id, msgCtrl.text, phoneCtrl.text);
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Enquiry sent successfully!')),
                              );
                            }
                          } catch (e) {
                            setSheetState(() => sending = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to send enquiry: $e')),
                            );
                          }
                        },
                  child: sending ? const CircularProgressIndicator(color: Colors.white) : const Text('Send Enquiry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVisitSheet(BuildContext context, PropertyDto p) {
    final auth = ref.read(authStoreProvider);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to schedule site visits.')),
      );
      return;
    }

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final notesCtrl = TextEditingController();
    bool scheduling = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Schedule Visit for ${p.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date & Time'),
                subtitle: Text(selectedDate.toString().substring(0, 16)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDate),
                    );
                    if (pickedTime != null) {
                      setSheetState(() {
                        selectedDate = DateTime(
                          pickedDate.year, pickedDate.month, pickedDate.day,
                          pickedTime.hour, pickedTime.minute,
                        );
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes / Special Requests', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: scheduling
                      ? null
                      : () async {
                          setSheetState(() => scheduling = true);
                          try {
                            await scheduleSiteVisit(ref, p.id, selectedDate, notesCtrl.text);
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Site visit scheduled successfully!')),
                              );
                            }
                          } catch (e) {
                            setSheetState(() => scheduling = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to schedule visit: $e')),
                            );
                          }
                        },
                  child: scheduling ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm Schedule'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(propertyDetailProvider(widget.id));
    final favsAsync = ref.watch(favoritesProvider);
    final isFav = favsAsync.asData?.value.any((f) => f.id == widget.id) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
            onPressed: () => toggleFavorite(ref, widget.id, isFav),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => BrowseError(error: e, onRetry: () => ref.invalidate(propertyDetailProvider(widget.id))),
        data: (p) {
          final images = p.imageUrls;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image gallery header
                SizedBox(
                  height: 250,
                  child: images.isNotEmpty
                      ? Stack(
                          children: [
                            PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (i) => setState(() => _activeImageIndex = i),
                              itemBuilder: (ctx, i) => Image.network(
                                normalizeImageUrl(images[i]),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300, child: const Icon(Icons.apartment, size: 64)),
                              ),
                            ),
                            if (images.length > 1)
                              Positioned(
                                bottom: 12, right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                                  child: Text('${_activeImageIndex + 1}/${images.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          width: double.infinity,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.apartment, size: 80),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(6)),
                            child: Text(p.listingType, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                            child: Text(p.propertyType, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(p.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      if (p.addressLine != null) Text('📍 ${p.addressLine}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),

                      const SizedBox(height: 16),
                      Text('₹${p.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),

                      const SizedBox(height: 16),
                      // Spec Chips Grid
                      Row(
                        children: [
                          _specCard('Area', '${p.areaSqft.toStringAsFixed(0)} sqft'),
                          _specCard('Bedrooms', p.bedrooms != null ? '${p.bedrooms} BHK' : '—'),
                          _specCard('Bathrooms', p.bathrooms != null ? '${p.bathrooms} Baths' : '—'),
                        ],
                      ),

                      if (p.amenities.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: p.amenities.map((a) => Chip(avatar: const Icon(Icons.star, size: 14), label: Text(a))).toList(),
                        ),
                      ],

                      if (p.description != null && p.description!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(p.description!, style: const TextStyle(fontSize: 14, height: 1.4)),
                      ],

                      const SizedBox(height: 16),
                      // Verified Agent RERA Badge Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade700,
                              child: const Icon(Icons.verified_user, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Apex Realty (Verified Agent)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                      const SizedBox(width: 4),
                                      Icon(Icons.verified, color: Colors.blue.shade700, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('RERA: PRM/KA/RERA/1251/310/PR/171015/000456', style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _showEnquirySheet(context, p),
                              icon: const Icon(Icons.phone),
                              label: const Text('Contact Owner'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showVisitSheet(context, p),
                              icon: const Icon(Icons.event),
                              label: const Text('Schedule Visit'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _specCard(String title, String val) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/properties_api.dart';
import '../data/recent_searches_store.dart';
import '../../listing_editor/domain/property_type_config.dart';
import '../../../core/browse_widgets.dart';
import '../../../core/network.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialKeyword;
  final String? initialListingType;
  final String? initialType;
  final String? initialCityId;
  final String? initialCityName;

  const SearchScreen({
    super.key,
    this.initialKeyword,
    this.initialListingType,
    this.initialType,
    this.initialCityId,
    this.initialCityName,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _keywordController;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  bool _isSearchFocused = false;

  late String? _listingType = widget.initialListingType;
  late PropertyType? _propertyType = PropertyType.tryFromApi(widget.initialType);
  late String? _cityId = widget.initialCityId;
  late String? _cityName = widget.initialCityName;
  late String? _keyword = widget.initialKeyword;

  String? _localityId;
  String? _localityName;
  double? _minPrice;
  double? _maxPrice;
  double? _minArea;
  double? _maxArea;
  int? _beds;
  int? _baths;
  String? _furnishing;
  String? _facing;
  int? _postedWithinDays;
  final Set<String> _selectedAmenities = {};
  String _sort = 'newest';

  // Pagination state
  int _currentPage = 1;
  final List<Map<String, dynamic>> _accumulatedProperties = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController(text: widget.initialKeyword);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_keyword != null && _keyword!.isNotEmpty) {
        ref.read(recentSearchesProvider.notifier).addSearch(_keyword!);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _keywordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadNextPage();
    }
  }

  PropertyQuery _buildCurrentQuery({int page = 1}) {
    return PropertyQuery(
      keyword: _keyword,
      listingType: _listingType,
      cityId: _cityId,
      city: _cityId == null ? _cityName : null,
      localityId: _localityId,
      locality: _localityId == null ? _localityName : null,
      type: _propertyType?.apiValue,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minArea: _minArea,
      maxArea: _maxArea,
      beds: _beds,
      baths: _baths,
      furnishing: _furnishing != null ? furnishingToApi(_furnishing!) : null,
      facing: _facing,
      postedWithinDays: _postedWithinDays,
      amenities: _selectedAmenities.isNotEmpty ? _selectedAmenities.toList() : null,
      page: page,
      pageSize: 20,
      sort: _sort,
    );
  }

  void _resetPagination() {
    setState(() {
      _currentPage = 1;
      _accumulatedProperties.clear();
      _hasMore = true;
      _isLoadingMore = false;
    });
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;
    final query = _buildCurrentQuery(page: nextPage);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/properties', queryParameters: query.toMap());
      final data = res.data as Map<String, dynamic>;
      final newItems = (data['data'] as List).cast<Map<String, dynamic>>();
      final total = (data['total'] as num?)?.toInt() ?? 0;

      setState(() {
        _currentPage = nextPage;
        _accumulatedProperties.addAll(newItems);
        _totalCount = total;
        _isLoadingMore = false;
        if (_accumulatedProperties.length >= total || newItems.isEmpty) {
          _hasMore = false;
        }
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onKeywordChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _keyword = val.trim().isEmpty ? null : val.trim();
      });
      _resetPagination();
      if (_keyword != null && _keyword!.isNotEmpty) {
        ref.read(recentSearchesProvider.notifier).addSearch(_keyword!);
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _keywordController.clear();
      _keyword = null;
      _listingType = null;
      _propertyType = null;
      _cityId = null;
      _cityName = null;
      _localityId = null;
      _localityName = null;
      _minPrice = null;
      _maxPrice = null;
      _minArea = null;
      _maxArea = null;
      _beds = null;
      _baths = null;
      _furnishing = null;
      _facing = null;
      _postedWithinDays = null;
      _selectedAmenities.clear();
      _sort = 'newest';
    });
    _resetPagination();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_listingType != null) count++;
    if (_propertyType != null) count++;
    if (_cityId != null || _cityName != null) count++;
    if (_localityId != null || _localityName != null) count++;
    if (_minPrice != null || _maxPrice != null) count++;
    if (_minArea != null || _maxArea != null) count++;
    if (_beds != null) count++;
    if (_baths != null) count++;
    if (_furnishing != null) count++;
    if (_facing != null) count++;
    if (_postedWithinDays != null) count++;
    if (_selectedAmenities.isNotEmpty) count += _selectedAmenities.length;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final query = _buildCurrentQuery(page: 1);
    final initialAsync = ref.watch(propertySearchProvider(query));
    final recentSearches = ref.watch(recentSearchesProvider);
    final savedSearches = ref.watch(savedSearchesProvider);
    final citiesAsync = ref.watch(citiesProvider);
    final cities = citiesAsync.valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Properties'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            tooltip: 'Save Search',
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () => _promptSaveSearch(context, query),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Focus(
              onFocusChange: (focused) => setState(() => _isSearchFocused = focused),
              child: TextField(
                controller: _keywordController,
                onChanged: _onKeywordChanged,
                decoration: InputDecoration(
                  hintText: 'Search locality, city or keyword (e.g. 2 BHK Nagpur)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _keywordController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _keywordController.clear();
                            _onKeywordChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // Show Recent & Saved Searches when search box focused
          if (_isSearchFocused || (_keywordController.text.isEmpty && _accumulatedProperties.isEmpty && initialAsync.valueOrNull == null))
            _buildRecentAndSavedSearches(recentSearches, savedSearches),

          // Horizontal Active Filter Bar
          _buildActiveFilterBar(context, cities),

          const Divider(height: 1),

          // Results Header & Count
          initialAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) {
              final total = (data['total'] as num?)?.toInt() ?? 0;

              // Initialize page 1 properties if not loaded yet
              if (_currentPage == 1 && _accumulatedProperties.isEmpty) {
                final page1Items = (data['data'] as List).cast<Map<String, dynamic>>();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _accumulatedProperties.clear();
                    _accumulatedProperties.addAll(page1Items);
                    _totalCount = total;
                    if (_accumulatedProperties.length >= total) {
                      _hasMore = false;
                    }
                  });
                });
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '$_totalCount Properties Found',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.sort, size: 18),
                      label: Text('Sort: ${_sortLabel(_sort)}'),
                      onPressed: () => _showSortSheet(context),
                    ),
                  ],
                ),
              );
            },
          ),

          // Properties Listing & Infinite Scroll
          Expanded(
            child: initialAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => BrowseError(
                error: e,
                onRetry: () {
                  ref.invalidate(propertySearchProvider);
                  _resetPagination();
                },
              ),
              data: (data) {
                if (_accumulatedProperties.isEmpty) {
                  return _buildEmptyResultsState(context);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _resetPagination();
                    ref.invalidate(propertySearchProvider);
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _accumulatedProperties.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, index) {
                      if (index == _accumulatedProperties.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PropertyCard(
                          p: _accumulatedProperties[index],
                          width: double.infinity,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(current: 1),
    );
  }

  // Active Filter Bar
  Widget _buildActiveFilterBar(BuildContext context, List<CityDto> cities) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Filter BottomSheet Button with Badge
          Badge(
            isLabelVisible: _activeFilterCount > 0,
            label: Text('$_activeFilterCount'),
            child: ActionChip(
              avatar: const Icon(Icons.tune, size: 16),
              label: const Text('Filters'),
              onPressed: () => _showFilterSheet(context, cities),
            ),
          ),
          const SizedBox(width: 8),

          // Listing Type Chips
          _quickChip('Buy', _listingType == 'Sale', () {
            setState(() => _listingType = _listingType == 'Sale' ? null : 'Sale');
            _resetPagination();
          }),
          _quickChip('Rent', _listingType == 'Rent', () {
            setState(() => _listingType = _listingType == 'Rent' ? null : 'Rent');
            _resetPagination();
          }),

          // Property Type Filter Chip
          if (_propertyType != null)
            _activeChip('Type: ${_propertyType!.label}', () {
              setState(() => _propertyType = null);
              _resetPagination();
            }),

          // City Filter Chip
          if (_cityName != null || _cityId != null)
            _activeChip('City: ${_cityName ?? "Selected"}', () {
              setState(() {
                _cityId = null;
                _cityName = null;
              });
              _resetPagination();
            }),

          // Price Filter Chip
          if (_minPrice != null || _maxPrice != null)
            _activeChip(_priceFilterLabel(), () {
              setState(() {
                _minPrice = null;
                _maxPrice = null;
              });
              _resetPagination();
            }),

          // BHK Filter Chip
          if (_beds != null)
            _activeChip('$_beds+ BHK', () {
              setState(() => _beds = null);
              _resetPagination();
            }),

          // Amenities Filter Chip
          if (_selectedAmenities.isNotEmpty)
            _activeChip('${_selectedAmenities.length} Amenities', () {
              setState(() => _selectedAmenities.clear());
              _resetPagination();
            }),

          if (_activeFilterCount > 0 || _keyword != null)
            TextButton(
              onPressed: _clearAllFilters,
              child: const Text('Clear All'),
            ),
        ],
      ),
    );
  }

  Widget _quickChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onDeleted) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InputChip(
        label: Text(label),
        selected: true,
        onDeleted: onDeleted,
      ),
    );
  }

  String _priceFilterLabel() {
    if (_minPrice != null && _maxPrice != null) {
      return '₹${_formatAmount(_minPrice!)} - ₹${_formatAmount(_maxPrice!)}';
    } else if (_minPrice != null) {
      return '> ₹${_formatAmount(_minPrice!)}';
    } else if (_maxPrice != null) {
      return '< ₹${_formatAmount(_maxPrice!)}';
    }
    return 'Price';
  }

  String _formatAmount(double amt) {
    if (amt >= 10000000) return '${(amt / 10000000).toStringAsFixed(2)} Cr';
    if (amt >= 100000) return '${(amt / 100000).toStringAsFixed(1)} L';
    if (amt >= 1000) return '${(amt / 1000).toStringAsFixed(0)}K';
    return amt.toStringAsFixed(0);
  }

  String _sortLabel(String key) {
    return switch (key) {
      'price_asc' => 'Price: Low to High',
      'price_desc' => 'Price: High to Low',
      'area_asc' => 'Area: Low to High',
      'area_desc' => 'Area: High to Low',
      _ => 'Newest',
    };
  }

  // Recent & Saved Searches Widget
  Widget _buildRecentAndSavedSearches(
    List<String> recent,
    List<SavedSearchItem> saved,
  ) {
    if (recent.isEmpty && saved.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recent.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.history, size: 18),
                const SizedBox(width: 6),
                const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                TextButton(
                  onPressed: () => ref.read(recentSearchesProvider.notifier).clearAll(),
                  child: const Text('Clear All', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: recent.map((term) {
                return Chip(
                  label: Text(term, style: const TextStyle(fontSize: 12)),
                  onDeleted: () => ref.read(recentSearchesProvider.notifier).removeSearch(term),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
          if (saved.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.bookmark, size: 18),
                const SizedBox(width: 6),
                const Text('Saved Searches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: saved.map((item) {
                return ActionChip(
                  avatar: const Icon(Icons.search, size: 14),
                  label: Text(item.title, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _keyword = item.query.keyword;
                      _keywordController.text = item.query.keyword ?? '';
                      _listingType = item.query.listingType;
                      _cityId = item.query.cityId;
                      _cityName = item.query.city;
                      _propertyType = PropertyType.tryFromApi(item.query.type);
                      _minPrice = item.query.minPrice;
                      _maxPrice = item.query.maxPrice;
                      _beds = item.query.beds;
                      _isSearchFocused = false;
                    });
                    _resetPagination();
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // Empty Results State
  Widget _buildEmptyResultsState(BuildContext context) {
    final activeCityLabel = _cityName ?? 'selected city';
    final recsAsync = ref.watch(propertySearchProvider(const PropertyQuery(pageSize: 10)));

    final titleText = (_cityName != null || _cityId != null)
        ? 'No properties found in $activeCityLabel'
        : 'No properties match your current filters';

    final subText = (_cityName != null || _cityId != null)
        ? 'There are currently no active listings available in $activeCityLabel matching your search.'
        : 'Try increasing your price range, clearing some filters, or searching another location.';

    return RefreshIndicator(
      onRefresh: () async {
        _clearAllFilters();
        ref.invalidate(propertySearchProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  (_cityName != null || _cityId != null) ? Icons.location_off_outlined : Icons.search_off,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  titleText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  subText,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Clear All Filters'),
                  onPressed: _clearAllFilters,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.stars, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('Recommended Properties from Other Cities',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          recsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (recJson) {
              final items = (recJson['data'] as List).cast<Map<String, dynamic>>();
              final otherCityRecs = items.where((p) {
                if (_cityId != null && p['cityId']?.toString() == _cityId) return false;
                if (_cityName != null && p['city']?.toString().toLowerCase() == _cityName!.toLowerCase()) return false;
                return true;
              }).toList();

              if (otherCityRecs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No recommendations available at this time.')),
                );
              }

              return Column(
                children: otherCityRecs
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PropertyCard(p: p, width: double.infinity),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Filter BottomSheet
  void _showFilterSheet(BuildContext context, List<CityDto> cities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterBottomSheet(
        listingType: _listingType,
        propertyType: _propertyType,
        cityId: _cityId,
        cityName: _cityName,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minArea: _minArea,
        maxArea: _maxArea,
        beds: _beds,
        baths: _baths,
        furnishing: _furnishing,
        facing: _facing,
        postedWithinDays: _postedWithinDays,
        selectedAmenities: Set.from(_selectedAmenities),
        cities: cities,
        onApply: (updated) {
          setState(() {
            _listingType = updated.listingType;
            _propertyType = updated.propertyType;
            _cityId = updated.cityId;
            _cityName = updated.cityName;
            _minPrice = updated.minPrice;
            _maxPrice = updated.maxPrice;
            _minArea = updated.minArea;
            _maxArea = updated.maxArea;
            _beds = updated.beds;
            _baths = updated.baths;
            _furnishing = updated.furnishing;
            _facing = updated.facing;
            _postedWithinDays = updated.postedWithinDays;
            _selectedAmenities.clear();
            _selectedAmenities.addAll(updated.selectedAmenities);
          });
          _resetPagination();
        },
      ),
    );
  }

  // Sort BottomSheet
  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort Properties By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _sortOption('Newest Listings', 'newest'),
            _sortOption('Price: Low to High', 'price_asc'),
            _sortOption('Price: High to Low', 'price_desc'),
            _sortOption('Area: Low to High', 'area_asc'),
            _sortOption('Area: High to Low', 'area_desc'),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(String label, String key) {
    final selected = _sort == key;
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      trailing: selected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      onTap: () {
        setState(() => _sort = key);
        Navigator.pop(context);
        _resetPagination();
      },
    );
  }

  void _promptSaveSearch(BuildContext context, PropertyQuery q) {
    final nameCtrl = TextEditingController(text: _keyword ?? _cityName ?? 'My Custom Search');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Search'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Search Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(savedSearchesProvider.notifier).saveSearch(nameCtrl.text, q);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search saved successfully!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _FilterResultData {
  final String? listingType;
  final PropertyType? propertyType;
  final String? cityId;
  final String? cityName;
  final double? minPrice;
  final double? maxPrice;
  final double? minArea;
  final double? maxArea;
  final int? beds;
  final int? baths;
  final String? furnishing;
  final String? facing;
  final int? postedWithinDays;
  final Set<String> selectedAmenities;

  _FilterResultData({
    this.listingType,
    this.propertyType,
    this.cityId,
    this.cityName,
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.beds,
    this.baths,
    this.furnishing,
    this.facing,
    this.postedWithinDays,
    required this.selectedAmenities,
  });
}

class _FilterBottomSheet extends StatefulWidget {
  final String? listingType;
  final PropertyType? propertyType;
  final String? cityId;
  final String? cityName;
  final double? minPrice;
  final double? maxPrice;
  final double? minArea;
  final double? maxArea;
  final int? beds;
  final int? baths;
  final String? furnishing;
  final String? facing;
  final int? postedWithinDays;
  final Set<String> selectedAmenities;
  final List<CityDto> cities;
  final ValueChanged<_FilterResultData> onApply;

  const _FilterBottomSheet({
    this.listingType,
    this.propertyType,
    this.cityId,
    this.cityName,
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.beds,
    this.baths,
    this.furnishing,
    this.facing,
    this.postedWithinDays,
    required this.selectedAmenities,
    required this.cities,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String? _listingType = widget.listingType;
  late PropertyType? _propertyType = widget.propertyType;
  late String? _cityId = widget.cityId;
  late String? _cityName = widget.cityName;
  late double? _minPrice = widget.minPrice;
  late double? _maxPrice = widget.maxPrice;
  late double? _minArea = widget.minArea;
  late double? _maxArea = widget.maxArea;
  late int? _beds = widget.beds;
  late int? _baths = widget.baths;
  late String? _furnishing = widget.furnishing;
  late String? _facing = widget.facing;
  late int? _postedWithinDays = widget.postedWithinDays;
  late final Set<String> _selectedAmenities = Set.from(widget.selectedAmenities);

  late final TextEditingController _minPriceCtrl;
  late final TextEditingController _maxPriceCtrl;
  late final TextEditingController _minAreaCtrl;
  late final TextEditingController _maxAreaCtrl;

  @override
  void initState() {
    super.initState();
    _minPriceCtrl = TextEditingController(text: _minPrice != null ? _minPrice!.toStringAsFixed(0) : '');
    _maxPriceCtrl = TextEditingController(text: _maxPrice != null ? _maxPrice!.toStringAsFixed(0) : '');
    _minAreaCtrl = TextEditingController(text: _minArea != null ? _minArea!.toStringAsFixed(0) : '');
    _maxAreaCtrl = TextEditingController(text: _maxArea != null ? _maxArea!.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _minAreaCtrl.dispose();
    _maxAreaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = PropertySearchFilterConfig.forType(_propertyType);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _listingType = null;
                      _propertyType = null;
                      _cityId = null;
                      _cityName = null;
                      _minPrice = null;
                      _maxPrice = null;
                      _minArea = null;
                      _maxArea = null;
                      _beds = null;
                      _baths = null;
                      _furnishing = null;
                      _facing = null;
                      _postedWithinDays = null;
                      _selectedAmenities.clear();
                      _minPriceCtrl.clear();
                      _maxPriceCtrl.clear();
                      _minAreaCtrl.clear();
                      _maxAreaCtrl.clear();
                    });
                  },
                  child: const Text('Reset'),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Filter Sections
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Listing Type (Buy / Rent)
                _sectionHeader('Listing Type'),
                Row(
                  children: [
                    _filterChip('All', _listingType == null, () => setState(() => _listingType = null)),
                    const SizedBox(width: 8),
                    _filterChip('Buy', _listingType == 'Sale', () => setState(() => _listingType = 'Sale')),
                    const SizedBox(width: 8),
                    _filterChip('Rent', _listingType == 'Rent', () => setState(() => _listingType = 'Rent')),
                  ],
                ),
                const SizedBox(height: 20),

                // City Selector
                if (widget.cities.isNotEmpty) ...[
                  _sectionHeader('Location'),
                  DropdownButtonFormField<String?>(
                    initialValue: _cityId,
                    decoration: const InputDecoration(
                      labelText: 'Select City',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All Cities')),
                      ...widget.cities.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _cityId = val;
                        _cityName = val != null ? widget.cities.where((c) => c.id == val).firstOrNull?.name : null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Property Type Selector
                _sectionHeader('Property Type'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PropertyType.values.map((pt) {
                    final selected = _propertyType == pt;
                    return ChoiceChip(
                      label: Text(pt.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _propertyType = selected ? null : pt),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // BHK Configuration (Residential)
                if (config.showBhk) ...[
                  _sectionHeader('BHK Configuration'),
                  Wrap(
                    spacing: 8,
                    children: [1, 2, 3, 4, 5].map((numBhk) {
                      final selected = _beds == numBhk;
                      return ChoiceChip(
                        label: Text('$numBhk BHK'),
                        selected: selected,
                        onSelected: (_) => setState(() => _beds = selected ? null : numBhk),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Price Range & Presets
                _sectionHeader('Price Range (₹)'),
                if (_listingType == 'Rent') ...[
                  Wrap(
                    spacing: 8,
                    children: [
                      _pricePreset('Up to ₹10K', null, 10000),
                      _pricePreset('₹10K - ₹20K', 10000, 20000),
                      _pricePreset('₹20K - ₹35K', 20000, 35000),
                      _pricePreset('₹35K+', 35000, null),
                    ],
                  ),
                ] else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _pricePreset('Under ₹30L', null, 3000000),
                      _pricePreset('₹30L - ₹60L', 3000000, 6000000),
                      _pricePreset('₹60L - ₹1Cr', 6000000, 10000000),
                      _pricePreset('₹1Cr - ₹2Cr', 10000000, 20000000),
                      _pricePreset('₹2Cr+', 20000000, null),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Min Price (₹)', border: OutlineInputBorder()),
                        onChanged: (v) => _minPrice = double.tryParse(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max Price (₹)', border: OutlineInputBorder()),
                        onChanged: (v) => _maxPrice = double.tryParse(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Area Range
                _sectionHeader('Area Range (sq.ft)'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAreaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Min Area (sqft)', border: OutlineInputBorder()),
                        onChanged: (v) => _minArea = double.tryParse(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxAreaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max Area (sqft)', border: OutlineInputBorder()),
                        onChanged: (v) => _maxArea = double.tryParse(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Furnishing
                if (config.showFurnishing) ...[
                  _sectionHeader('Furnishing'),
                  Wrap(
                    spacing: 8,
                    children: ['Unfurnished', 'Semi Furnished', 'Furnished'].map((f) {
                      final selected = _furnishing == f;
                      return ChoiceChip(
                        label: Text(f),
                        selected: selected,
                        onSelected: (_) => setState(() => _furnishing = selected ? null : f),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Facing
                if (config.showFacing) ...[
                  _sectionHeader('Facing'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: ['East', 'West', 'North', 'South', 'North East', 'North West'].map((fc) {
                      final selected = _facing == fc;
                      return ChoiceChip(
                        label: Text(fc),
                        selected: selected,
                        onSelected: (_) => setState(() => _facing = selected ? null : fc),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Posted Within
                _sectionHeader('Posted Within'),
                Wrap(
                  spacing: 8,
                  children: [
                    _postedChip('Any Time', null),
                    _postedChip('Today', 1),
                    _postedChip('Last 7 Days', 7),
                    _postedChip('Last 30 Days', 30),
                  ],
                ),
                const SizedBox(height: 20),

                // Amenities Filter
                if (config.showAmenities) ...[
                  _sectionHeader('Amenities'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableAmenities.map((amenity) {
                      final selected = _selectedAmenities.contains(amenity);
                      return FilterChip(
                        label: Text(amenity),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedAmenities.add(amenity);
                            } else {
                              _selectedAmenities.remove(amenity);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Sticky Bottom Apply Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  widget.onApply(_FilterResultData(
                    listingType: _listingType,
                    propertyType: _propertyType,
                    cityId: _cityId,
                    cityName: _cityName,
                    minPrice: _minPrice,
                    maxPrice: _maxPrice,
                    minArea: _minArea,
                    maxArea: _maxArea,
                    beds: _beds,
                    baths: _baths,
                    furnishing: _furnishing,
                    facing: _facing,
                    postedWithinDays: _postedWithinDays,
                    selectedAmenities: _selectedAmenities,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _postedChip(String label, int? days) {
    final selected = _postedWithinDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _postedWithinDays = days),
    );
  }

  Widget _pricePreset(String label, double? min, double? max) {
    final selected = _minPrice == min && _maxPrice == max;
    return ActionChip(
      label: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      backgroundColor: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      onPressed: () {
        setState(() {
          _minPrice = min;
          _maxPrice = max;
          _minPriceCtrl.text = min != null ? min.toStringAsFixed(0) : '';
          _maxPriceCtrl.text = max != null ? max.toStringAsFixed(0) : '';
        });
      },
    );
  }
}

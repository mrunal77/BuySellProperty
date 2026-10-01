import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network.dart';

class PropertyDto {
  final String id, title, propertyType, listingType, status;
  final double price, areaSqft;
  final int? bedrooms, bathrooms;
  PropertyDto.fromJson(Map<String, dynamic> j)
      : id = j['id'].toString(), title = j['title'] ?? '',
        propertyType = j['propertyType'] ?? '', listingType = j['listingType'] ?? '',
        status = j['status'] ?? '', price = (j['price'] as num).toDouble(),
        areaSqft = (j['areaSqft'] as num).toDouble(),
        bedrooms = j['bedrooms'], bathrooms = j['bathrooms'];

  factory PropertyDto.fromMap(Map<String, dynamic> j) => PropertyDto.fromJson(j);
}

/// Value-type search query (stable ==/hashCode so Riverpod caches correctly).
class PropertyQuery {
  final String? listingType;
  final String? cityId;
  final String? type;
  final int? beds;
  final double? maxPrice;
  final int page;
  final int pageSize;
  final bool mine;
  final String sort;
  const PropertyQuery({
    this.listingType, this.cityId, this.type, this.beds, this.maxPrice,
    this.page = 1, this.pageSize = 20, this.mine = false, this.sort = 'newest',
  });

  Map<String, dynamic> toMap() => {
    if (listingType != null) 'listingType': listingType,
    if (cityId != null) 'cityId': cityId,
    if (type != null) 'type': type,
    if (beds != null) 'beds': beds,
    if (maxPrice != null) 'maxPrice': maxPrice,
    'sort': sort, 'page': page, 'pageSize': pageSize,
    if (mine) 'mine': true,
  };

  @override
  bool operator ==(Object other) =>
      other is PropertyQuery &&
      other.listingType == listingType && other.cityId == cityId && other.type == type &&
      other.beds == beds && other.maxPrice == maxPrice && other.page == page &&
      other.pageSize == pageSize && other.mine == mine && other.sort == sort;

  @override
  int get hashCode => Object.hash(listingType, cityId, type, beds, maxPrice, page, pageSize, mine, sort);
}

final propertySearchProvider = FutureProvider.family<Map<String, dynamic>, PropertyQuery>((ref, q) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/v1/properties', queryParameters: q.toMap());
  return res.data as Map<String, dynamic>;
});

final propertyDetailProvider = FutureProvider.family<PropertyDto, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/v1/properties/$id');
  return PropertyDto.fromJson(res.data);
});

Future<void> publishProperty(WidgetRef ref, String id) async {
  await ref.read(dioProvider).post('/api/v1/properties/$id/publish');
}

Future<void> createProperty(WidgetRef ref, Map<String, dynamic> body) async {
  await ref.read(dioProvider).post('/api/v1/properties', data: body);
}

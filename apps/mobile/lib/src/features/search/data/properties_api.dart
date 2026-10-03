import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network.dart';

class PropertyDto {
  final String id, title, propertyType, listingType, status;
  final String? description, addressLine, cityId, furnishing, ownerPhone, ownerEmail;
  final double price, areaSqft;
  final double? latitude, longitude;
  final int? bedrooms, bathrooms;
  final List<String> imageUrls;
  final List<String> amenities;

  PropertyDto.fromJson(Map<String, dynamic> j)
      : id = j['id'].toString(),
        title = j['title'] ?? '',
        description = j['description'],
        addressLine = j['addressLine'],
        cityId = j['cityId']?.toString(),
        furnishing = j['furnishing'],
        ownerPhone = j['ownerPhone']?.toString() ?? '+91 9876543210',
        ownerEmail = j['ownerEmail']?.toString() ?? 'owner@buysellproperty.com',
        propertyType = j['propertyType'] ?? '',
        listingType = j['listingType'] ?? '',
        status = j['status'] ?? '',
        price = (j['price'] as num).toDouble(),
        areaSqft = (j['areaSqft'] as num).toDouble(),
        latitude = j['latitude'] != null ? (j['latitude'] as num).toDouble() : null,
        longitude = j['longitude'] != null ? (j['longitude'] as num).toDouble() : null,
        bedrooms = j['bedrooms'],
        bathrooms = j['bathrooms'],
        imageUrls = (j['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
        amenities = (j['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [];

  factory PropertyDto.fromMap(Map<String, dynamic> j) => PropertyDto.fromJson(j);
}

class AmenityDto {
  final String id, name, icon, category;
  AmenityDto.fromJson(Map<String, dynamic> j)
      : id = j['id'].toString(),
        name = j['name'] ?? '',
        icon = j['icon'] ?? '',
        category = j['category'] ?? '';
}

class EnquiryDto {
  final String id, propertyId, propertyTitle, buyerId, ownerId, message, contactPhone, status, createdAt;
  EnquiryDto.fromJson(Map<String, dynamic> j)
      : id = j['id'].toString(),
        propertyId = j['propertyId'].toString(),
        propertyTitle = j['propertyTitle'] ?? '',
        buyerId = j['buyerId'].toString(),
        ownerId = j['ownerId'].toString(),
        message = j['message'] ?? '',
        contactPhone = j['contactPhone'] ?? '',
        status = j['status'] ?? '',
        createdAt = j['createdAt'] ?? '';
}

class SiteVisitDto {
  final String id, propertyId, propertyTitle, buyerId, ownerId, scheduledAt, status, createdAt;
  final String? notes;
  SiteVisitDto.fromJson(Map<String, dynamic> j)
      : id = j['id'].toString(),
        propertyId = j['propertyId'].toString(),
        propertyTitle = j['propertyTitle'] ?? '',
        buyerId = j['buyerId'].toString(),
        ownerId = j['ownerId'].toString(),
        scheduledAt = j['scheduledAt'] ?? '',
        status = j['status'] ?? '',
        notes = j['notes'],
        createdAt = j['createdAt'] ?? '';
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

final favoritesProvider = FutureProvider<List<PropertyDto>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/v1/favorites');
  return (res.data as List).map((j) => PropertyDto.fromJson(j)).toList();
});

final masterAmenitiesProvider = FutureProvider<List<AmenityDto>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/v1/amenities');
  return (res.data as List).map((j) => AmenityDto.fromJson(j)).toList();
});

final myEnquiriesProvider = FutureProvider.family<List<EnquiryDto>, bool>((ref, mine) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/v1/enquiries', queryParameters: {'mine': mine});
  return (res.data as List).map((j) => EnquiryDto.fromJson(j)).toList();
});

final mySiteVisitsProvider = FutureProvider.family<List<SiteVisitDto>, bool>((ref, mine) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/v1/site-visits', queryParameters: {'mine': mine});
  return (res.data as List).map((j) => SiteVisitDto.fromJson(j)).toList();
});

Future<void> toggleFavorite(WidgetRef ref, String propertyId, bool isFav) async {
  final dio = ref.read(dioProvider);
  if (isFav) {
    await dio.delete('/api/v1/favorites/$propertyId');
  } else {
    await dio.post('/api/v1/favorites', data: {'propertyId': propertyId});
  }
  ref.invalidate(favoritesProvider);
}

Future<void> publishProperty(WidgetRef ref, String id) async {
  await ref.read(dioProvider).post('/api/v1/properties/$id/publish');
}

Future<void> markPropertySold(WidgetRef ref, String id) async {
  await ref.read(dioProvider).post('/api/v1/properties/$id/mark-sold');
}

Future<void> markPropertyRented(WidgetRef ref, String id) async {
  await ref.read(dioProvider).post('/api/v1/properties/$id/mark-rented');
}

Future<void> pauseProperty(WidgetRef ref, String id) async {
  await ref.read(dioProvider).post('/api/v1/properties/$id/pause');
}

Future<void> deleteProperty(WidgetRef ref, String id) async {
  await ref.read(dioProvider).delete('/api/v1/properties/$id');
}

Future<void> createProperty(WidgetRef ref, Map<String, dynamic> body) async {
  await ref.read(dioProvider).post('/api/v1/properties', data: body);
}

Future<void> createEnquiry(WidgetRef ref, String propertyId, String message, String phone) async {
  await ref.read(dioProvider).post('/api/v1/enquiries', data: {
    'propertyId': propertyId,
    'message': message,
    'contactPhone': phone,
  });
  ref.invalidate(myEnquiriesProvider(false));
}

Future<void> scheduleSiteVisit(WidgetRef ref, String propertyId, DateTime date, String? notes) async {
  await ref.read(dioProvider).post('/api/v1/site-visits', data: {
    'propertyId': propertyId,
    'scheduledAt': date.toUtc().toIso8601String(),
    'notes': notes,
  });
  ref.invalidate(mySiteVisitsProvider(false));
}

Future<String> uploadImage(WidgetRef ref, String filePath) async {
  final dio = ref.read(dioProvider);
  final fileName = filePath.split('/').last;
  final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpeg';
  final mimeSubtype = (ext == 'png' || ext == 'webp' || ext == 'gif') ? ext : 'jpeg';
  
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(
      filePath,
      filename: fileName,
      contentType: DioMediaType('image', mimeSubtype),
    ),
  });
  final res = await dio.post('/api/v1/media/upload', data: formData);
  return (res.data as Map<String, dynamic>)['url'] as String;
}

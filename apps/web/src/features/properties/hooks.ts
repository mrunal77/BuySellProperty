import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../../lib/api';

export interface Property {
  id: string;
  title: string;
  description: string;
  propertyType: string;
  listingType: string;
  price: number;
  areaSqft: number;
  bedrooms?: number;
  bathrooms?: number;
  furnishing: string;
  status: string;
  ownerId: string;
  addressLine: string;
  cityId: string;
  localityId?: string;
  latitude: number;
  longitude: number;
  imageUrls?: string[];
  amenities?: string[];
  ownerPhone?: string;
  ownerEmail?: string;
  createdAt: string;
  publishedAt?: string;
}

export interface Amenity {
  id: string;
  name: string;
  icon: string;
  category: string;
}

export interface Enquiry {
  id: string;
  propertyId: string;
  propertyTitle: string;
  buyerId: string;
  ownerId: string;
  message: string;
  contactPhone: string;
  status: string;
  createdAt: string;
}

export interface SiteVisit {
  id: string;
  propertyId: string;
  propertyTitle: string;
  buyerId: string;
  ownerId: string;
  scheduledAt: string;
  status: string;
  notes?: string;
  createdAt: string;
}

export function useProperties(filters: Record<string, unknown>) {
  return useQuery<{ data: Property[]; page: number; pageSize: number; total: number }>({
    queryKey: ['properties', filters],
    queryFn: async () => (await api.get('/api/v1/properties', { params: filters })).data,
  });
}

export function useProperty(id?: string) {
  return useQuery<Property>({
    queryKey: ['property', id],
    queryFn: async () => (await api.get(`/api/v1/properties/${id}`)).data,
    enabled: !!id,
  });
}

export function useCities() {
  return useQuery<{ id: string; name: string; state: string; propertyCount?: number }[]>({
    queryKey: ['cities'],
    queryFn: async () => (await api.get('/api/v1/cities')).data,
  });
}

export function useAmenities() {
  return useQuery<Amenity[]>({
    queryKey: ['amenities'],
    queryFn: async () => (await api.get('/api/v1/amenities')).data,
  });
}

export function useFavorites() {
  return useQuery<Property[]>({
    queryKey: ['favorites'],
    queryFn: async () => (await api.get('/api/v1/favorites')).data,
  });
}

export function useToggleFavorite() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ propertyId, isFav }: { propertyId: string; isFav: boolean }) => {
      if (isFav) {
        await api.delete(`/api/v1/favorites/${propertyId}`);
      } else {
        await api.post('/api/v1/favorites', { propertyId });
      }
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['favorites'] });
    },
  });
}

export function useEnquiries(mine = false) {
  return useQuery<Enquiry[]>({
    queryKey: ['enquiries', mine],
    queryFn: async () => (await api.get('/api/v1/enquiries', { params: { mine } })).data,
  });
}

export function useCreateEnquiry() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: { propertyId: string; message: string; contactPhone: string }) => {
      return (await api.post('/api/v1/enquiries', payload)).data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['enquiries'] });
    },
  });
}

export function useSiteVisits(mine = false) {
  return useQuery<SiteVisit[]>({
    queryKey: ['site-visits', mine],
    queryFn: async () => (await api.get('/api/v1/site-visits', { params: { mine } })).data,
  });
}

export function useScheduleSiteVisit() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: { propertyId: string; scheduledAt: string; notes?: string }) => {
      return (await api.post('/api/v1/site-visits', payload)).data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['site-visits'] });
    },
  });
}

export function useCreateProperty() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: Partial<Property>) => {
      return (await api.post('/api/v1/properties', payload)).data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['properties'] });
    },
  });
}

export function useUpdateProperty() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, data }: { id: string; data: Partial<Property> }) => {
      return (await api.patch(`/api/v1/properties/${id}`, data)).data;
    },
    onSuccess: (_, variables) => {
      qc.invalidateQueries({ queryKey: ['properties'] });
      qc.invalidateQueries({ queryKey: ['property', variables.id] });
    },
  });
}

export function usePublishProperty() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      return (await api.post(`/api/v1/properties/${id}/publish`)).data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['properties'] });
      qc.invalidateQueries({ queryKey: ['mine'] });
    },
  });
}

export function useMarkSold() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      return (await api.post(`/api/v1/properties/${id}/mark-sold`)).data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['properties'] });
      qc.invalidateQueries({ queryKey: ['mine'] });
    },
  });
}

export function useMarkRented() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      return (await api.post(`/api/v1/properties/${id}/mark-rented`)).data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['properties'] });
      qc.invalidateQueries({ queryKey: ['mine'] });
    },
  });
}

export function usePauseProperty() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      return (await api.post(`/api/v1/properties/${id}/pause`)).data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['properties'] });
      qc.invalidateQueries({ queryKey: ['mine'] });
    },
  });
}

export function useDeleteProperty() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      return (await api.delete(`/api/v1/properties/${id}`)).data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['properties'] });
      qc.invalidateQueries({ queryKey: ['mine'] });
    },
  });
}

export function useAdminUsers() {
  return useQuery({
    queryKey: ['admin', 'users'],
    queryFn: async () => (await api.get('/api/v1/admin/users')).data,
  });
}

export function useAdminPendingListings() {
  return useQuery<Property[]>({
    queryKey: ['admin', 'pending-listings'],
    queryFn: async () => (await api.get('/api/v1/admin/listings/pending')).data,
  });
}

export function useModerateListing() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, approve, reason }: { id: string; approve: boolean; reason?: string }) => {
      return (await api.post(`/api/v1/admin/listings/${id}/moderate`, { approve, reason })).data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'pending-listings'] });
      qc.invalidateQueries({ queryKey: ['properties'] });
    },
  });
}

export function useUploadImage() {
  return useMutation({
    mutationFn: async (file: File) => {
      const formData = new FormData();
      formData.append('file', file);
      const { data } = await api.post('/api/v1/media/upload', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      return data.url as string;
    },
  });
}

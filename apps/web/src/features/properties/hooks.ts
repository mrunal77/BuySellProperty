import { useQuery } from '@tanstack/react-query';
import { api } from '../../lib/api';

export function useProperties(filters: Record<string, unknown>) {
  return useQuery({
    queryKey: ['properties', filters],
    queryFn: async () => (await api.get('/api/v1/properties', { params: filters })).data,
  });
}

export function useCities() {
  return useQuery({
    queryKey: ['cities'],
    queryFn: async () => (await api.get('/api/v1/cities')).data,
  });
}

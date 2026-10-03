import { useState, ChangeEvent } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { api } from '../lib/api';
import { useAuth } from '../lib/auth';
import { PropertyCard } from '../components/PropertyCard';
import { SectionHeading, Button, EmptyState, Badge, Spinner } from '../components/ui';
import { useCities, useAmenities, useCreateProperty, usePublishProperty, useMarkSold, useMarkRented, usePauseProperty, useDeleteProperty, useEnquiries, useSiteVisits, useUploadImage } from '../features/properties/hooks';

export function DashboardPage() {
  const { session } = useAuth();
  const [activeTab, setActiveTab] = useState<'listings' | 'enquiries' | 'visits'>('listings');
  const [showCreateModal, setShowCreateModal] = useState(false);

  // Queries
  const { data: listingsData, isLoading: listingsLoading, refetch: refetchListings } = useQuery({
    queryKey: ['mine'],
    queryFn: async () => (await api.get('/api/v1/properties', { params: { mine: true, pageSize: 50 } })).data,
  });

  const { data: enquiries, isLoading: enquiriesLoading } = useEnquiries(true);
  const { data: visits, isLoading: visitsLoading } = useSiteVisits(true);
  const { data: cities } = useCities();
  const { data: masterAmenities } = useAmenities();

  const createProperty = useCreateProperty();
  const publishProperty = usePublishProperty();
  const markSold = useMarkSold();
  const markRented = useMarkRented();
  const pauseProperty = usePauseProperty();
  const deleteProperty = useDeleteProperty();
  const uploadImage = useUploadImage();

  // Create Form State
  const [formTitle, setFormTitle] = useState('');
  const [formDesc, setFormDesc] = useState('');
  const [formPropType, setFormPropType] = useState('Apartment');
  const [formListingType, setFormListingType] = useState('Sale');
  const [formPrice, setFormPrice] = useState('');
  const [formArea, setFormArea] = useState('');
  const [formBeds, setFormBeds] = useState('2');
  const [formBaths, setFormBaths] = useState('2');
  const [formFurnishing, setFormFurnishing] = useState('SemiFurnished');
  const [formAddress, setFormAddress] = useState('');
  const [formCityId, setFormCityId] = useState('');
  const [uploadedImages, setUploadedImages] = useState<string[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const [selectedAmenities, setSelectedAmenities] = useState<string[]>(['24x7 Security', 'Power Backup']);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const items = listingsData?.data ?? [];

  const handleFileUpload = async (e: ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;

    setIsUploading(true);
    setSubmitError(null);

    const newUrls: string[] = [];
    try {
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        const url = await uploadImage.mutateAsync(file);
        newUrls.push(url);
      }
      setUploadedImages((prev) => [...prev, ...newUrls]);
    } catch (err: any) {
      setSubmitError(err.response?.data?.detail || 'Failed to upload image.');
    } finally {
      setIsUploading(false);
      e.target.value = '';
    }
  };

  const removeUploadedImage = (urlToRemove: string) => {
    setUploadedImages((prev) => prev.filter((u) => u !== urlToRemove));
  };

  const handleCreateProperty = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);

    const city = formCityId || (cities && cities[0]?.id);
    if (!city) { setSubmitError('Please select a city.'); return; }

    createProperty.mutate(
      {
        title: formTitle,
        description: formDesc,
        propertyType: formPropType,
        listingType: formListingType,
        price: Number(formPrice),
        areaSqft: Number(formArea),
        bedrooms: Number(formBeds),
        bathrooms: Number(formBaths),
        furnishing: formFurnishing,
        addressLine: formAddress,
        cityId: city,
        latitude: 19.076,
        longitude: 72.8777,
        imageUrls: uploadedImages,
        amenities: selectedAmenities,
      },
      {
        onSuccess: (newProp) => {
          publishProperty.mutate(newProp.id, {
            onSuccess: () => {
              setShowCreateModal(false);
              refetchListings();
            },
          });
        },
        onError: (err: any) => {
          setSubmitError(err.response?.data?.detail || 'Failed to create listing.');
        },
      }
    );
  };

  const toggleAmenity = (name: string) => {
    setSelectedAmenities((prev) =>
      prev.includes(name) ? prev.filter((a) => a !== name) : [...prev, name]
    );
  };

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
      <SectionHeading
        kicker="Owner & Agent Studio"
        title={`Welcome, ${session?.email}`}
        sub={`${listingsData?.total ?? 0} total listings • Role: ${session?.userType}`}
        action={
          <div className="flex gap-2">
            <Button onClick={() => setShowCreateModal(true)}>+ Post New Property</Button>
            <Link to="/search"><Button variant="secondary">View Marketplace</Button></Link>
          </div>
        }
      />

      {/* Tabs */}
      <div className="mt-6 flex border-b border-slate-200 dark:border-slate-800">
        <button
          onClick={() => setActiveTab('listings')}
          className={`border-b-2 px-4 py-2.5 text-sm font-semibold transition ${activeTab === 'listings' ? 'border-brand-600 text-brand-600 dark:text-brand-400' : 'border-transparent text-slate-500 hover:text-slate-700'}`}
        >
          📋 My Listings ({items.length})
        </button>
        <button
          onClick={() => setActiveTab('enquiries')}
          className={`border-b-2 px-4 py-2.5 text-sm font-semibold transition ${activeTab === 'enquiries' ? 'border-brand-600 text-brand-600 dark:text-brand-400' : 'border-transparent text-slate-500 hover:text-slate-700'}`}
        >
          📬 Enquiries Inbox ({enquiries?.length ?? 0})
        </button>
        <button
          onClick={() => setActiveTab('visits')}
          className={`border-b-2 px-4 py-2.5 text-sm font-semibold transition ${activeTab === 'visits' ? 'border-brand-600 text-brand-600 dark:text-brand-400' : 'border-transparent text-slate-500 hover:text-slate-700'}`}
        >
          📅 Site Visits ({visits?.length ?? 0})
        </button>
      </div>

      {/* Listings Tab */}
      {activeTab === 'listings' && (
        <div className="mt-6">
          {listingsLoading ? (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {[0, 1, 2, 3].map((i) => <div key={i} className="h-64 animate-pulse rounded-xl bg-slate-200 dark:bg-slate-800" />)}
            </div>
          ) : items.length === 0 ? (
            <EmptyState
              title="You haven't posted any listings yet."
              sub="Click '+ Post New Property' above to create your first listing."
            />
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {items.map((p: any) => (
                <div key={p.id} className="flex flex-col justify-between rounded-xl border border-slate-200 bg-white p-3 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                  <div>
                    <PropertyCard p={p} />
                  </div>
                  <div className="mt-3 border-t border-slate-100 pt-3 dark:border-slate-800">
                    <div className="flex flex-wrap gap-1.5">
                      {(p.status === 'Draft' || p.status === 'Paused') && (
                        <button
                          onClick={() => publishProperty.mutate(p.id)}
                          className="rounded-lg bg-emerald-600 px-2.5 py-1 text-xs font-semibold text-white hover:bg-emerald-700"
                        >
                          Publish
                        </button>
                      )}
                      {(p.status === 'Active' || p.status === 'Paused') && (
                        <>
                          <button
                            onClick={() => markSold.mutate(p.id)}
                            className="rounded-lg bg-rose-600 px-2.5 py-1 text-xs font-semibold text-white hover:bg-rose-700"
                          >
                            Mark Sold
                          </button>
                          <button
                            onClick={() => markRented.mutate(p.id)}
                            className="rounded-lg bg-blue-600 px-2.5 py-1 text-xs font-semibold text-white hover:bg-blue-700"
                          >
                            Mark Rented
                          </button>
                          <button
                            onClick={() => pauseProperty.mutate(p.id)}
                            className="rounded-lg bg-slate-600 px-2.5 py-1 text-xs font-semibold text-white hover:bg-slate-700"
                          >
                            Pause
                          </button>
                        </>
                      )}
                      <button
                        onClick={() => deleteProperty.mutate(p.id)}
                        className="rounded-lg border border-slate-300 px-2.5 py-1 text-xs font-semibold text-slate-600 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Enquiries Tab */}
      {activeTab === 'enquiries' && (
        <div className="mt-6">
          {enquiriesLoading ? (
            <div className="flex justify-center p-8"><Spinner /></div>
          ) : !enquiries || enquiries.length === 0 ? (
            <EmptyState title="No enquiries received yet." sub="When buyers contact your properties, inquiries will appear here." />
          ) : (
            <div className="space-y-3">
              {enquiries.map((enq) => (
                <div key={enq.id} className="rounded-xl border border-slate-200 bg-white p-4 dark:border-slate-800 dark:bg-slate-900">
                  <div className="flex items-center justify-between">
                    <p className="font-bold text-brand-700 dark:text-brand-300">Property: {enq.propertyTitle}</p>
                    <Badge tone="blue">{enq.status}</Badge>
                  </div>
                  <p className="mt-2 text-sm text-slate-700 dark:text-slate-300">"{enq.message}"</p>
                  <div className="mt-3 flex items-center justify-between text-xs text-slate-500">
                    <p>📞 Contact: <span className="font-semibold text-slate-900 dark:text-slate-100">{enq.contactPhone}</span></p>
                    <p>{new Date(enq.createdAt).toLocaleDateString()}</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Visits Tab */}
      {activeTab === 'visits' && (
        <div className="mt-6">
          {visitsLoading ? (
            <div className="flex justify-center p-8"><Spinner /></div>
          ) : !visits || visits.length === 0 ? (
            <EmptyState title="No site visits requested yet." sub="Scheduled buyer site visits will show here." />
          ) : (
            <div className="space-y-3">
              {visits.map((v) => (
                <div key={v.id} className="rounded-xl border border-slate-200 bg-white p-4 dark:border-slate-800 dark:bg-slate-900">
                  <div className="flex items-center justify-between">
                    <p className="font-bold text-brand-700 dark:text-brand-300">Property: {v.propertyTitle}</p>
                    <Badge tone="green">{v.status}</Badge>
                  </div>
                  <p className="mt-2 text-sm font-semibold">📅 Scheduled: {new Date(v.scheduledAt).toLocaleString()}</p>
                  {v.notes && <p className="mt-1 text-xs text-slate-500">Notes: {v.notes}</p>}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Create Property Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-2xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-slate-800 dark:bg-slate-900">
            <h3 className="text-xl font-extrabold">Post New Property Listing</h3>
            <p className="mt-1 text-xs text-slate-500">Fill in details and upload property photos directly from your device.</p>

            <form onSubmit={handleCreateProperty} className="mt-4 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-500">Title</label>
                <input
                  type="text"
                  required
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  placeholder="e.g. Spacious 3 BHK Sea View Apartment"
                  className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-500">Property Type</label>
                  <select
                    value={formPropType}
                    onChange={(e) => setFormPropType(e.target.value)}
                    className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                  >
                    {['Apartment', 'Villa', 'IndependentHouse', 'Plot', 'Commercial', 'PG', 'Office'].map((t) => (
                      <option key={t} value={t}>{t}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-500">Listing Type</label>
                  <select
                    value={formListingType}
                    onChange={(e) => setFormListingType(e.target.value)}
                    className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                  >
                    {['Sale', 'Rent', 'Lease'].map((t) => (
                      <option key={t} value={t}>{t}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-500">Price (₹)</label>
                  <input
                    type="number"
                    required
                    min="1"
                    value={formPrice}
                    onChange={(e) => setFormPrice(e.target.value)}
                    placeholder="e.g. 7500000"
                    className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-500">Super Area (sqft)</label>
                  <input
                    type="number"
                    required
                    min="1"
                    value={formArea}
                    onChange={(e) => setFormArea(e.target.value)}
                    placeholder="e.g. 1450"
                    className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-500">Bedrooms</label>
                  <input
                    type="number"
                    value={formBeds}
                    onChange={(e) => setFormBeds(e.target.value)}
                    className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-500">Bathrooms</label>
                  <input
                    type="number"
                    value={formBaths}
                    onChange={(e) => setFormBaths(e.target.value)}
                    className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-500">Furnishing</label>
                  <select
                    value={formFurnishing}
                    onChange={(e) => setFormFurnishing(e.target.value)}
                    className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                  >
                    {['Unfurnished', 'SemiFurnished', 'Furnished'].map((f) => (
                      <option key={f} value={f}>{f}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-500">City</label>
                  <select
                    value={formCityId}
                    onChange={(e) => setFormCityId(e.target.value)}
                    className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                  >
                    {cities?.map((c) => (
                      <option key={c.id} value={c.id}>{c.name}, {c.state}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-500">Address Line / Locality</label>
                  <input
                    type="text"
                    required
                    value={formAddress}
                    onChange={(e) => setFormAddress(e.target.value)}
                    placeholder="e.g. Bandra West, Carter Road"
                    className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                  />
                </div>
              </div>

              {/* DIRECT IMAGE FILE UPLOAD DROPZONE */}
              <div>
                <label className="block text-xs font-semibold text-slate-500">Upload Property Photos (File Picker)</label>
                <div className="mt-1 flex flex-col items-center justify-center rounded-xl border-2 border-dashed border-slate-300 bg-slate-50 p-4 text-center dark:border-slate-700 dark:bg-slate-800/50">
                  <input
                    type="file"
                    id="property-image-upload"
                    accept="image/*"
                    multiple
                    onChange={handleFileUpload}
                    className="hidden"
                  />
                  <label
                    htmlFor="property-image-upload"
                    className="cursor-pointer rounded-lg bg-brand-600 px-4 py-2 text-xs font-bold text-white hover:bg-brand-700"
                  >
                    {isUploading ? 'Uploading Image...' : '📁 Choose Image Files from Disk'}
                  </label>
                  <p className="mt-1 text-[11px] text-slate-400">JPG, PNG, WEBP up to 10 MB per image.</p>
                </div>

                {/* Uploaded Thumbnails Preview */}
                {uploadedImages.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {uploadedImages.map((imgUrl, i) => (
                      <div key={i} className="group relative h-20 w-24 overflow-hidden rounded-lg border border-slate-200 shadow-sm dark:border-slate-700">
                        <img src={imgUrl} alt="" className="h-full w-full object-cover" />
                        <button
                          type="button"
                          onClick={() => removeUploadedImage(imgUrl)}
                          className="absolute right-1 top-1 flex h-5 w-5 items-center justify-center rounded-full bg-rose-600 text-xs font-bold text-white shadow hover:bg-rose-700"
                        >
                          ✕
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-500">Amenities</label>
                <div className="mt-2 flex flex-wrap gap-2">
                  {masterAmenities?.map((am) => (
                    <button
                      key={am.id}
                      type="button"
                      onClick={() => toggleAmenity(am.name)}
                      className={`rounded-lg px-3 py-1.5 text-xs font-semibold border ${selectedAmenities.includes(am.name) ? 'bg-brand-600 text-white border-brand-600' : 'bg-slate-100 text-slate-700 border-slate-200 dark:bg-slate-800 dark:text-slate-300 dark:border-slate-700'}`}
                    >
                      {selectedAmenities.includes(am.name) ? '✓ ' : '+ '}{am.name}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-500">Description</label>
                <textarea
                  rows={3}
                  value={formDesc}
                  onChange={(e) => setFormDesc(e.target.value)}
                  placeholder="Describe your property highlights, nearby spots, ventilation..."
                  className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                />
              </div>

              {submitError && (
                <p className="text-xs font-semibold text-rose-600">{submitError}</p>
              )}

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowCreateModal(false)}
                  className="w-1/2 rounded-lg border border-slate-300 py-2.5 text-sm font-semibold dark:border-slate-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={createProperty.isPending || isUploading}
                  className="w-1/2 rounded-lg bg-brand-600 py-2.5 text-sm font-semibold text-white hover:bg-brand-700"
                >
                  {createProperty.isPending ? 'Publishing...' : 'Publish Property'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

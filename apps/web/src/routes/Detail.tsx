import { useState } from 'react';
import { Link, useParams, useNavigate } from 'react-router-dom';
import { formatINR } from '../lib/validation';
import { Badge, Spinner } from '../components/ui';
import { PropertyArt } from '../components/PropertyCard';
import { useProperty, useFavorites, useToggleFavorite, useCreateEnquiry, useScheduleSiteVisit } from '../features/properties/hooks';
import { useAuth } from '../lib/auth';

export function DetailPage() {
  const { id } = useParams();
  const nav = useNavigate();
  const { session } = useAuth();
  const { data, isLoading, isError } = useProperty(id);
  const { data: favorites } = useFavorites();
  const toggleFav = useToggleFavorite();

  const createEnquiry = useCreateEnquiry();
  const scheduleVisit = useScheduleSiteVisit();

  const [activeImg, setActiveImg] = useState<string | null>(null);
  const [showEnquiry, setShowEnquiry] = useState(false);
  const [showVisit, setShowVisit] = useState(false);

  const [enquiryMsg, setEnquiryMsg] = useState('Hi, I am interested in this property. Please contact me.');
  const [enquiryPhone, setEnquiryPhone] = useState('');
  const [enquiryStatus, setEnquiryStatus] = useState<string | null>(null);

  const [visitDate, setVisitDate] = useState('');
  const [visitNotes, setVisitNotes] = useState('');
  const [visitStatus, setVisitStatus] = useState<string | null>(null);

  if (isLoading) return <div className="flex justify-center p-12"><Spinner /></div>;
  if (isError || !data) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-12 text-center">
        <p className="text-xl font-bold">Property not found</p>
        <p className="mt-1 text-sm text-slate-500">It may have been sold or removed.</p>
        <Link to="/search" className="mt-4 inline-block rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white">Back to search</Link>
      </div>
    );
  }

  const isFav = !!favorites?.some((f) => f.id === data.id);
  const images = data.imageUrls && data.imageUrls.length > 0 ? data.imageUrls : [];
  const currentImg = activeImg || (images.length > 0 ? images[0] : undefined);

  const handleToggleFav = () => {
    if (!session) { nav('/login'); return; }
    toggleFav.mutate({ propertyId: data.id, isFav });
  };

  const handleSendEnquiry = (e: React.FormEvent) => {
    e.preventDefault();
    if (!session) { nav('/login'); return; }
    setEnquiryStatus('sending');
    createEnquiry.mutate(
      { propertyId: data.id, message: enquiryMsg, contactPhone: enquiryPhone },
      {
        onSuccess: () => {
          setEnquiryStatus('success');
          setTimeout(() => setShowEnquiry(false), 2000);
        },
        onError: (err: any) => {
          setEnquiryStatus(err.response?.data?.detail || 'Failed to send enquiry.');
        },
      }
    );
  };

  const handleScheduleVisit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!session) { nav('/login'); return; }
    if (!visitDate) return;
    setVisitStatus('sending');
    scheduleVisit.mutate(
      { propertyId: data.id, scheduledAt: new Date(visitDate).toISOString(), notes: visitNotes },
      {
        onSuccess: () => {
          setVisitStatus('success');
          setTimeout(() => setShowVisit(false), 2000);
        },
        onError: (err: any) => {
          setVisitStatus(err.response?.data?.detail || 'Failed to schedule visit.');
        },
      }
    );
  };

  return (
    <div className="mx-auto max-w-5xl px-4 py-8 sm:px-6">
      <div className="flex items-center justify-between">
        <Link to="/search" className="text-sm font-semibold text-brand-700 hover:underline">← Back to results</Link>
        <button
          onClick={handleToggleFav}
          className="flex items-center gap-1.5 rounded-lg border border-slate-300 px-3 py-1.5 text-sm font-semibold hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
        >
          <span>{isFav ? '❤️ Saved' : '🤍 Save property'}</span>
        </button>
      </div>

      <div className="mt-3 overflow-hidden rounded-2xl border border-slate-200 dark:border-slate-800">
        <PropertyArt id={data.id} title={data.title} imageUrl={currentImg} className="h-64 sm:h-96" />
      </div>

      {images.length > 1 && (
        <div className="mt-3 flex gap-2 overflow-x-auto pb-2">
          {images.map((img, i) => (
            <button
              key={i}
              onClick={() => setActiveImg(img)}
              className={`h-20 w-28 shrink-0 overflow-hidden rounded-lg border-2 ${currentImg === img ? 'border-brand-600' : 'border-transparent opacity-70 hover:opacity-100'}`}
            >
              <img src={img} alt="" className="h-full w-full object-cover" />
            </button>
          ))}
        </div>
      )}

      <div className="mt-5 grid gap-6 lg:grid-cols-[1fr_320px]">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <Badge tone={data.listingType === 'Rent' ? 'blue' : 'green'}>{data.listingType}</Badge>
            <Badge tone="slate">{data.propertyType}</Badge>
            <Badge tone="slate">{data.status}</Badge>
          </div>
          <h1 className="mt-2 text-2xl font-extrabold sm:text-3xl">{data.title}</h1>
          <p className="mt-1 text-sm text-slate-500">📍 {data.addressLine}</p>

          <dl className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
            {[
              ['Area', `${data.areaSqft} sqft`],
              ['Bedrooms', data.bedrooms ? `${data.bedrooms} BHK` : '—'],
              ['Bathrooms', data.bathrooms ? `${data.bathrooms} Baths` : '—'],
              ['Furnishing', data.furnishing ?? '—'],
            ].map(([k, v]) => (
              <div key={k} className="rounded-xl border border-slate-200 p-3 dark:border-slate-800">
                <dt className="text-xs text-slate-500">{k}</dt>
                <dd className="font-bold">{v}</dd>
              </div>
            ))}
          </dl>

          {data.amenities && data.amenities.length > 0 && (
            <div className="mt-6">
              <h2 className="font-bold">Amenities</h2>
              <div className="mt-2 flex flex-wrap gap-2">
                {data.amenities.map((am) => (
                  <span key={am} className="inline-flex items-center gap-1 rounded-lg bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                    ✨ {am}
                  </span>
                ))}
              </div>
            </div>
          )}

          <h2 className="mt-6 font-bold">Description</h2>
          <p className="mt-1 whitespace-pre-wrap text-sm text-slate-600 dark:text-slate-300">{data.description || 'No description provided.'}</p>
        </div>

        <aside className="h-fit rounded-2xl border border-slate-200 p-5 dark:border-slate-800 dark:bg-slate-900">
          <p className="text-3xl font-extrabold text-brand-700 dark:text-brand-300">{formatINR(data.price)}</p>
          <p className="text-xs text-slate-500 mt-1">₹{Math.round(data.price / data.areaSqft)} / sqft</p>

          <div className="mt-4 rounded-xl border border-slate-200 bg-slate-50 p-3 dark:border-slate-800 dark:bg-slate-800/50">
            <p className="text-xs font-semibold text-slate-500">Property Owner</p>
            <p className="text-sm font-bold text-slate-900 dark:text-white">{data.ownerPhone || '+91 9876543210'}</p>
            <div className="mt-2 flex gap-2">
              <a
                href={`tel:${(data.ownerPhone || '+919876543210').replace(/[^0-9+]/g, '')}`}
                className="flex-1 rounded-lg bg-blue-600 px-3 py-1.5 text-center text-xs font-semibold text-white hover:bg-blue-700"
              >
                📞 Call
              </a>
              <a
                href={`https://wa.me/${(data.ownerPhone || '919876543210').replace(/[^0-9]/g, '')}`}
                target="_blank"
                rel="noreferrer"
                className="flex-1 rounded-lg bg-emerald-600 px-3 py-1.5 text-center text-xs font-semibold text-white hover:bg-emerald-700"
              >
                💬 WhatsApp
              </a>
            </div>
          </div>

          <button
            onClick={() => setShowEnquiry(true)}
            className="mt-3 w-full rounded-lg bg-brand-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-brand-700"
          >
            ✉️ Send Enquiry
          </button>
          <button
            onClick={() => setShowVisit(true)}
            className="mt-2 w-full rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-semibold hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800"
          >
            📅 Schedule Site Visit
          </button>
        </aside>
      </div>

      {/* Contact Owner Enquiry Modal */}
      {showEnquiry && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-xl dark:border-slate-800 dark:bg-slate-900">
            <h3 className="text-lg font-bold">Contact Property Owner</h3>
            <p className="mt-1 text-xs text-slate-500">Call, WhatsApp, or send an inquiry for {data.title}</p>

            <div className="my-4 rounded-xl border border-slate-200 bg-slate-50 p-3 dark:border-slate-800 dark:bg-slate-800/50">
              <p className="text-xs font-semibold text-slate-500">Owner Contact Number</p>
              <p className="text-base font-bold text-slate-900 dark:text-white">{data.ownerPhone || '+91 9876543210'}</p>
              <div className="mt-2 flex gap-2">
                <a
                  href={`tel:${(data.ownerPhone || '+919876543210').replace(/[^0-9+]/g, '')}`}
                  className="flex-1 rounded-lg bg-blue-600 py-2 text-center text-xs font-semibold text-white hover:bg-blue-700"
                >
                  📞 Call Now
                </a>
                <a
                  href={`https://wa.me/${(data.ownerPhone || '919876543210').replace(/[^0-9]/g, '')}`}
                  target="_blank"
                  rel="noreferrer"
                  className="flex-1 rounded-lg bg-emerald-600 py-2 text-center text-xs font-semibold text-white hover:bg-emerald-700"
                >
                  💬 Chat on WhatsApp
                </a>
              </div>
            </div>

            <div className="relative my-4 flex items-center justify-center">
              <span className="absolute bg-white px-2 text-[10px] font-bold text-slate-400 dark:bg-slate-900">OR SEND MESSAGE</span>
              <div className="w-full border-t border-slate-200 dark:border-slate-800"></div>
            </div>

            {enquiryStatus === 'success' ? (
              <div className="my-6 rounded-lg bg-emerald-50 p-4 text-center text-sm font-semibold text-emerald-800 dark:bg-emerald-950 dark:text-emerald-200">
                ✅ Enquiry sent successfully! The owner will contact you shortly.
              </div>
            ) : (
              <form onSubmit={handleSendEnquiry} className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-500">Your Phone Number</label>
                  <input
                    type="tel"
                    required
                    value={enquiryPhone}
                    onChange={(e) => setEnquiryPhone(e.target.value)}
                    placeholder="9876543210"
                    className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-500">Message</label>
                  <textarea
                    rows={3}
                    required
                    value={enquiryMsg}
                    onChange={(e) => setEnquiryMsg(e.target.value)}
                    className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                  />
                </div>
                {enquiryStatus && enquiryStatus !== 'sending' && (
                  <p className="text-xs font-semibold text-rose-600">{enquiryStatus}</p>
                )}
                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => setShowEnquiry(false)}
                    className="w-1/2 rounded-lg border border-slate-300 py-2 text-sm font-semibold dark:border-slate-700"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={enquiryStatus === 'sending'}
                    className="w-1/2 rounded-lg bg-brand-600 py-2 text-sm font-semibold text-white hover:bg-brand-700"
                  >
                    {enquiryStatus === 'sending' ? 'Sending...' : 'Send Enquiry'}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}

      {/* Schedule Site Visit Modal */}
      {showVisit && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-xl dark:border-slate-800 dark:bg-slate-900">
            <h3 className="text-lg font-bold">Book a Site Visit</h3>
            <p className="mt-1 text-xs text-slate-500">Schedule a visit to inspect {data.title}</p>

            {visitStatus === 'success' ? (
              <div className="my-6 rounded-lg bg-emerald-50 p-4 text-center text-sm font-semibold text-emerald-800 dark:bg-emerald-950 dark:text-emerald-200">
                📅 Site visit scheduled! Check your visits tab for updates.
              </div>
            ) : (
              <form onSubmit={handleScheduleVisit} className="mt-4 space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-500">Preferred Date & Time</label>
                  <input
                    type="datetime-local"
                    required
                    value={visitDate}
                    onChange={(e) => setVisitDate(e.target.value)}
                    className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-500">Notes / Requests (Optional)</label>
                  <input
                    type="text"
                    value={visitNotes}
                    onChange={(e) => setVisitNotes(e.target.value)}
                    placeholder="e.g. Please meet at front gate"
                    className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                  />
                </div>
                {visitStatus && visitStatus !== 'sending' && (
                  <p className="text-xs font-semibold text-rose-600">{visitStatus}</p>
                )}
                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => setShowVisit(false)}
                    className="w-1/2 rounded-lg border border-slate-300 py-2 text-sm font-semibold dark:border-slate-700"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={visitStatus === 'sending'}
                    className="w-1/2 rounded-lg bg-brand-600 py-2 text-sm font-semibold text-white hover:bg-brand-700"
                  >
                    {visitStatus === 'sending' ? 'Booking...' : 'Confirm Visit'}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

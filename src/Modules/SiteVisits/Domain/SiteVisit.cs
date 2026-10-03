using SharedKernel;

namespace SiteVisits.Domain;

public enum VisitStatus { Requested, Confirmed, Completed, Cancelled, NoShow }

public sealed class SiteVisit : Entity
{
    public Guid PropertyId { get; private set; }
    public Guid BuyerId { get; private set; }
    public Guid OwnerId { get; private set; }
    public DateTimeOffset ScheduledAt { get; private set; }
    public VisitStatus Status { get; private set; } = VisitStatus.Requested;
    public string? Notes { get; private set; }

    private SiteVisit() { }

    public static Result<SiteVisit> Create(Guid propertyId, Guid buyerId, Guid ownerId, DateTimeOffset scheduledAt, string? notes = null)
    {
        if (propertyId == Guid.Empty) return Result<SiteVisit>.Failure(Error.Validation("visit.invalid_property", "Invalid property."));
        if (buyerId == Guid.Empty) return Result<SiteVisit>.Failure(Error.Validation("visit.invalid_buyer", "Invalid buyer."));
        if (ownerId == Guid.Empty) return Result<SiteVisit>.Failure(Error.Validation("visit.invalid_owner", "Invalid owner."));
        if (buyerId == ownerId) return Result<SiteVisit>.Failure(Error.Validation("visit.self_contact", "Cannot schedule visit for your own listing."));
        if (scheduledAt <= DateTimeOffset.UtcNow)
            return Result<SiteVisit>.Failure(Error.Validation("visit.past_date", "Scheduled date must be in the future."));

        return Result<SiteVisit>.Success(new SiteVisit
        {
            PropertyId = propertyId,
            BuyerId = buyerId,
            OwnerId = ownerId,
            ScheduledAt = scheduledAt,
            Status = VisitStatus.Requested,
            Notes = notes?.Trim()
        });
    }

    public Result UpdateStatus(VisitStatus status)
    {
        Status = status;
        Touch();
        return Result.Success();
    }
}

using SharedKernel;

namespace Enquiries.Domain;

public enum EnquiryStatus { New, Contacted, Visited, Closed, Spam }

public sealed class Enquiry : Entity
{
    public Guid PropertyId { get; private set; }
    public Guid BuyerId { get; private set; }
    public Guid OwnerId { get; private set; }
    public string Message { get; private set; } = default!;
    public string ContactPhone { get; private set; } = default!;
    public EnquiryStatus Status { get; private set; } = EnquiryStatus.New;

    private Enquiry() { }

    public static Result<Enquiry> Create(Guid propertyId, Guid buyerId, Guid ownerId, string message, string contactPhone)
    {
        if (propertyId == Guid.Empty) return Result<Enquiry>.Failure(Error.Validation("enquiry.invalid_property", "Invalid property."));
        if (buyerId == Guid.Empty) return Result<Enquiry>.Failure(Error.Validation("enquiry.invalid_buyer", "Invalid buyer."));
        if (ownerId == Guid.Empty) return Result<Enquiry>.Failure(Error.Validation("enquiry.invalid_owner", "Invalid owner."));
        if (buyerId == ownerId) return Result<Enquiry>.Failure(Error.Validation("enquiry.self_contact", "Cannot send enquiry to your own property."));
        if (string.IsNullOrWhiteSpace(contactPhone)) return Result<Enquiry>.Failure(Error.Validation("enquiry.phone_required", "Contact phone is required."));

        return Result<Enquiry>.Success(new Enquiry
        {
            PropertyId = propertyId,
            BuyerId = buyerId,
            OwnerId = ownerId,
            Message = message?.Trim() ?? "Hi, I am interested in this property.",
            ContactPhone = contactPhone.Trim(),
            Status = EnquiryStatus.New
        });
    }

    public Result UpdateStatus(EnquiryStatus status)
    {
        Status = status;
        Touch();
        return Result.Success();
    }
}

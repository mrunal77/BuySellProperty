using SharedKernel;

namespace Properties.Domain;

public enum PropertyType { Apartment, Villa, IndependentHouse, Plot, Commercial, Office, Shop, PG, Studio }
public enum ListingType { Sale, Rent, Lease, PG }
public enum Furnishing { Unfurnished, SemiFurnished, Furnished }
public enum PropertyStatus { Draft, Active, Paused, Sold, Rented, Expired, Rejected }

public sealed class Property : Entity
{
    public string Title { get; private set; } = default!;
    public string Description { get; private set; } = default!;
    public PropertyType PropertyType { get; private set; }
    public ListingType ListingType { get; private set; }
    public decimal Price { get; private set; }
    public double AreaSqft { get; private set; }
    public int? Bedrooms { get; private set; }
    public int? Bathrooms { get; private set; }
    public Furnishing Furnishing { get; private set; }
    public int? Floor { get; private set; }
    public int? TotalFloors { get; private set; }
    public string? Facing { get; private set; }
    public PropertyStatus Status { get; private set; } = PropertyStatus.Draft;
    public Guid OwnerId { get; private set; }
    public Guid? AgentId { get; private set; }
    public string AddressLine { get; private set; } = default!;
    public Guid CityId { get; private set; }
    public Guid? LocalityId { get; private set; }
    public double Latitude { get; private set; }
    public double Longitude { get; private set; }
    public DateTimeOffset? PublishedAt { get; private set; }
    public string? RejectionReason { get; private set; }

    private Property() { }

    public static Result<Property> Create(
        string title, string description, PropertyType type, ListingType listingType,
        decimal price, double areaSqft, Guid ownerId, string addressLine,
        Guid cityId, double lat, double lng,
        int? bedrooms = null, int? bathrooms = null,
        Furnishing furnishing = Furnishing.Unfurnished,
        Guid? localityId = null, int? floor = null, int? totalFloors = null, string? facing = null)
    {
        if (string.IsNullOrWhiteSpace(title) || title.Length > 200)
            return Result<Property>.Failure(Error.Validation("property.invalid_title", "Title must be 1..200 chars."));
        if (price <= 0) return Result<Property>.Failure(Error.Validation("property.invalid_price", "Price must be > 0."));
        if (areaSqft <= 0) return Result<Property>.Failure(Error.Validation("property.invalid_area", "Area must be > 0."));
        if (lat is < -90 or > 90 || lng is < -180 or > 180)
            return Result<Property>.Failure(Error.Validation("property.invalid_geo", "Invalid coordinates."));
        if (ownerId == Guid.Empty) return Result<Property>.Failure(Error.Validation("property.invalid_owner", "Invalid owner."));

        return Result<Property>.Success(new Property
        {
            Title = title.Trim(), Description = description?.Trim() ?? "",
            PropertyType = type, ListingType = listingType, Price = price, AreaSqft = areaSqft,
            OwnerId = ownerId, AddressLine = addressLine?.Trim() ?? "", CityId = cityId,
            LocalityId = localityId, Latitude = lat, Longitude = lng,
            Bedrooms = bedrooms, Bathrooms = bathrooms, Furnishing = furnishing,
            Floor = floor, TotalFloors = totalFloors, Facing = facing,
        });
    }

    public Result Publish()
    {
        if (Status is PropertyStatus.Sold or PropertyStatus.Rented)
            return Result.Failure(Error.Conflict("property.already_closed", "Already sold/rented."));
        Status = PropertyStatus.Active; PublishedAt = DateTimeOffset.UtcNow; Touch();
        return Result.Success();
    }

    public Result Pause() { if (Status != PropertyStatus.Active) return Cant("pause"); Status = PropertyStatus.Paused; Touch(); return Result.Success(); }
    public Result MarkSold() { Status = PropertyStatus.Sold; Touch(); return Result.Success(); }
    public Result MarkRented() { Status = PropertyStatus.Rented; Touch(); return Result.Success(); }
    public Result Reject(string reason) { Status = PropertyStatus.Rejected; RejectionReason = reason; Touch(); return Result.Success(); }

    private static Result Cant(string op) => Result.Failure(Error.Conflict("property.invalid_transition", $"Cannot {op} in current status."));

    public void Update(string title, string description, decimal price, double areaSqft,
        int? beds, int? baths, Furnishing furnishing, string addressLine)
    {
        Title = title; Description = description; Price = price; AreaSqft = areaSqft;
        Bedrooms = beds; Bathrooms = baths; Furnishing = furnishing; AddressLine = addressLine;
        Touch();
    }

    public bool IsOwnedBy(Guid userId) => OwnerId == userId || AgentId == userId;
}

public sealed record SearchPropertiesQuery(
    Guid? CityId, Guid? LocalityId, PropertyType? Type, ListingType? ListingType,
    decimal? MinPrice, decimal? MaxPrice, int? Beds, int? Baths,
    double? MinArea, double? MaxArea, double? Lat, double? Lng, double? RadiusKm,
    string Sort, int Page, int PageSize);

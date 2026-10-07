using System.Text.Json;
using FluentValidation;
using Properties.Domain;

namespace Properties.Application;

public sealed record CreatePropertyRequest(
    string Title, string Description, PropertyType PropertyType, ListingType ListingType,
    decimal Price, double AreaSqft, string AddressLine, Guid CityId, double Latitude, double Longitude,
    Guid? LocalityId, int? Bedrooms, int? Bathrooms, Furnishing Furnishing,
    List<string>? ImageUrls = null, List<string>? Amenities = null,
    JsonElement? Details = null, string? ContactName = null, string? ContactPhone = null, string? WhatsApp = null);

public sealed class CreatePropertyValidator : AbstractValidator<CreatePropertyRequest>
{
    public CreatePropertyValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Description).MaximumLength(5000);
        RuleFor(x => x.Price).GreaterThan(0);
        RuleFor(x => x.AreaSqft).GreaterThan(0);
        RuleFor(x => x.CityId).NotEmpty();
        RuleFor(x => x.Latitude).InclusiveBetween(-90, 90);
        RuleFor(x => x.Longitude).InclusiveBetween(-180, 180);
        RuleFor(x => x.ContactName).MaximumLength(120);
        RuleFor(x => x.ContactPhone).MaximumLength(30);
        RuleFor(x => x.WhatsApp).MaximumLength(30);
        When(x => x.Details is not null, () =>
            RuleFor(x => x.Details!.Value.GetRawText().Length).LessThanOrEqualTo(8192));
    }
}

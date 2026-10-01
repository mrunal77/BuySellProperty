using FluentValidation;
using Properties.Domain;

namespace Properties.Application;

public sealed record CreatePropertyRequest(
    string Title, string Description, PropertyType PropertyType, ListingType ListingType,
    decimal Price, double AreaSqft, string AddressLine, Guid CityId, double Latitude, double Longitude,
    Guid? LocalityId, int? Bedrooms, int? Bathrooms, Furnishing Furnishing);

public sealed class CreatePropertyValidator : AbstractValidator<CreatePropertyRequest>
{
    public CreatePropertyValidator()
    {
        RuleFor(x => x.Title).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Price).GreaterThan(0);
        RuleFor(x => x.AreaSqft).GreaterThan(0);
        RuleFor(x => x.CityId).NotEmpty();
        RuleFor(x => x.Latitude).InclusiveBetween(-90, 90);
        RuleFor(x => x.Longitude).InclusiveBetween(-180, 180);
    }
}

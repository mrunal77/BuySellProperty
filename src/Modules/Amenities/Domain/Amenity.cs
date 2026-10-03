using SharedKernel;

namespace Amenities.Domain;

public sealed class Amenity : Entity
{
    public string Name { get; private set; } = default!;
    public string Icon { get; private set; } = default!;
    public string Category { get; private set; } = default!;

    private Amenity() { }

    public static Result<Amenity> Create(string name, string icon, string category)
    {
        if (string.IsNullOrWhiteSpace(name)) return Result<Amenity>.Failure(Error.Validation("amenity.invalid_name", "Name required."));
        return Result<Amenity>.Success(new Amenity
        {
            Name = name.Trim(),
            Icon = icon?.Trim() ?? "check",
            Category = category?.Trim() ?? "General"
        });
    }
}

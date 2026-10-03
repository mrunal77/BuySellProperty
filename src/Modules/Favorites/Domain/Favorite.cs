using SharedKernel;

namespace Favorites.Domain;

public sealed class Favorite : Entity
{
    public Guid UserId { get; private set; }
    public Guid PropertyId { get; private set; }

    private Favorite() { }

    public static Result<Favorite> Create(Guid userId, Guid propertyId)
    {
        if (userId == Guid.Empty) return Result<Favorite>.Failure(Error.Validation("favorite.invalid_user", "User required."));
        if (propertyId == Guid.Empty) return Result<Favorite>.Failure(Error.Validation("favorite.invalid_property", "Property required."));

        return Result<Favorite>.Success(new Favorite
        {
            UserId = userId,
            PropertyId = propertyId
        });
    }
}

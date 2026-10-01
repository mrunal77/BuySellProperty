using SharedKernel;

namespace Users.Domain;

public sealed class UserProfile : Entity
{
    public new Guid Id { get; private set; } // = UserId
    public string DisplayName { get; private set; } = default!;
    public string? AvatarUrl { get; private set; }
    public string UserType { get; private set; } = "Customer";
    public string? CompanyName { get; private set; }
    public string? ReraId { get; private set; }
    public Guid? CityId { get; private set; }
    public bool IsVerified { get; private set; }

    private UserProfile() { }

    public static Result<UserProfile> Create(Guid userId, string displayName, string userType)
    {
        if (userId == Guid.Empty) return Result<UserProfile>.Failure(Error.Validation("profile.invalid_user", "Invalid user."));
        if (string.IsNullOrWhiteSpace(displayName)) return Result<UserProfile>.Failure(Error.Validation("profile.invalid_name", "Display name required."));
        return Result<UserProfile>.Success(new UserProfile { Id = userId, DisplayName = displayName.Trim(), UserType = userType });
    }

    public void Update(string displayName, string? company, string? rera, Guid? cityId, string? avatar)
    {
        DisplayName = displayName; CompanyName = company; ReraId = rera; CityId = cityId; AvatarUrl = avatar;
        Touch();
    }
    public void MarkVerified() { IsVerified = true; Touch(); }
}

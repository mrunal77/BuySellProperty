using SharedKernel;

namespace Identity.Domain;

public static class Roles
{
    public const string Customer = "Customer";
    public const string Owner = "Owner";
    public const string Agent = "Agent";
    public const string Builder = "Builder";
    public const string Admin = "Admin";

    public static readonly string[] All = [Customer, Owner, Agent, Builder, Admin];
}

public sealed class User : Entity
{
    public string Email { get; private set; } = default!;
    public string? Phone { get; private set; }
    public string PasswordHash { get; private set; } = default!;
    public List<string> UserRoles { get; private set; } = [];
    public string UserType { get; private set; } = Roles.Customer;
    public bool IsActive { get; private set; } = true;

    private User() { }

    public static Result<User> Create(string email, string passwordHash, string userType, string? phone, IEnumerable<string> roles)
    {
        if (string.IsNullOrWhiteSpace(email) || !email.Contains('@'))
            return Result<User>.Failure(Error.Validation("user.invalid_email", "Invalid email."));
        if (string.IsNullOrWhiteSpace(passwordHash))
            return Result<User>.Failure(Error.Validation("user.invalid_password", "Invalid password."));
        if (!Roles.All.Contains(userType))
            return Result<User>.Failure(Error.Validation("user.invalid_type", $"Unknown user type {userType}."));
        var roleList = roles.Distinct().ToList();
        if (roleList.Count == 0 || roleList.Any(r => !Roles.All.Contains(r)))
            return Result<User>.Failure(Error.Validation("user.invalid_role", "Invalid role."));

        return Result<User>.Success(new User
        {
            Email = email.Trim().ToLowerInvariant(),
            PasswordHash = passwordHash,
            UserType = userType,
            Phone = string.IsNullOrWhiteSpace(phone) ? null : phone.Trim(),
            UserRoles = roleList,
        });
    }

    public void Deactivate() { IsActive = false; Touch(); }
    public void Activate() { IsActive = true; Touch(); }
    public void SetPasswordHash(string hash) { PasswordHash = hash; Touch(); }
}

public sealed class RefreshToken : Entity
{
    public Guid UserId { get; private set; }
    public string TokenHash { get; private set; } = default!;
    public DateTimeOffset ExpiresAt { get; private set; }
    public DateTimeOffset? RevokedAt { get; private set; }
    public string? ReplacedByHash { get; private set; }
    public string? DeviceInfo { get; private set; }

    private RefreshToken() { }

    public static RefreshToken Create(Guid userId, string tokenHash, DateTimeOffset expiresAt, string? deviceInfo)
        => new() { UserId = userId, TokenHash = tokenHash, ExpiresAt = expiresAt, DeviceInfo = deviceInfo };

    public bool IsActive => RevokedAt is null && ExpiresAt > DateTimeOffset.UtcNow;

    public void Revoke(string? replacedByHash = null)
    {
        RevokedAt = DateTimeOffset.UtcNow;
        ReplacedByHash = replacedByHash;
        Touch();
    }
}

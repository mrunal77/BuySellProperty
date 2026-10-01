using BuildingBlocks.Auth;
using Identity.Domain;
using SharedKernel;

namespace Identity.Application;

public interface IAuthService
{
    Task<Result<AuthResponse>> RegisterAsync(RegisterRequest req, CancellationToken ct = default);
    Task<Result<AuthResponse>> LoginAsync(LoginRequest req, CancellationToken ct = default);
    Task<Result<AuthResponse>> RefreshAsync(RefreshRequest req, CancellationToken ct = default);
    Task<Result> LogoutAsync(string refreshToken, CancellationToken ct = default);
    Task<Result<User>> GetByIdAsync(Guid id, CancellationToken ct = default);
}

public sealed class AuthService(
    IIdentityStore store,
    IPasswordHasher hasher,
    ITokenIssuer issuer) : IAuthService
{

    public async Task<Result<AuthResponse>> RegisterAsync(RegisterRequest req, CancellationToken ct = default)
    {
        var existing = await store.FindByEmailAsync(req.Email, ct);
        if (existing is not null)
            return Result<AuthResponse>.Failure(Error.Conflict("auth.email_taken", "Email already registered."));

        var roles = req.Roles is { Length: > 0 } ? req.Roles : [req.UserType];
        var created = User.Create(req.Email, hasher.Hash(req.Password), req.UserType, req.Phone, roles);
        if (created.IsFailure) return Result<AuthResponse>.Failure(created.Error!);

        await store.AddUserAsync(created.Value!, ct);
        return Result<AuthResponse>.Success(await issuer.IssueAsync(created.Value!, null, ct));
    }

    public async Task<Result<AuthResponse>> LoginAsync(LoginRequest req, CancellationToken ct = default)
    {
        var user = await store.FindByEmailAsync(req.Email, ct);
        if (user is null || !user.IsActive || !hasher.Verify(req.Password, user.PasswordHash))
            return Result<AuthResponse>.Failure(Error.Unauthorized("auth.invalid_credentials", "Invalid email or password."));
        return Result<AuthResponse>.Success(await issuer.IssueAsync(user, req.DeviceInfo, ct));
    }

    public async Task<Result<AuthResponse>> RefreshAsync(RefreshRequest req, CancellationToken ct = default)
    {
        var hash = JwtTokenService.Hash(req.RefreshToken);
        var stored = await store.FindRefreshTokenAsync(hash, ct);
        if (stored is null || !stored.IsActive)
            return Result<AuthResponse>.Failure(Error.Unauthorized("auth.invalid_refresh", "Invalid refresh token."));
        var user = await store.FindByIdAsync(stored.UserId, ct);
        if (user is null || !user.IsActive)
            return Result<AuthResponse>.Failure(Error.Unauthorized("auth.user_inactive", "User inactive."));

        stored.Revoke(JwtTokenService.Hash(JwtTokenService.NewRefreshToken()));
        await store.UpdateRefreshTokenAsync(stored, ct);
        return Result<AuthResponse>.Success(await issuer.IssueAsync(user, req.DeviceInfo, ct));
    }

    public async Task<Result> LogoutAsync(string refreshToken, CancellationToken ct = default)
    {
        var stored = await store.FindRefreshTokenAsync(JwtTokenService.Hash(refreshToken), ct);
        if (stored is null) return Result.Success();
        stored.Revoke();
        await store.UpdateRefreshTokenAsync(stored, ct);
        return Result.Success();
    }

    public async Task<Result<User>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var user = await store.FindByIdAsync(id, ct);
        return user is null
            ? Result<User>.Failure(Error.NotFound("user.not_found", "User not found."))
            : Result<User>.Success(user);
    }
}

public interface IIdentityStore
{
    Task<User?> FindByEmailAsync(string email, CancellationToken ct = default);
    Task<User?> FindByPhoneAsync(string phone, CancellationToken ct = default);
    Task<User?> FindByIdAsync(Guid id, CancellationToken ct = default);
    Task AddUserAsync(User user, CancellationToken ct = default);
    Task<RefreshToken?> FindRefreshTokenAsync(string hash, CancellationToken ct = default);
    Task AddRefreshTokenAsync(RefreshToken token, CancellationToken ct = default);
    Task UpdateRefreshTokenAsync(RefreshToken token, CancellationToken ct = default);
}

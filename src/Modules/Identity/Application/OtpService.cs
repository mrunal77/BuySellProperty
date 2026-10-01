using System.Security.Cryptography;
using BuildingBlocks.Auth;
using Identity.Domain;
using Microsoft.Extensions.Options;
using SharedKernel;

namespace Identity.Application;

/// <summary>Shared access+refresh issuance so password and OTP flows stay identical.</summary>
public interface ITokenIssuer
{
    Task<AuthResponse> IssueAsync(User user, string? deviceInfo, CancellationToken ct = default);
}

public sealed class TokenIssuer(
    IIdentityStore store,
    JwtTokenService tokens,
    IOptions<JwtOptions> jwtOptions) : ITokenIssuer
{
    private readonly JwtOptions _jwt = jwtOptions.Value;

    public async Task<AuthResponse> IssueAsync(User user, string? deviceInfo, CancellationToken ct = default)
    {
        var access = tokens.CreateAccessToken(user.Id, user.Email, user.UserRoles, user.UserType);
        var refresh = JwtTokenService.NewRefreshToken();
        await store.AddRefreshTokenAsync(
            RefreshToken.Create(user.Id, JwtTokenService.Hash(refresh),
                DateTimeOffset.UtcNow.AddDays(_jwt.RefreshTokenDays), deviceInfo), ct);
        return new(user.Id, user.Email, user.UserType, [.. user.UserRoles], access, refresh);
    }
}

public sealed class OtpService(
    IOtpStore codes,
    IIdentityStore users,
    IPasswordHasher hasher,
    JwtTokenService tokens,
    ITokenIssuer issuer,
    IOptions<OtpOptions> otpOptions,
    IOtpSender sender) : IOtpService
{
    private const string Purpose = "otp";
    private readonly OtpOptions _otp = otpOptions.Value;

    public async Task<Result<OtpRequested>> RequestAsync(OtpRequestRequest req, CancellationToken ct = default)
    {
        var phone = PhoneNumber.Normalize(req.Phone);
        if (phone.IsFailure) return Result<OtpRequested>.Failure(phone.Error!);

        var latest = await codes.FindLatestAsync(phone.Value!, ct);
        if (latest is not null && latest.IsUsable(_otp.MaxAttempts) &&
            latest.CreatedAt > DateTimeOffset.UtcNow.AddSeconds(-_otp.CooldownSeconds))
        {
            return Result<OtpRequested>.Failure(Error.Conflict("auth.otp_cooldown",
                $"Please wait {(int)(latest.CreatedAt.AddSeconds(_otp.CooldownSeconds) - DateTimeOffset.UtcNow).TotalSeconds}s before requesting a new code."));
        }

        var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
        var entity = OtpCode.Create(phone.Value!, JwtTokenService.Hash(code), TimeSpan.FromMinutes(_otp.TtlMinutes));
        await codes.AddAsync(entity, ct);
        await sender.SendAsync(phone.Value!, code, ct);

        return Result<OtpRequested>.Success(new OtpRequested(phone.Value!, PhoneNumber.Mask(phone.Value!), _otp.TtlMinutes * 60) { RawCode = code });
    }

    public async Task<Result<OtpVerified>> VerifyAsync(OtpVerifyRequest req, CancellationToken ct = default)
    {
        var phone = PhoneNumber.Normalize(req.Phone);
        if (phone.IsFailure) return Result<OtpVerified>.Failure(phone.Error!);

        var latest = await codes.FindLatestAsync(phone.Value!, ct);
        if (latest is null || !latest.IsUsable(_otp.MaxAttempts))
            return Result<OtpVerified>.Failure(Error.Unauthorized("auth.invalid_otp", "Invalid or expired code."));

        if (!CryptographicOperations.FixedTimeEquals(
                System.Text.Encoding.UTF8.GetBytes(latest.CodeHash),
                System.Text.Encoding.UTF8.GetBytes(JwtTokenService.Hash(req.Code.Trim()))))
        {
            latest.RegisterFailure();
            if (!latest.IsUsable(_otp.MaxAttempts)) latest.Consume();
            await codes.UpdateAsync(latest, ct);
            var left = _otp.MaxAttempts - latest.Attempts;
            return Result<OtpVerified>.Failure(Error.Unauthorized("auth.invalid_otp",
                left > 0 ? $"Wrong code. {left} attempt(s) left." : "Too many wrong attempts. Request a new code."));
        }

        latest.Consume();
        await codes.UpdateAsync(latest, ct);

        var existing = await users.FindByPhoneAsync(phone.Value!, ct);
        var otpToken = tokens.CreatePurposeToken(Purpose, phone.Value!, _otp.OtpTokenMinutes);
        return Result<OtpVerified>.Success(new(otpToken, existing is null, PhoneNumber.Mask(phone.Value!)));
    }

    public async Task<Result<AuthResponse>> LoginAsync(OtpLoginRequest req, CancellationToken ct = default)
    {
        if (!tokens.TryValidatePurposeToken(req.OtpToken, Purpose, out var phone) || phone is null)
            return Result<AuthResponse>.Failure(Error.Unauthorized("auth.invalid_otp_token", "Verification expired. Please verify again."));
        var user = await users.FindByPhoneAsync(phone, ct);
        if (user is null || !user.IsActive)
            return Result<AuthResponse>.Failure(Error.Unauthorized("auth.user_inactive", "Account not found or inactive."));
        return Result<AuthResponse>.Success(await issuer.IssueAsync(user, "otp", ct));
    }

    public async Task<Result<AuthResponse>> RegisterAsync(OtpRegisterRequest req, CancellationToken ct = default)
    {
        if (!tokens.TryValidatePurposeToken(req.OtpToken, Purpose, out var tokenPhone) || tokenPhone is null)
            return Result<AuthResponse>.Failure(Error.Unauthorized("auth.invalid_otp_token", "Verification expired. Please verify again."));

        var phone = PhoneNumber.Normalize(req.Phone);
        if (phone.IsFailure) return Result<AuthResponse>.Failure(phone.Error!);
        if (!string.Equals(phone.Value, tokenPhone, StringComparison.Ordinal))
            return Result<AuthResponse>.Failure(Error.Validation("auth.phone_mismatch", "Verified number does not match."));

        if (await users.FindByEmailAsync(req.Email, ct) is not null)
            return Result<AuthResponse>.Failure(Error.Conflict("auth.email_taken", "Email already registered."));
        if (await users.FindByPhoneAsync(phone.Value!, ct) is not null)
            return Result<AuthResponse>.Failure(Error.Conflict("auth.phone_taken", "This mobile number is already registered. Try logging in."));

        var created = User.Create(req.Email, hasher.Hash(req.Password), req.UserType, phone.Value, [req.UserType]);
        if (created.IsFailure) return Result<AuthResponse>.Failure(created.Error!);
        await users.AddUserAsync(created.Value!, ct);
        return Result<AuthResponse>.Success(await issuer.IssueAsync(created.Value!, "otp", ct));
    }
}

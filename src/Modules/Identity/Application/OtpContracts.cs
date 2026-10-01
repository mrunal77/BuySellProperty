using FluentValidation;
using Identity.Domain;

namespace Identity.Application;

public sealed record OtpRequestRequest(string Phone);
public sealed record OtpRequested(string Phone, string MaskedPhone, int ExpiresInSeconds)
{
    // Carries the raw code ONLY so the controller can expose it in Development.
    // Never serialized to clients in non-dev environments.
    public string RawCode { get; init; } = "";
}
public sealed record OtpVerifyRequest(string Phone, string Code);
public sealed record OtpVerified(string OtpToken, bool IsNewUser, string MaskedPhone);
public sealed record OtpLoginRequest(string OtpToken);
public sealed record OtpRegisterRequest(string OtpToken, string Phone, string Email, string Password, string UserType);

public sealed class OtpRequestValidator : AbstractValidator<OtpRequestRequest>
{
    public OtpRequestValidator()
    {
        RuleFor(x => x.Phone).Must(p => PhoneNumber.Normalize(p).IsSuccess).WithMessage("Enter a valid mobile number.");
    }
}

public sealed class OtpVerifyValidator : AbstractValidator<OtpVerifyRequest>
{
    public OtpVerifyValidator()
    {
        RuleFor(x => x.Phone).Must(p => PhoneNumber.Normalize(p).IsSuccess).WithMessage("Enter a valid mobile number.");
        RuleFor(x => x.Code).Matches(@"^\d{4,8}$").WithMessage("Enter the 6-digit code.");
    }
}

public sealed class OtpRegisterValidator : AbstractValidator<OtpRegisterRequest>
{
    public OtpRegisterValidator()
    {
        RuleFor(x => x.OtpToken).NotEmpty();
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(256);
        RuleFor(x => x.Password).NotEmpty().MinimumLength(8).MaximumLength(128);
        RuleFor(x => x.UserType).NotEmpty().Must(t => Domain.Roles.All.Contains(t)).WithMessage("Unknown user type.");
        RuleFor(x => x.Phone).Must(p => PhoneNumber.Normalize(p).IsSuccess).WithMessage("Enter a valid mobile number.");
    }
}

public sealed class OtpOptions
{
    public const string SectionName = "Otp";
    public int TtlMinutes { get; set; } = 5;
    public int CooldownSeconds { get; set; } = 60;
    public int MaxAttempts { get; set; } = 5;
    public int OtpTokenMinutes { get; set; } = 10;
    public bool ExposeCodesInDev { get; set; } = true;
}

/// <summary>SMS gateway abstraction. Production: plug in MSG91/Twilio/etc.</summary>
public interface IOtpSender
{
    Task SendAsync(string phone, string code, CancellationToken ct = default);
}

public interface IOtpStore
{
    Task<OtpCode?> FindLatestAsync(string phone, CancellationToken ct = default);
    Task AddAsync(OtpCode code, CancellationToken ct = default);
    Task UpdateAsync(OtpCode code, CancellationToken ct = default);
}

public interface IOtpService
{
    Task<SharedKernel.Result<OtpRequested>> RequestAsync(OtpRequestRequest req, CancellationToken ct = default);
    Task<SharedKernel.Result<OtpVerified>> VerifyAsync(OtpVerifyRequest req, CancellationToken ct = default);
    Task<SharedKernel.Result<AuthResponse>> LoginAsync(OtpLoginRequest req, CancellationToken ct = default);
    Task<SharedKernel.Result<AuthResponse>> RegisterAsync(OtpRegisterRequest req, CancellationToken ct = default);
}

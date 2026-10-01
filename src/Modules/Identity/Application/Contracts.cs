using FluentValidation;

namespace Identity.Application;

public sealed record RegisterRequest(string Email, string Password, string UserType, string? Phone, string[]? Roles);
public sealed record LoginRequest(string Email, string Password, string? DeviceInfo);
public sealed record RefreshRequest(string RefreshToken, string? DeviceInfo);
public sealed record AuthResponse(Guid UserId, string Email, string UserType, string[] Roles, string AccessToken, string RefreshToken);

public sealed class RegisterValidator : AbstractValidator<RegisterRequest>
{
    public RegisterValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(256);
        RuleFor(x => x.Password).NotEmpty().MinimumLength(8).MaximumLength(128);
        RuleFor(x => x.UserType).NotEmpty().Must(t => Domain.Roles.All.Contains(t)).WithMessage("Unknown user type.");
        RuleFor(x => x.Phone).Must(p => Domain.PhoneNumber.Normalize(p).IsSuccess).When(x => !string.IsNullOrWhiteSpace(x.Phone)).WithMessage("Enter a valid mobile number.");
    }
}

public sealed class LoginValidator : AbstractValidator<LoginRequest>
{
    public LoginValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress();
        RuleFor(x => x.Password).NotEmpty();
    }
}

public interface IPasswordHasher
{
    string Hash(string password);
    bool Verify(string password, string hash);
}

public sealed class BCryptPasswordHasher : IPasswordHasher
{
    public string Hash(string password) => BCrypt.Net.BCrypt.HashPassword(password);
    public bool Verify(string password, string hash)
    {
        try { return BCrypt.Net.BCrypt.Verify(password, hash); }
        catch { return false; }
    }
}

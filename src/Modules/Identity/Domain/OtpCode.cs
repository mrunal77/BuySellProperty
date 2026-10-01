using SharedKernel;

namespace Identity.Domain;

/// <summary>Normalized phone helper. Canonical form: optional leading '+'
/// followed by 8..15 digits (E.164-compatible).</summary>
public static class PhoneNumber
{
    public static Result<string> Normalize(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
            return Result<string>.Failure(Error.Validation("auth.invalid_phone", "Enter a valid mobile number."));
        var t = raw.Trim().Replace(" ", "").Replace("-", "").Replace("(", "").Replace(")", "");
        if (!System.Text.RegularExpressions.Regex.IsMatch(t, @"^\+?[1-9]\d{7,14}$"))
            return Result<string>.Failure(Error.Validation("auth.invalid_phone", "Enter a valid mobile number."));
        return Result<string>.Success(t);
    }

    /// e.g. +919876543210 -> +91 ••••• 3210
    public static string Mask(string normalized)
    {
        if (normalized.Length < 8) return "••••";
        return $"{normalized[..3]} ••••• {normalized[^4..]}";
    }
}

/// <summary>Single-use login/registration code sent over SMS (dev: logged).</summary>
public sealed class OtpCode : Entity
{
    public string Phone { get; private set; } = default!;
    public string CodeHash { get; private set; } = default!;
    public DateTimeOffset ExpiresAt { get; private set; }
    public int Attempts { get; private set; }
    public DateTimeOffset? ConsumedAt { get; private set; }

    private OtpCode() { }

    public static OtpCode Create(string phone, string codeHash, TimeSpan ttl)
        => new() { Phone = phone, CodeHash = codeHash, ExpiresAt = DateTimeOffset.UtcNow.Add(ttl) };

    public bool IsUsable(int maxAttempts)
        => ConsumedAt is null && ExpiresAt > DateTimeOffset.UtcNow && Attempts < maxAttempts;

    public void RegisterFailure() { Attempts++; Touch(); }
    public void Consume() { ConsumedAt = DateTimeOffset.UtcNow; Touch(); }
}

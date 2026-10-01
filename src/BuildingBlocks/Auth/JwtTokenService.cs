using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace BuildingBlocks.Auth;

public sealed class JwtTokenService(Microsoft.Extensions.Options.IOptions<JwtOptions> options)
{
    private readonly JwtOptions _options = options.Value;

    public string CreateAccessToken(Guid userId, string email, IEnumerable<string> roles, string userType)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.Secret));
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new(JwtRegisteredClaimNames.Email, email),
            new("userType", userType),
        };
        claims.AddRange(roles.Select(r => new Claim(ClaimTypes.Role, r)));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_options.AccessTokenMinutes),
            signingCredentials: creds);
        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public static string NewRefreshToken() => Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));

    public static string Hash(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }

    /// Short-lived single-purpose token (e.g. purpose "otp", subject = verified phone).
    public string CreatePurposeToken(string purpose, string subject, int minutes)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.Secret));
        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: [new("purpose", purpose), new(JwtRegisteredClaimNames.Sub, subject)],
            expires: DateTime.UtcNow.AddMinutes(minutes),
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));
        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public bool TryValidatePurposeToken(string token, string purpose, out string? subject)
    {
        subject = null;
        try
        {
            // MapInboundClaims=false keeps "sub" as "sub" (default maps it to
            // ClaimTypes.NameIdentifier, which would break the lookup below).
            var handler = new JwtSecurityTokenHandler { MapInboundClaims = false };
            var principal = handler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuer = true, ValidIssuer = _options.Issuer,
                ValidateAudience = true, ValidAudience = _options.Audience,
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.Secret)),
                ValidateLifetime = true, ClockSkew = TimeSpan.FromMinutes(1),
            }, out _);
            if (principal.FindFirst("purpose")?.Value != purpose) return false;
            subject = principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
            return subject is not null;
        }
        catch
        {
            return false;
        }
    }
}

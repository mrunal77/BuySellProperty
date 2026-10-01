namespace BuildingBlocks.Auth;

public sealed class JwtOptions
{
    public const string SectionName = "Jwt";
    public string Issuer { get; set; } = "buysellproperty";
    public string Audience { get; set; } = "buysellproperty";
    public string Secret { get; set; } = "dev-only-super-secret-key-min-32-chars!!";
    public int AccessTokenMinutes { get; set; } = 15;
    public int RefreshTokenDays { get; set; } = 30;
}

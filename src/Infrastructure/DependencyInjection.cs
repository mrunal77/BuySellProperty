using BuildingBlocks.Auth;
using BuildingBlocks.Storage;
using Identity.Application;
using Infrastructure.Auth;
using Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
    {
        services.Configure<JwtOptions>(config.GetSection(JwtOptions.SectionName));
        services.Configure<StorageOptions>(config.GetSection(StorageOptions.SectionName));
        services.Configure<OtpOptions>(config.GetSection(OtpOptions.SectionName));

        var conn = config.GetConnectionString("Default") ?? "Host=localhost;Port=5432;Database=buysell;Username=postgres;Password=postgres";
        services.AddDbContext<AppDbContext>(o => o.UseNpgsql(conn, npg => npg.UseNetTopologySuite()));

        services.AddScoped<IIdentityStore, EfIdentityStore>();
        services.AddScoped<IOtpStore, EfOtpStore>();
        services.AddScoped<ITokenIssuer, TokenIssuer>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IOtpService, OtpService>();
        services.AddSingleton<IOtpSender, LogOtpSender>();
        services.AddScoped<IPasswordHasher, BCryptPasswordHasher>();
        services.AddSingleton<JwtTokenService>();
        services.AddSingleton<IFileStorage, LocalDiskStorage>();
        return services;
    }
}

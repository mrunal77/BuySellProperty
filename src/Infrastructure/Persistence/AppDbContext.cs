using Identity.Domain;
using Locations.Domain;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;
using Properties.Domain;
using Users.Domain;

namespace Infrastructure.Persistence;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<OtpCode> OtpCodes => Set<OtpCode>();
    public DbSet<UserProfile> Profiles => Set<UserProfile>();
    public DbSet<City> Cities => Set<City>();
    public DbSet<Locality> Localities => Set<Locality>();
    public DbSet<Property> Properties => Set<Property>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        base.OnModelCreating(b);
        b.HasPostgresExtension("postgis");
        b.HasPostgresExtension("citext");
        b.HasPostgresExtension("pg_trgm");

        // Identity
        b.Entity<User>(e =>
        {
            e.ToTable("users", "identity");
            e.HasKey(x => x.Id);
            e.Property(x => x.Email).HasColumnType("citext").IsRequired();
            e.HasIndex(x => x.Email).IsUnique();
            e.Property(x => x.UserRoles).HasColumnName("roles").HasColumnType("text[]");
            e.Property(x => x.UserType).HasColumnName("user_type");
            e.HasIndex(x => x.Phone).IsUnique();
        });
        b.Entity<OtpCode>(e =>
        {
            e.ToTable("otp_codes", "identity");
            e.HasKey(x => x.Id);
            e.Property(x => x.Phone).IsRequired().HasMaxLength(20);
            e.HasIndex(x => x.Phone);
        });
        b.Entity<RefreshToken>(e =>
        {
            e.ToTable("refresh_tokens", "identity");
            e.HasKey(x => x.Id);
            e.HasIndex(x => x.TokenHash).IsUnique();
            e.HasIndex(x => x.UserId);
        });

        // Users
        b.Entity<UserProfile>(e =>
        {
            e.ToTable("profiles", "users");
            e.HasKey(x => x.Id);
        });

        // Locations
        b.Entity<City>(e =>
        {
            e.ToTable("cities", "locations");
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).IsRequired().HasMaxLength(128);
        });
        b.Entity<Locality>(e =>
        {
            e.ToTable("localities", "locations");
            e.HasKey(x => x.Id);
            e.HasIndex(x => x.CityId);
        });

        // Properties — geo stored as lat/lng doubles + generated geography point for PostGIS queries.
        // KISS: keep Point out of domain; compute in queries via ST_MakePoint. GiST index via raw SQL in migration.
        b.Entity<Property>(e =>
        {
            e.ToTable("properties", "properties");
            e.HasKey(x => x.Id);
            e.Property(x => x.Title).IsRequired().HasMaxLength(200);
            e.HasIndex(x => new { x.CityId, x.Status, x.Price });
            e.HasIndex(x => x.Status);
        });

        Seed(b);
    }

    private static void Seed(ModelBuilder b)
    {
        var mumbai = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var puneId = Guid.Parse("22222222-2222-2222-2222-222222222222");
        var at = new DateTimeOffset(2026, 10, 1, 0, 0, 0, TimeSpan.Zero);
        b.Entity<City>().HasData(
            new { Id = mumbai, Name = "Mumbai", State = "Maharashtra", Latitude = 19.0760, Longitude = 72.8777, CreatedAt = at, UpdatedAt = at },
            new { Id = puneId, Name = "Pune", State = "Maharashtra", Latitude = 18.5204, Longitude = 73.8567, CreatedAt = at, UpdatedAt = at },
            new { Id = Guid.Parse("33333333-3333-3333-3333-333333333333"), Name = "Bengaluru", State = "Karnataka", Latitude = 12.9716, Longitude = 77.5946, CreatedAt = at, UpdatedAt = at });
    }
}

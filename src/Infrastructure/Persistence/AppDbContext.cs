using Amenities.Domain;
using Chat.Domain;
using Enquiries.Domain;
using Favorites.Domain;
using Identity.Domain;
using Locations.Domain;
using Microsoft.EntityFrameworkCore;
using Properties.Domain;
using SiteVisits.Domain;
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
    public DbSet<Favorite> Favorites => Set<Favorite>();
    public DbSet<Enquiry> Enquiries => Set<Enquiry>();
    public DbSet<SiteVisit> SiteVisits => Set<SiteVisit>();
    public DbSet<Conversation> Conversations => Set<Conversation>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
    public DbSet<Amenity> Amenities => Set<Amenity>();

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

        // Properties
        b.Entity<Property>(e =>
        {
            e.ToTable("properties", "properties");
            e.HasKey(x => x.Id);
            e.Property(x => x.Title).IsRequired().HasMaxLength(200);
            e.Property(x => x.ImageUrls).HasColumnName("image_urls").HasColumnType("text[]");
            e.Property(x => x.Amenities).HasColumnName("amenities").HasColumnType("text[]");
            e.Property(x => x.Details).HasColumnName("details").HasColumnType("jsonb");
            e.Property(x => x.ContactName).HasColumnName("contact_name").HasMaxLength(120);
            e.Property(x => x.ContactPhone).HasColumnName("contact_phone").HasMaxLength(30);
            e.Property(x => x.WhatsApp).HasColumnName("whatsapp").HasMaxLength(30);
            e.HasIndex(x => new { x.CityId, x.Status, x.Price });
            e.HasIndex(x => x.Status);
        });

        // Engagement: Favorites
        b.Entity<Favorite>(e =>
        {
            e.ToTable("favorites", "engagement");
            e.HasKey(x => x.Id);
            e.HasIndex(x => new { x.UserId, x.PropertyId }).IsUnique();
        });

        // Engagement: Enquiries
        b.Entity<Enquiry>(e =>
        {
            e.ToTable("enquiries", "engagement");
            e.HasKey(x => x.Id);
            e.HasIndex(x => x.PropertyId);
            e.HasIndex(x => x.BuyerId);
            e.HasIndex(x => x.OwnerId);
        });

        // Engagement: SiteVisits
        b.Entity<SiteVisit>(e =>
        {
            e.ToTable("site_visits", "engagement");
            e.HasKey(x => x.Id);
            e.HasIndex(x => x.PropertyId);
            e.HasIndex(x => x.BuyerId);
            e.HasIndex(x => x.OwnerId);
        });

        // Engagement: Chat
        b.Entity<Conversation>(e =>
        {
            e.ToTable("conversations", "engagement");
            e.HasKey(x => x.Id);
            e.HasIndex(x => x.Participant1Id);
            e.HasIndex(x => x.Participant2Id);
        });
        b.Entity<ChatMessage>(e =>
        {
            e.ToTable("messages", "engagement");
            e.HasKey(x => x.Id);
            e.HasIndex(x => x.ConversationId);
        });

        // Amenities Master
        b.Entity<Amenity>(e =>
        {
            e.ToTable("amenities", "amenities");
            e.HasKey(x => x.Id);
            e.Property(x => x.Name).IsRequired().HasMaxLength(100);
        });

        Seed(b);
    }

    private static void Seed(ModelBuilder b)
    {
        var mumbai = Guid.Parse("11111111-1111-1111-1111-111111111111");
        var puneId = Guid.Parse("22222222-2222-2222-2222-222222222222");
        var blrId = Guid.Parse("33333333-3333-3333-3333-333333333333");
        var at = new DateTimeOffset(2026, 10, 1, 0, 0, 0, TimeSpan.Zero);

        b.Entity<City>().HasData(
            new { Id = mumbai, Name = "Mumbai", State = "Maharashtra", Latitude = 19.0760, Longitude = 72.8777, CreatedAt = at, UpdatedAt = at },
            new { Id = puneId, Name = "Pune", State = "Maharashtra", Latitude = 18.5204, Longitude = 73.8567, CreatedAt = at, UpdatedAt = at },
            new { Id = blrId, Name = "Bengaluru", State = "Karnataka", Latitude = 12.9716, Longitude = 77.5946, CreatedAt = at, UpdatedAt = at });

        // Master Amenities
        var a1 = Guid.Parse("a1111111-1111-1111-1111-111111111111");
        var a2 = Guid.Parse("a2222222-2222-2222-2222-222222222222");
        var a3 = Guid.Parse("a3333333-3333-3333-3333-333333333333");
        var a4 = Guid.Parse("a4444444-4444-4444-4444-444444444444");
        var a5 = Guid.Parse("a5555555-5555-5555-5555-555555555555");
        var a6 = Guid.Parse("a6666666-6666-6666-6666-666666666666");

        b.Entity<Amenity>().HasData(
            new { Id = a1, Name = "Swimming Pool", Icon = "pool", Category = "Leisure", CreatedAt = at, UpdatedAt = at },
            new { Id = a2, Name = "Gymnasium", Icon = "fitness_center", Category = "Fitness", CreatedAt = at, UpdatedAt = at },
            new { Id = a3, Name = "24x7 Security", Icon = "security", Category = "Safety", CreatedAt = at, UpdatedAt = at },
            new { Id = a4, Name = "Power Backup", Icon = "bolt", Category = "Utilities", CreatedAt = at, UpdatedAt = at },
            new { Id = a5, Name = "Reserved Parking", Icon = "local_parking", Category = "Convenience", CreatedAt = at, UpdatedAt = at },
            new { Id = a6, Name = "Clubhouse", Icon = "meeting_room", Category = "Community", CreatedAt = at, UpdatedAt = at });
    }
}

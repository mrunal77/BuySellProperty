using Identity.Domain;
using Locations.Domain;
using Microsoft.EntityFrameworkCore;
using Properties.Domain;

namespace Infrastructure.Persistence;

public static class DbSeeder
{
    public static async Task SeedAsync(AppDbContext db)
    {
        if (await db.Properties.AnyAsync()) return;

        var mumbai = await db.Cities.FirstOrDefaultAsync(c => c.Name == "Mumbai");
        var pune = await db.Cities.FirstOrDefaultAsync(c => c.Name == "Pune");
        var blr = await db.Cities.FirstOrDefaultAsync(c => c.Name == "Bengaluru");

        if (mumbai is null || pune is null || blr is null) return;

        // Seed demo owner user if not exists
        var owner = await db.Users.FirstOrDefaultAsync(u => u.Email == "owner@example.com");
        if (owner is null)
        {
            var hash = BCrypt.Net.BCrypt.HashPassword("Owner123!");
            var ownerRes = User.Create("owner@example.com", hash, Roles.Owner, "9876543210", [Roles.Owner]);
            if (ownerRes.IsSuccess)
            {
                owner = ownerRes.Value!;
                db.Users.Add(owner);
            }
        }

        // Seed demo buyer user if not exists
        var buyer = await db.Users.FirstOrDefaultAsync(u => u.Email == "buyer@example.com");
        if (buyer is null)
        {
            var hash = BCrypt.Net.BCrypt.HashPassword("Buyer123!");
            var buyerRes = User.Create("buyer@example.com", hash, Roles.Customer, "9876543211", [Roles.Customer]);
            if (buyerRes.IsSuccess)
            {
                db.Users.Add(buyerRes.Value!);
            }
        }

        // Seed demo admin user if not exists
        var admin = await db.Users.FirstOrDefaultAsync(u => u.Email == "admin@example.com");
        if (admin is null)
        {
            var hash = BCrypt.Net.BCrypt.HashPassword("Admin123!");
            var adminRes = User.Create("admin@example.com", hash, Roles.Admin, "9876543212", [Roles.Admin]);
            if (adminRes.IsSuccess)
            {
                db.Users.Add(adminRes.Value!);
            }
        }

        await db.SaveChangesAsync();

        var ownerId = owner?.Id ?? Guid.NewGuid();

        var properties = new List<Property>
        {
            Property.Create(
                title: "Luxurious 3 BHK Sea View Apartment",
                description: "Spacious 3 BHK apartment with unobstructed sea view in Bandra West. Modern interiors, high floor, 2 dedicated car parking spots.",
                type: PropertyType.Apartment,
                listingType: ListingType.Sale,
                price: 32500000m,
                areaSqft: 1850,
                ownerId: ownerId,
                addressLine: "Carter Road, Bandra West",
                cityId: mumbai.Id,
                lat: 19.0596,
                lng: 72.8295,
                bedrooms: 3,
                bathrooms: 3,
                furnishing: Furnishing.Furnished,
                imageUrls: [
                    "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80",
                    "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80",
                    "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80"
                ],
                amenities: ["Swimming Pool", "Gymnasium", "24x7 Security", "Power Backup", "Reserved Parking"]
            ).Value!,

            Property.Create(
                title: "Modern 2 BHK Flat in Koregaon Park",
                description: "Sunlit 2 BHK fully furnished apartment in prime Koregaon Park. Walking distance from fine dining, cafes, and green parks.",
                type: PropertyType.Apartment,
                listingType: ListingType.Rent,
                price: 45000m,
                areaSqft: 1100,
                ownerId: ownerId,
                addressLine: "Lane 7, Koregaon Park",
                cityId: pune.Id,
                lat: 18.5362,
                lng: 73.8940,
                bedrooms: 2,
                bathrooms: 2,
                furnishing: Furnishing.Furnished,
                imageUrls: [
                    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80",
                    "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80"
                ],
                amenities: ["24x7 Security", "Power Backup", "Reserved Parking", "Clubhouse"]
            ).Value!,

            Property.Create(
                title: "Premium 4 BHK Independent Villa in Indiranagar",
                description: "Exclusive gated villa featuring private garden, terrace lounge, Italian marble flooring, and smart home automation.",
                type: PropertyType.Villa,
                listingType: ListingType.Sale,
                price: 48000000m,
                areaSqft: 3400,
                ownerId: ownerId,
                addressLine: "100 Feet Road, Indiranagar",
                cityId: blr.Id,
                lat: 12.9784,
                lng: 77.6408,
                bedrooms: 4,
                bathrooms: 4,
                furnishing: Furnishing.SemiFurnished,
                imageUrls: [
                    "https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=800&q=80",
                    "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=800&q=80"
                ],
                amenities: ["Swimming Pool", "Gymnasium", "24x7 Security", "Clubhouse"]
            ).Value!,

            Property.Create(
                title: "Commercial Office Space in Hiranandani Powai",
                description: "Ready-to-move Grade A commercial office space with 40 workstations, 2 conference rooms, cafeteria, and central AC.",
                type: PropertyType.Commercial,
                listingType: ListingType.Lease,
                price: 220000m,
                areaSqft: 2500,
                ownerId: ownerId,
                addressLine: "Business Park, Hiranandani Gardens, Powai",
                cityId: mumbai.Id,
                lat: 19.1197,
                lng: 72.9050,
                bedrooms: 0,
                bathrooms: 2,
                furnishing: Furnishing.Furnished,
                imageUrls: [
                    "https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=800&q=80",
                    "https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=800&q=80"
                ],
                amenities: ["Power Backup", "24x7 Security", "Reserved Parking"]
            ).Value!
        };

        foreach (var p in properties)
        {
            p.Publish();
            db.Properties.Add(p);
        }

        await db.SaveChangesAsync();
    }
}

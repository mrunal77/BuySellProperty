using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using BuildingBlocks.Api;
using Favorites.Domain;
using Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Route("api/v1/favorites")]
[Authorize]
public sealed class FavoritesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IResult> GetMyFavorites(CancellationToken ct)
    {
        var userId = CurrentUserId();
        if (userId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var propertyIds = await db.Favorites
            .Where(f => f.UserId == userId.Value)
            .OrderByDescending(f => f.CreatedAt)
            .Select(f => f.PropertyId)
            .ToListAsync(ct);

        var properties = await db.Properties
            .Where(p => propertyIds.Contains(p.Id))
            .ToListAsync(ct);

        var ordered = propertyIds
            .Select(id => properties.FirstOrDefault(p => p.Id == id))
            .Where(p => p is not null)
            .ToList();

        return Results.Ok(ordered.Select(p => new
        {
            p!.Id, p.Title, p.Description, propertyType = p.PropertyType.ToString(),
            listingType = p.ListingType.ToString(), p.Price, p.AreaSqft,
            p.Bedrooms, p.Bathrooms, furnishing = p.Furnishing.ToString(),
            status = p.Status.ToString(), p.OwnerId, p.AddressLine, p.CityId, p.LocalityId,
            p.Latitude, p.Longitude, imageUrls = p.ImageUrls, amenities = p.Amenities,
            p.CreatedAt, p.PublishedAt,
        }));
    }

    [HttpPost]
    public async Task<IResult> AddFavorite([FromBody] AddFavoriteRequest req, CancellationToken ct)
    {
        var userId = CurrentUserId();
        if (userId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var property = await db.Properties.FirstOrDefaultAsync(p => p.Id == req.PropertyId, ct);
        if (property is null) return Errors.Problem("property.not_found", "Property not found.", 404);

        var existing = await db.Favorites.FirstOrDefaultAsync(f => f.UserId == userId.Value && f.PropertyId == req.PropertyId, ct);
        if (existing is not null) return Results.Ok(new { message = "Already in favorites." });

        var created = Favorite.Create(userId.Value, req.PropertyId);
        if (created.IsFailure) return Errors.Problem(created.Error!.Code, created.Error.Message, 400);

        db.Favorites.Add(created.Value!);
        await db.SaveChangesAsync(ct);
        return Results.Created($"/api/v1/favorites/{req.PropertyId}", new { message = "Added to favorites." });
    }

    [HttpDelete("{propertyId:guid}")]
    public async Task<IResult> RemoveFavorite(Guid propertyId, CancellationToken ct)
    {
        var userId = CurrentUserId();
        if (userId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var existing = await db.Favorites.FirstOrDefaultAsync(f => f.UserId == userId.Value && f.PropertyId == propertyId, ct);
        if (existing is null) return Results.NoContent();

        db.Favorites.Remove(existing);
        await db.SaveChangesAsync(ct);
        return Results.NoContent();
    }

    private Guid? CurrentUserId()
    {
        var sub = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(sub, out var id) ? id : null;
    }
}

public sealed record AddFavoriteRequest(Guid PropertyId);

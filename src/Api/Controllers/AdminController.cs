using BuildingBlocks.Api;
using Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Properties.Domain;

namespace Api.Controllers;

[ApiController]
[Route("api/v1/admin")]
[Authorize(Roles = "Admin")]
public sealed class AdminController(AppDbContext db) : ControllerBase
{
    [HttpGet("users")]
    public async Task<IResult> GetUsers([FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var query = db.Users.OrderByDescending(u => u.CreatedAt);
        var total = await query.LongCountAsync(ct);
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);

        return Results.Ok(new
        {
            data = items.Select(u => new
            {
                u.Id, u.Email, u.Phone, u.UserType, roles = u.UserRoles, u.IsActive, u.CreatedAt
            }),
            page, pageSize, total
        });
    }

    [HttpPatch("users/{id:guid}/status")]
    public async Task<IResult> ToggleUserStatus(Guid id, [FromBody] UpdateUserStatusRequest req, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == id, ct);
        if (user is null) return Errors.Problem("user.not_found", "User not found.", 404);

        if (req.IsActive) user.Activate();
        else user.Deactivate();

        await db.SaveChangesAsync(ct);
        return Results.Ok(new { user.Id, user.Email, user.IsActive });
    }

    [HttpGet("listings/pending")]
    public async Task<IResult> GetPendingListings(CancellationToken ct)
    {
        var pending = await db.Properties
            .Where(p => p.Status == PropertyStatus.Draft || p.Status == PropertyStatus.Paused)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync(ct);

        return Results.Ok(pending.Select(p => new
        {
            p.Id, p.Title, p.Description, propertyType = p.PropertyType.ToString(),
            listingType = p.ListingType.ToString(), p.Price, p.AreaSqft,
            status = p.Status.ToString(), p.OwnerId, p.AddressLine, p.CityId,
            p.Latitude, p.Longitude, imageUrls = p.ImageUrls, amenities = p.Amenities,
            p.CreatedAt
        }));
    }

    [HttpPost("listings/{id:guid}/moderate")]
    public async Task<IResult> ModerateListing(Guid id, [FromBody] ModerateListingRequest req, CancellationToken ct)
    {
        var property = await db.Properties.FirstOrDefaultAsync(p => p.Id == id, ct);
        if (property is null) return Errors.Problem("property.not_found", "Property not found.", 404);

        if (req.Approve)
        {
            var res = property.Publish();
            if (res.IsFailure) return Errors.Problem(res.Error!.Code, res.Error.Message, 400);
        }
        else
        {
            var res = property.Reject(req.Reason ?? "Listing rejected by moderator.");
            if (res.IsFailure) return Errors.Problem(res.Error!.Code, res.Error.Message, 400);
        }

        await db.SaveChangesAsync(ct);
        return Results.Ok(new { property.Id, status = property.Status.ToString() });
    }
}

public sealed record UpdateUserStatusRequest(bool IsActive);
public sealed record ModerateListingRequest(bool Approve, string? Reason = null);

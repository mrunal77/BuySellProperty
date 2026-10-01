using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using BuildingBlocks.Api;
using Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Properties.Application;
using Properties.Domain;

namespace Api.Controllers;

[ApiController]
[Route("api/v1/properties")]
public sealed class PropertiesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    [AllowAnonymous]
    public async Task<IResult> Search(
        [FromQuery] Guid? cityId, [FromQuery] Guid? localityId,
        [FromQuery] PropertyType? type, [FromQuery] ListingType? listingType,
        [FromQuery] decimal? minPrice, [FromQuery] decimal? maxPrice,
        [FromQuery] int? beds, [FromQuery] int? baths,
        [FromQuery] double? minArea, [FromQuery] double? maxArea,
        [FromQuery] double? lat, [FromQuery] double? lng, [FromQuery] double? radiusKm,
        [FromQuery] string sort = "newest", [FromQuery] int page = 1, [FromQuery] int pageSize = 20,
        [FromQuery] bool mine = false, [FromQuery] Guid? ownerId = null,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);
        radiusKm = Math.Min(radiusKm ?? 50, 50);

        var q = db.Properties.AsQueryable();
        if (mine)
        {
            var me = CurrentUserId();
            if (me is null) return Errors.Problem("auth.unauthorized", "Login required to view your listings.", 401);
            q = q.Where(p => p.OwnerId == me);
        }
        else
        {
            q = q.Where(p => p.Status == PropertyStatus.Active);
        }
        if (ownerId is not null) q = q.Where(p => p.OwnerId == ownerId);
        if (cityId is not null) q = q.Where(p => p.CityId == cityId);
        if (localityId is not null) q = q.Where(p => p.LocalityId == localityId);
        if (type is not null) q = q.Where(p => p.PropertyType == type);
        if (listingType is not null) q = q.Where(p => p.ListingType == listingType);
        if (minPrice is not null) q = q.Where(p => p.Price >= minPrice);
        if (maxPrice is not null) q = q.Where(p => p.Price <= maxPrice);
        if (beds is not null) q = q.Where(p => p.Bedrooms >= beds);
        if (baths is not null) q = q.Where(p => p.Bathrooms >= baths);
        if (minArea is not null) q = q.Where(p => p.AreaSqft >= minArea);
        if (maxArea is not null) q = q.Where(p => p.AreaSqft <= maxArea);

        // Geo: PostGIS ST_DWithin in production; Haversine fallback here keeps it DB-agnostic for MVP/tests.
        if (lat is not null && lng is not null && radiusKm is not null)
        {
            var lat0 = lat.Value; var lng0 = lng.Value; var r = radiusKm.Value;
            q = q.Where(p => 6371 * Math.Acos(Math.Cos(ToRad(lat0)) * Math.Cos(ToRad(p.Latitude)) *
                Math.Cos(ToRad(p.Longitude) - ToRad(lng0)) + Math.Sin(ToRad(lat0)) * Math.Sin(ToRad(p.Latitude))) <= r);
        }

        q = sort switch
        {
            "price_asc" => q.OrderBy(p => p.Price),
            "price_desc" => q.OrderByDescending(p => p.Price),
            "area_desc" => q.OrderByDescending(p => p.AreaSqft),
            _ => q.OrderByDescending(p => p.CreatedAt),
        };

        var total = await q.LongCountAsync(ct);
        var items = await q.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);
        return Results.Ok(new { data = items.Select(ToDto), page, pageSize, total });
    }

    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<IResult> Get(Guid id, CancellationToken ct)
    {
        var p = await db.Properties.FirstOrDefaultAsync(x => x.Id == id, ct);
        return p is null ? Errors.Problem("property.not_found", "Not found.", 404) : Results.Ok(ToDto(p));
    }

    [HttpPost]
    [Authorize(Roles = "Owner,Agent,Builder,Admin")]
    public async Task<IResult> Create([FromBody] CreatePropertyRequest req, CancellationToken ct)
    {
        var v = new CreatePropertyValidator().Validate(req);
        if (!v.IsValid) return Errors.Problem("property.validation", "Validation failed.", 400,
            v.Errors.Select(e => new { e.PropertyName, e.ErrorMessage }));
        var ownerId = CurrentUserId();
        if (ownerId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var created = Property.Create(req.Title, req.Description, req.PropertyType, req.ListingType,
            req.Price, req.AreaSqft, ownerId.Value, req.AddressLine, req.CityId,
            req.Latitude, req.Longitude, req.Bedrooms, req.Bathrooms, req.Furnishing, req.LocalityId);
        if (created.IsFailure) return Errors.Problem(created.Error!.Code, created.Error.Message, 400);

        db.Properties.Add(created.Value!);
        await db.SaveChangesAsync(ct);
        return Results.Created($"/api/v1/properties/{created.Value!.Id}", ToDto(created.Value));
    }

    [HttpPost("{id:guid}/publish")]
    [Authorize(Roles = "Owner,Agent,Builder,Admin")]
    public async Task<IResult> Publish(Guid id, CancellationToken ct)
    {
        var p = await db.Properties.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (p is null) return Errors.Problem("property.not_found", "Not found.", 404);
        if (!CanEdit(p)) return Errors.Problem("auth.forbidden", "Not your listing.", 403);
        var r = p.Publish();
        if (r.IsFailure) return Errors.Problem(r.Error!.Code, r.Error.Message, 409);
        await db.SaveChangesAsync(ct);
        return Results.Ok(ToDto(p));
    }

    [HttpPatch("{id:guid}")]
    [Authorize(Roles = "Owner,Agent,Builder,Admin")]
    public async Task<IResult> Update(Guid id, [FromBody] CreatePropertyRequest req, CancellationToken ct)
    {
        var p = await db.Properties.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (p is null) return Errors.Problem("property.not_found", "Not found.", 404);
        if (!CanEdit(p)) return Errors.Problem("auth.forbidden", "Not your listing.", 403);
        p.Update(req.Title, req.Description, req.Price, req.AreaSqft, req.Bedrooms, req.Bathrooms, req.Furnishing, req.AddressLine);
        await db.SaveChangesAsync(ct);
        return Results.Ok(ToDto(p));
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Owner,Agent,Builder,Admin")]
    public async Task<IResult> Delete(Guid id, CancellationToken ct)
    {
        var p = await db.Properties.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (p is null) return Errors.Problem("property.not_found", "Not found.", 404);
        if (!CanEdit(p)) return Errors.Problem("auth.forbidden", "Not your listing.", 403);
        db.Properties.Remove(p);
        await db.SaveChangesAsync(ct);
        return Results.NoContent();
    }

    private Guid? CurrentUserId()
    {
        var sub = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(sub, out var id) ? id : null;
    }

    private bool CanEdit(Property p)
    {
        if (User.IsInRole("Admin")) return true;
        var id = CurrentUserId();
        return id is not null && p.IsOwnedBy(id.Value);
    }

    private static double ToRad(double d) => d * Math.PI / 180.0;

    private static object ToDto(Property p) => new
    {
        p.Id, p.Title, p.Description, propertyType = p.PropertyType.ToString(),
        listingType = p.ListingType.ToString(), p.Price, p.AreaSqft,
        p.Bedrooms, p.Bathrooms, furnishing = p.Furnishing.ToString(),
        status = p.Status.ToString(), p.OwnerId, p.AddressLine, p.CityId, p.LocalityId,
        p.Latitude, p.Longitude, p.CreatedAt, p.PublishedAt,
    };
}

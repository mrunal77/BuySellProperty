using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using BuildingBlocks.Api;
using Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SiteVisits.Domain;

namespace Api.Controllers;

[ApiController]
[Route("api/v1/site-visits")]
[Authorize]
public sealed class SiteVisitsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IResult> GetSiteVisits([FromQuery] bool mine = false, CancellationToken ct = default)
    {
        var userId = CurrentUserId();
        if (userId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var query = db.SiteVisits.AsQueryable();
        if (mine)
        {
            query = query.Where(v => v.OwnerId == userId.Value);
        }
        else
        {
            query = query.Where(v => v.BuyerId == userId.Value);
        }

        var visits = await query.OrderByDescending(v => v.ScheduledAt).ToListAsync(ct);
        var propertyIds = visits.Select(v => v.PropertyId).Distinct().ToList();
        var properties = await db.Properties.Where(p => propertyIds.Contains(p.Id)).ToDictionaryAsync(p => p.Id, ct);

        return Results.Ok(visits.Select(v => new
        {
            v.Id,
            v.PropertyId,
            propertyTitle = properties.TryGetValue(v.PropertyId, out var p) ? p.Title : "Property",
            v.BuyerId,
            v.OwnerId,
            v.ScheduledAt,
            status = v.Status.ToString(),
            v.Notes,
            v.CreatedAt
        }));
    }

    [HttpPost]
    public async Task<IResult> ScheduleVisit([FromBody] ScheduleVisitRequest req, CancellationToken ct)
    {
        var buyerId = CurrentUserId();
        if (buyerId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var property = await db.Properties.FirstOrDefaultAsync(p => p.Id == req.PropertyId, ct);
        if (property is null) return Errors.Problem("property.not_found", "Property not found.", 404);

        var created = SiteVisit.Create(req.PropertyId, buyerId.Value, property.OwnerId, req.ScheduledAt, req.Notes);
        if (created.IsFailure) return Errors.Problem(created.Error!.Code, created.Error.Message, 400);

        db.SiteVisits.Add(created.Value!);
        await db.SaveChangesAsync(ct);
        return Results.Created($"/api/v1/site-visits/{created.Value!.Id}", new
        {
            created.Value.Id,
            created.Value.PropertyId,
            propertyTitle = property.Title,
            created.Value.BuyerId,
            created.Value.OwnerId,
            created.Value.ScheduledAt,
            status = created.Value.Status.ToString(),
            created.Value.Notes,
            created.Value.CreatedAt
        });
    }

    [HttpPatch("{id:guid}")]
    public async Task<IResult> UpdateStatus(Guid id, [FromBody] UpdateVisitStatusRequest req, CancellationToken ct)
    {
        var userId = CurrentUserId();
        if (userId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var visit = await db.SiteVisits.FirstOrDefaultAsync(v => v.Id == id, ct);
        if (visit is null) return Errors.Problem("visit.not_found", "Site visit not found.", 404);

        if (visit.OwnerId != userId.Value && visit.BuyerId != userId.Value && !User.IsInRole("Admin"))
            return Errors.Problem("auth.forbidden", "Not authorized to update this visit.", 403);

        visit.UpdateStatus(req.Status);
        await db.SaveChangesAsync(ct);
        return Results.Ok(new { visit.Id, status = visit.Status.ToString() });
    }

    private Guid? CurrentUserId()
    {
        var sub = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(sub, out var id) ? id : null;
    }
}

public sealed record ScheduleVisitRequest(Guid PropertyId, DateTimeOffset ScheduledAt, string? Notes);
public sealed record UpdateVisitStatusRequest(VisitStatus Status);

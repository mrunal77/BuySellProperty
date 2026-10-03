using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using BuildingBlocks.Api;
using Enquiries.Domain;
using Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Route("api/v1/enquiries")]
[Authorize]
public sealed class EnquiriesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IResult> GetEnquiries([FromQuery] bool mine = false, CancellationToken ct = default)
    {
        var userId = CurrentUserId();
        if (userId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var query = db.Enquiries.AsQueryable();
        if (mine)
        {
            // Owner inbox (received enquiries)
            query = query.Where(e => e.OwnerId == userId.Value);
        }
        else
        {
            // Buyer sent enquiries
            query = query.Where(e => e.BuyerId == userId.Value);
        }

        var enquiries = await query.OrderByDescending(e => e.CreatedAt).ToListAsync(ct);
        var propertyIds = enquiries.Select(e => e.PropertyId).Distinct().ToList();
        var properties = await db.Properties.Where(p => propertyIds.Contains(p.Id)).ToDictionaryAsync(p => p.Id, ct);

        return Results.Ok(enquiries.Select(e => new
        {
            e.Id,
            e.PropertyId,
            propertyTitle = properties.TryGetValue(e.PropertyId, out var p) ? p.Title : "Property",
            e.BuyerId,
            e.OwnerId,
            e.Message,
            e.ContactPhone,
            status = e.Status.ToString(),
            e.CreatedAt
        }));
    }

    [HttpPost]
    public async Task<IResult> CreateEnquiry([FromBody] CreateEnquiryRequest req, CancellationToken ct)
    {
        var buyerId = CurrentUserId();
        if (buyerId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var property = await db.Properties.FirstOrDefaultAsync(p => p.Id == req.PropertyId, ct);
        if (property is null) return Errors.Problem("property.not_found", "Property not found.", 404);

        var created = Enquiry.Create(req.PropertyId, buyerId.Value, property.OwnerId, req.Message, req.ContactPhone);
        if (created.IsFailure) return Errors.Problem(created.Error!.Code, created.Error.Message, 400);

        db.Enquiries.Add(created.Value!);
        await db.SaveChangesAsync(ct);
        return Results.Created($"/api/v1/enquiries/{created.Value!.Id}", new
        {
            created.Value.Id,
            created.Value.PropertyId,
            propertyTitle = property.Title,
            created.Value.BuyerId,
            created.Value.OwnerId,
            created.Value.Message,
            created.Value.ContactPhone,
            status = created.Value.Status.ToString(),
            created.Value.CreatedAt
        });
    }

    [HttpPatch("{id:guid}")]
    public async Task<IResult> UpdateStatus(Guid id, [FromBody] UpdateEnquiryStatusRequest req, CancellationToken ct)
    {
        var userId = CurrentUserId();
        if (userId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var enquiry = await db.Enquiries.FirstOrDefaultAsync(e => e.Id == id, ct);
        if (enquiry is null) return Errors.Problem("enquiry.not_found", "Enquiry not found.", 404);

        if (enquiry.OwnerId != userId.Value && !User.IsInRole("Admin"))
            return Errors.Problem("auth.forbidden", "Not authorized to update this enquiry.", 403);

        enquiry.UpdateStatus(req.Status);
        await db.SaveChangesAsync(ct);
        return Results.Ok(new { enquiry.Id, status = enquiry.Status.ToString() });
    }

    private Guid? CurrentUserId()
    {
        var sub = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(sub, out var id) ? id : null;
    }
}

public sealed record CreateEnquiryRequest(Guid PropertyId, string Message, string ContactPhone);
public sealed record UpdateEnquiryStatusRequest(EnquiryStatus Status);

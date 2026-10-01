using Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Route("api/v1")]
public sealed class LocationsController(AppDbContext db) : ControllerBase
{
    [HttpGet("cities")]
    [AllowAnonymous]
    public async Task<IResult> Cities(CancellationToken ct)
        => Results.Ok(await db.Cities.OrderBy(c => c.Name).ToListAsync(ct));

    [HttpGet("localities")]
    [AllowAnonymous]
    public async Task<IResult> Localities([FromQuery] Guid? cityId, CancellationToken ct)
    {
        var q = db.Localities.AsQueryable();
        if (cityId is not null) q = q.Where(l => l.CityId == cityId);
        return Results.Ok(await q.OrderBy(l => l.Name).ToListAsync(ct));
    }

    [HttpGet("amenities")]
    [AllowAnonymous]
    public IResult Amenities() => Results.Ok(new[]
    {
        new { id = "parking", name = "Parking", category = "Essential" },
        new { id = "lift", name = "Lift", category = "Essential" },
        new { id = "pool", name = "Swimming Pool", category = "Lifestyle" },
        new { id = "gym", name = "Gym", category = "Lifestyle" },
        new { id = "clubhouse", name = "Club House", category = "Lifestyle" },
        new { id = "security", name = "24x7 Security", category = "Safety" },
    });
}

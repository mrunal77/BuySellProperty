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
    {
        var cities = await db.Cities.OrderBy(c => c.Name).ToListAsync(ct);
        var counts = await db.Properties
            .Where(p => p.Status == Properties.Domain.PropertyStatus.Active)
            .GroupBy(p => p.CityId)
            .Select(g => new { CityId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.CityId, x => x.Count, ct);

        var result = cities.Select(c => new
        {
            c.Id,
            c.Name,
            c.State,
            c.Latitude,
            c.Longitude,
            propertyCount = counts.GetValueOrDefault(c.Id, 0)
        });

        return Results.Ok(result);
    }

    [HttpGet("localities")]
    [AllowAnonymous]
    public async Task<IResult> Localities([FromQuery] Guid? cityId, CancellationToken ct)
    {
        var q = db.Localities.AsQueryable();
        if (cityId is not null) q = q.Where(l => l.CityId == cityId);
        return Results.Ok(await q.OrderBy(l => l.Name).ToListAsync(ct));
    }
}

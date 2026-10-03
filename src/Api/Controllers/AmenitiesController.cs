using Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Route("api/v1/amenities")]
[AllowAnonymous]
public sealed class AmenitiesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IResult> GetAll(CancellationToken ct)
    {
        var items = await db.Amenities
            .OrderBy(a => a.Category)
            .ThenBy(a => a.Name)
            .Select(a => new { a.Id, a.Name, a.Icon, a.Category })
            .ToListAsync(ct);

        return Results.Ok(items);
    }
}

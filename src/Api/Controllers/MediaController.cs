using BuildingBlocks.Api;
using BuildingBlocks.Storage;
using Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Route("api/v1/media")]
public sealed class MediaController(IFileStorage fileStorage, AppDbContext db) : ControllerBase
{
    private static readonly string[] AllowedContentTypes = ["image/jpeg", "image/png", "image/webp", "image/gif"];

    private static string? ResolveContentType(IFormFile file)
    {
        var contentType = file.ContentType?.ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(contentType) || contentType == "application/octet-stream")
        {
            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            contentType = ext switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".webp" => "image/webp",
                ".gif" => "image/gif",
                _ => contentType
            };
        }
        return contentType;
    }

    [HttpPost("upload")]
    [AllowAnonymous]
    public async Task<IResult> UploadImage(IFormFile file, CancellationToken ct)
    {
        if (file is null || file.Length == 0)
            return Errors.Problem("media.empty_file", "File cannot be empty.", 400);

        if (file.Length > 10 * 1024 * 1024)
            return Errors.Problem("media.file_too_large", "File size cannot exceed 10 MB.", 400);

        var contentType = ResolveContentType(file);
        if (contentType is null || !AllowedContentTypes.Contains(contentType))
            return Errors.Problem("media.invalid_content_type", "Only JPEG, PNG, WEBP, and GIF images are allowed.", 400);

        await using var stream = file.OpenReadStream();
        var url = await fileStorage.SaveAsync(stream, file.FileName, contentType, ct);

        return Results.Ok(new { url });
    }

    [HttpPost("properties/{propertyId:guid}")]
    [Authorize(Roles = "Owner,Agent,Builder,Admin")]
    public async Task<IResult> UploadPropertyImage(Guid propertyId, IFormFile file, CancellationToken ct)
    {
        var property = await db.Properties.FirstOrDefaultAsync(p => p.Id == propertyId, ct);
        if (property is null) return Errors.Problem("property.not_found", "Property not found.", 404);

        if (file is null || file.Length == 0)
            return Errors.Problem("media.empty_file", "File cannot be empty.", 400);

        if (file.Length > 10 * 1024 * 1024)
            return Errors.Problem("media.file_too_large", "File size cannot exceed 10 MB.", 400);

        var contentType = ResolveContentType(file);
        if (contentType is null || !AllowedContentTypes.Contains(contentType))
            return Errors.Problem("media.invalid_content_type", "Only JPEG, PNG, WEBP, and GIF images are allowed.", 400);

        await using var stream = file.OpenReadStream();
        var url = await fileStorage.SaveAsync(stream, file.FileName, contentType, ct);

        var currentImages = new List<string>(property.ImageUrls) { url };
        property.Update(
            property.Title, property.Description, property.Price, property.AreaSqft,
            property.Bedrooms, property.Bathrooms, property.Furnishing, property.AddressLine,
            imageUrls: currentImages, amenities: property.Amenities
        );

        await db.SaveChangesAsync(ct);
        return Results.Ok(new { url, imageUrls = property.ImageUrls });
    }
}

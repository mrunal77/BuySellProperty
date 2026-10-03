using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Options;

namespace BuildingBlocks.Storage;

public interface IFileStorage
{
    Task<string> GetPresignedUploadUrlAsync(string key, string contentType, CancellationToken ct = default);
    Task<string> SaveAsync(Stream stream, string fileName, string contentType, CancellationToken ct = default);
}

public sealed class LocalDiskStorage(IOptions<StorageOptions> options, IWebHostEnvironment env) : IFileStorage
{
    private readonly StorageOptions _options = options.Value;

    public Task<string> GetPresignedUploadUrlAsync(string key, string contentType, CancellationToken ct = default)
        => Task.FromResult($"{_options.PublicBaseUrl.TrimEnd('/')}/uploads/{key}");

    public async Task<string> SaveAsync(Stream stream, string fileName, string contentType, CancellationToken ct = default)
    {
        var webRoot = env.WebRootPath ?? Path.Combine(env.ContentRootPath, "wwwroot");
        var dir = Path.Combine(webRoot, "uploads");
        Directory.CreateDirectory(dir);
        var key = $"{Guid.NewGuid():N}_{Path.GetFileName(fileName)}";
        var path = Path.Combine(dir, key);
        await using var fs = File.Create(path);
        await stream.CopyToAsync(fs, ct);
        return $"{_options.PublicBaseUrl.TrimEnd('/')}/uploads/{key}";
    }
}

public sealed class StorageOptions
{
    public const string SectionName = "Storage";
    public string Provider { get; set; } = "LocalDisk";
    public string PublicBaseUrl { get; set; } = "http://localhost:5000";
    public string Bucket { get; set; } = "property-media";
}

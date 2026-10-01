namespace BuildingBlocks.Storage;

public interface IFileStorage
{
    Task<string> GetPresignedUploadUrlAsync(string key, string contentType, CancellationToken ct = default);
    Task<string> SaveAsync(Stream stream, string fileName, string contentType, CancellationToken ct = default);
}

public sealed class LocalDiskStorage(Microsoft.Extensions.Options.IOptions<StorageOptions> options) : IFileStorage
{
    private readonly StorageOptions _options = options.Value;

    public Task<string> GetPresignedUploadUrlAsync(string key, string contentType, CancellationToken ct = default)
        => Task.FromResult($"{_options.PublicBaseUrl.TrimEnd('/')}/uploads/{key}");

    public async Task<string> SaveAsync(Stream stream, string fileName, string contentType, CancellationToken ct = default)
    {
        var dir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads");
        Directory.CreateDirectory(dir);
        var key = $"{Guid.NewGuid():N}_{fileName}";
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

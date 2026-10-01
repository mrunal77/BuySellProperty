using Identity.Application;
using Identity.Domain;
using Microsoft.EntityFrameworkCore;

namespace Infrastructure.Persistence;

public sealed class EfOtpStore(AppDbContext db) : IOtpStore
{
    public Task<OtpCode?> FindLatestAsync(string phone, CancellationToken ct = default)
        => db.OtpCodes.Where(o => o.Phone == phone).OrderByDescending(o => o.CreatedAt).FirstOrDefaultAsync(ct);

    public async Task AddAsync(OtpCode code, CancellationToken ct = default)
    {
        db.OtpCodes.Add(code);
        await db.SaveChangesAsync(ct);
    }

    public async Task UpdateAsync(OtpCode code, CancellationToken ct = default)
    {
        db.OtpCodes.Update(code);
        await db.SaveChangesAsync(ct);
    }
}

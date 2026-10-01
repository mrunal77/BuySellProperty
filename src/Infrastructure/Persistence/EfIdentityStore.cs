using Identity.Application;
using Identity.Domain;
using Microsoft.EntityFrameworkCore;

namespace Infrastructure.Persistence;

public sealed class EfIdentityStore(AppDbContext db) : IIdentityStore
{
    public Task<User?> FindByEmailAsync(string email, CancellationToken ct = default)
        => db.Users.FirstOrDefaultAsync(u => u.Email == email.ToLower(), ct);

    public Task<User?> FindByPhoneAsync(string phone, CancellationToken ct = default)
        => db.Users.FirstOrDefaultAsync(u => u.Phone == phone, ct);

    public Task<User?> FindByIdAsync(Guid id, CancellationToken ct = default)
        => db.Users.FirstOrDefaultAsync(u => u.Id == id, ct);

    public async Task AddUserAsync(User user, CancellationToken ct = default)
    {
        db.Users.Add(user);
        await db.SaveChangesAsync(ct);
    }

    public Task<RefreshToken?> FindRefreshTokenAsync(string hash, CancellationToken ct = default)
        => db.RefreshTokens.FirstOrDefaultAsync(t => t.TokenHash == hash, ct);

    public async Task AddRefreshTokenAsync(RefreshToken token, CancellationToken ct = default)
    {
        db.RefreshTokens.Add(token);
        await db.SaveChangesAsync(ct);
    }

    public async Task UpdateRefreshTokenAsync(RefreshToken token, CancellationToken ct = default)
    {
        db.RefreshTokens.Update(token);
        await db.SaveChangesAsync(ct);
    }
}

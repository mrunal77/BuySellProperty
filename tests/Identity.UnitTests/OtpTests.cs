using BuildingBlocks.Auth;
using FluentAssertions;
using Identity.Application;
using Identity.Domain;
using Microsoft.Extensions.Options;

namespace Identity.UnitTests;

public sealed class PhoneNumberTests
{
    [Theory]
    [InlineData("+91 98765 43210", "+919876543210")]
    [InlineData("+1-415-555-1234", "+14155551234")]
    [InlineData("9876543210", "9876543210")]
    public void Normalize_strips_formatting(string raw, string expected)
    {
        var r = PhoneNumber.Normalize(raw);
        r.IsSuccess.Should().BeTrue();
        r.Value.Should().Be(expected);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("abc")]
    [InlineData("123")]
    [InlineData("++919876543210")]
    public void Normalize_rejects_invalid(string? raw)
    {
        PhoneNumber.Normalize(raw).IsFailure.Should().BeTrue();
    }

    [Fact]
    public void Mask_hides_middle_digits()
    {
        PhoneNumber.Mask("+919876543210").Should().Be("+91 ••••• 3210");
    }
}

public sealed class OtpCodeTests
{
    [Fact]
    public void Code_is_usable_until_consumed_or_expired()
    {
        var c = OtpCode.Create("+919876543210", "hash", TimeSpan.FromMinutes(5));
        c.IsUsable(5).Should().BeTrue();
        c.Consume();
        c.IsUsable(5).Should().BeFalse();
    }

    [Fact]
    public void Code_locks_after_max_attempts()
    {
        var c = OtpCode.Create("+919876543210", "hash", TimeSpan.FromMinutes(5));
        for (var i = 0; i < 5; i++) c.RegisterFailure();
        c.IsUsable(5).Should().BeFalse();
    }

    [Fact]
    public void Expired_code_is_not_usable()
    {
        var c = OtpCode.Create("+919876543210", "hash", TimeSpan.FromMinutes(-1));
        c.IsUsable(5).Should().BeFalse();
    }
}

public sealed class OtpServiceTests
{
    private sealed class FakeOtpStore : IOtpStore
    {
        public readonly List<OtpCode> Codes = [];
        public Task<OtpCode?> FindLatestAsync(string phone, CancellationToken ct = default)
            => Task.FromResult(Codes.Where(c => c.Phone == phone).OrderByDescending(c => c.CreatedAt).FirstOrDefault());
        public Task AddAsync(OtpCode code, CancellationToken ct = default) { Codes.Add(code); return Task.CompletedTask; }
        public Task UpdateAsync(OtpCode code, CancellationToken ct = default) => Task.CompletedTask;
    }

    private sealed class FakeIdentityStore(List<User> users) : IIdentityStore
    {
        public Task<User?> FindByEmailAsync(string email, CancellationToken ct = default)
            => Task.FromResult(users.FirstOrDefault(u => u.Email == email.ToLower()));
        public Task<User?> FindByPhoneAsync(string phone, CancellationToken ct = default)
            => Task.FromResult(users.FirstOrDefault(u => u.Phone == phone));
        public Task<User?> FindByIdAsync(Guid id, CancellationToken ct = default)
            => Task.FromResult(users.FirstOrDefault(u => u.Id == id));
        public Task AddUserAsync(User user, CancellationToken ct = default) { users.Add(user); return Task.CompletedTask; }
        public Task<RefreshToken?> FindRefreshTokenAsync(string hash, CancellationToken ct = default) => Task.FromResult<RefreshToken?>(null);
        public Task AddRefreshTokenAsync(RefreshToken token, CancellationToken ct = default) => Task.CompletedTask;
        public Task UpdateRefreshTokenAsync(RefreshToken token, CancellationToken ct = default) => Task.CompletedTask;
    }

    private sealed class FakeSender : IOtpSender
    {
        public readonly List<(string Phone, string Code)> Sent = [];
        public Task SendAsync(string phone, string code, CancellationToken ct = default)
        {
            Sent.Add((phone, code));
            return Task.CompletedTask;
        }
    }

    private sealed class FakeHasher : IPasswordHasher
    {
        public string Hash(string p) => "HASH:" + p;
        public bool Verify(string p, string h) => h == "HASH:" + p;
    }

    private static OtpService Build(FakeOtpStore codes, FakeIdentityStore users, FakeSender sender, out JwtTokenService tokens)
    {
        tokens = new JwtTokenService(Options.Create(new JwtOptions { Secret = "test-secret-key-min-32-chars-long!!" }));
        var issuer = new TokenIssuer(users, tokens, Options.Create(new JwtOptions { Secret = "test-secret-key-min-32-chars-long!!" }));
        return new OtpService(codes, users, new FakeHasher(), tokens, issuer,
            Options.Create(new OtpOptions { TtlMinutes = 5, CooldownSeconds = 60, MaxAttempts = 3, OtpTokenMinutes = 10 }), sender);
    }

    [Fact]
    public async Task Request_then_verify_new_user_then_register()
    {
        var codes = new FakeOtpStore();
        var users = new FakeIdentityStore([]);
        var sender = new FakeSender();
        var svc = Build(codes, users, sender, out _);

        var req = await svc.RequestAsync(new("+91 98765 43210"));
        req.IsSuccess.Should().BeTrue();
        sender.Sent.Should().HaveCount(1);

        // Cooldown blocks immediate re-request.
        var again = await svc.RequestAsync(new("+919876543210"));
        again.IsFailure.Should().BeTrue();
        again.Error!.Code.Should().Be("auth.otp_cooldown");

        // Wrong code fails with attempts left.
        var wrong = await svc.VerifyAsync(new("+919876543210", "000000"));
        wrong.IsFailure.Should().BeTrue();
        wrong.Error!.Code.Should().Be("auth.invalid_otp");

        // Right code verifies as new user.
        var ok = await svc.VerifyAsync(new("+919876543210", sender.Sent[0].Code));
        ok.IsSuccess.Should().BeTrue();
        ok.Value!.IsNewUser.Should().BeTrue();

        // Code is single-use.
        var reuse = await svc.VerifyAsync(new("+919876543210", sender.Sent[0].Code));
        reuse.IsFailure.Should().BeTrue();

        // Register with the otp token.
        var reg = await svc.RegisterAsync(new(ok.Value.OtpToken, "+919876543210", "new@example.com", "Strong1!pass", "Customer"));
        reg.IsSuccess.Should().BeTrue("register error was {0}: {1}", reg.Error?.Code, reg.Error?.Message);
        reg.Value!.Email.Should().Be("new@example.com");
        users.FindByPhoneAsync("+919876543210").Result.Should().NotBeNull();

        // Consumed code allows a fresh request.
        var req2 = await svc.RequestAsync(new("+919876543210"));
        req2.IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task Verify_existing_user_then_login()
    {
        var codes = new FakeOtpStore();
        // Simulate phone already on the account.
        var withPhone = User.Create("e@x.com", "HASH:pw123456", "Owner", "+14155551234", ["Owner"]).Value!;
        var users = new FakeIdentityStore([withPhone]);
        var sender = new FakeSender();
        var svc = Build(codes, users, sender, out _);
        svc = Build(codes, users, sender, out _);

        await svc.RequestAsync(new("+14155551234"));
        var ok = await svc.VerifyAsync(new("+14155551234", sender.Sent[0].Code));
        ok.Value!.IsNewUser.Should().BeFalse();

        var login = await svc.LoginAsync(new(ok.Value.OtpToken));
        login.IsSuccess.Should().BeTrue();
        login.Value!.Email.Should().Be("e@x.com");
    }

    [Fact]
    public async Task Register_rejects_taken_phone()
    {
        var codes = new FakeOtpStore();
        var existing = User.Create("a@x.com", "HASH:pw123456", "Customer", "+919876543210", ["Customer"]).Value!;
        var users = new FakeIdentityStore([existing]);
        var sender = new FakeSender();
        var svc = Build(codes, users, sender, out var tokens);

        var otpToken = tokens.CreatePurposeToken("otp", "+919876543210", 10);
        var reg = await svc.RegisterAsync(new(otpToken, "+919876543210", "b@x.com", "Strong1!pass", "Customer"));
        reg.IsFailure.Should().BeTrue();
        reg.Error!.Code.Should().Be("auth.phone_taken");
    }
}

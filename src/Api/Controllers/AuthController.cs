using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using BuildingBlocks.Api;
using Identity.Application;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace Api.Controllers;

[ApiController]
[Route("api/v1/auth")]
public sealed class AuthController(
    IAuthService auth,
    IOtpService otp,
    IOptions<OtpOptions> otpOptions,
    IWebHostEnvironment env) : ControllerBase
{
    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<IResult> Register([FromBody] RegisterRequest req, CancellationToken ct)
    {
        var v = new RegisterValidator().Validate(req);
        if (!v.IsValid) return Errors.Problem("auth.validation", "Validation failed.", 400, v.Errors.Select(e => new { e.PropertyName, e.ErrorMessage }));
        var r = await auth.RegisterAsync(req, ct);
        return r.IsSuccess ? Results.Ok(r.Value) : Map(r.Error!);
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IResult> Login([FromBody] LoginRequest req, CancellationToken ct)
    {
        var r = await auth.LoginAsync(req, ct);
        return r.IsSuccess ? Results.Ok(r.Value) : Map(r.Error!);
    }

    [HttpPost("refresh")]
    [AllowAnonymous]
    public async Task<IResult> Refresh([FromBody] RefreshRequest req, CancellationToken ct)
    {
        var r = await auth.RefreshAsync(req, ct);
        return r.IsSuccess ? Results.Ok(r.Value) : Map(r.Error!);
    }

    [HttpPost("logout")]
    [AllowAnonymous]
    public async Task<IResult> Logout([FromBody] RefreshRequest req, CancellationToken ct)
    {
        await auth.LogoutAsync(req.RefreshToken, ct);
        return Results.NoContent();
    }

    [HttpPost("otp/request")]
    [AllowAnonymous]
    public async Task<IResult> OtpRequest([FromBody] OtpRequestRequest req, CancellationToken ct)
    {
        var v = new OtpRequestValidator().Validate(req);
        if (!v.IsValid) return Errors.Problem("auth.validation", "Validation failed.", 400, v.Errors.Select(e => new { e.PropertyName, e.ErrorMessage }));
        var r = await otp.RequestAsync(req, ct);
        if (r.IsFailure) return Map(r.Error!);
        // Raw code is exposed ONLY in Development (see Otp:ExposeCodesInDev).
        var devCode = env.IsDevelopment() && otpOptions.Value.ExposeCodesInDev ? r.Value!.RawCode : null;
        return Results.Ok(new { phone = r.Value!.Phone, maskedPhone = r.Value!.MaskedPhone, expiresInSeconds = r.Value!.ExpiresInSeconds, devCode });
    }

    [HttpPost("otp/verify")]
    [AllowAnonymous]
    public async Task<IResult> OtpVerify([FromBody] OtpVerifyRequest req, CancellationToken ct)
    {
        var v = new OtpVerifyValidator().Validate(req);
        if (!v.IsValid) return Errors.Problem("auth.validation", "Validation failed.", 400, v.Errors.Select(e => new { e.PropertyName, e.ErrorMessage }));
        var r = await otp.VerifyAsync(req, ct);
        return r.IsSuccess ? Results.Ok(r.Value) : Map(r.Error!);
    }

    [HttpPost("otp/login")]
    [AllowAnonymous]
    public async Task<IResult> OtpLogin([FromBody] OtpLoginRequest req, CancellationToken ct)
    {
        var r = await otp.LoginAsync(req, ct);
        return r.IsSuccess ? Results.Ok(r.Value) : Map(r.Error!);
    }

    [HttpPost("otp/register")]
    [AllowAnonymous]
    public async Task<IResult> OtpRegister([FromBody] OtpRegisterRequest req, CancellationToken ct)
    {
        var v = new OtpRegisterValidator().Validate(req);
        if (!v.IsValid) return Errors.Problem("auth.validation", "Validation failed.", 400, v.Errors.Select(e => new { e.PropertyName, e.ErrorMessage }));
        var r = await otp.RegisterAsync(req, ct);
        return r.IsSuccess ? Results.Ok(r.Value) : Map(r.Error!);
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<IResult> Me(CancellationToken ct)
    {
        var sub = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(sub, out var id)) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);
        var r = await auth.GetByIdAsync(id, ct);
        return r.IsSuccess
            ? Results.Ok(new { r.Value!.Id, r.Value.Email, r.Value.UserType, Roles = r.Value.UserRoles })
            : Map(r.Error!);
    }

    private static IResult Map(SharedKernel.Error e) => e.Code switch
    {
        "auth.otp_cooldown" => Errors.Problem(e.Code, e.Message, 429),
        var c when c.StartsWith("auth.invalid") => Errors.Problem(e.Code, e.Message, 401),
        var c when c.Contains("taken") => Errors.Problem(e.Code, e.Message, 409),
        var c when c.Contains("not_found") => Errors.Problem(e.Code, e.Message, 404),
        _ => Errors.Problem(e.Code, e.Message, 400),
    };
}

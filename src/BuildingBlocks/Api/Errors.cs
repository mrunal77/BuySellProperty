using Microsoft.AspNetCore.Http;

namespace BuildingBlocks.Api;

public static class Errors
{
    public static IResult Problem(string code, string message, int status, object? details = null)
        => Results.Json(new { error = new { code, message, details } }, statusCode: status);
}

public sealed class CorrelationIdMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext ctx)
    {
        var id = ctx.Request.Headers.TryGetValue("X-Correlation-Id", out var v) && v.Count > 0
            ? v.ToString() : Guid.NewGuid().ToString("N");
        ctx.Response.Headers["X-Correlation-Id"] = id;
        ctx.Items["CorrelationId"] = id;
        await next(ctx);
    }
}

using Identity.Application;
using Microsoft.Extensions.Logging;

namespace Infrastructure.Auth;

/// <summary>Dev SMS sender: logs the code. Swap for MSG91/Twilio in production
/// by registering a different <see cref="IOtpSender"/>.</summary>
public sealed class LogOtpSender(ILogger<LogOtpSender> logger) : IOtpSender
{
    public Task SendAsync(string phone, string code, CancellationToken ct = default)
    {
        logger.LogInformation("OTP for {Phone}: {Code} (dev sender — plug in a real SMS gateway for production)", phone, code);
        return Task.CompletedTask;
    }
}

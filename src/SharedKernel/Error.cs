namespace SharedKernel;

public sealed record Error(string Code, string Message)
{
    public static Error NotFound(string code, string message) => new(code, message);
    public static Error Validation(string code, string message) => new(code, message);
    public static Error Conflict(string code, string message) => new(code, message);
    public static Error Unauthorized(string code = "auth.unauthorized", string message = "Unauthorized") => new(code, message);
    public static Error Forbidden(string code = "auth.forbidden", string message = "Forbidden") => new(code, message);
}

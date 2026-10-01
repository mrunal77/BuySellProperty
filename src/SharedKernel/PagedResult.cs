namespace SharedKernel;

public sealed record PagedResult<T>(IReadOnlyList<T> Data, int Page, int PageSize, long Total);

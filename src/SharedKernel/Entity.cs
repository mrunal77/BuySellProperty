namespace SharedKernel;

public abstract class Entity
{
    public Guid Id { get; protected set; } = Guid.NewGuid();
    public DateTimeOffset CreatedAt { get; protected set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; protected set; } = DateTimeOffset.UtcNow;

    private readonly List<IDomainEvent> _events = [];
    public IReadOnlyCollection<IDomainEvent> DomainEvents => _events.AsReadOnly();

    protected void Raise(IDomainEvent @event) => _events.Add(@event);
    public void ClearEvents() => _events.Clear();
    protected void Touch() => UpdatedAt = DateTimeOffset.UtcNow;
}

public interface IDomainEvent
{
    DateTimeOffset OccurredAt { get; }
}

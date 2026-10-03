using SharedKernel;

namespace Chat.Domain;

public sealed class Conversation : Entity
{
    public Guid? PropertyId { get; private set; }
    public Guid Participant1Id { get; private set; }
    public Guid Participant2Id { get; private set; }

    private Conversation() { }

    public static Result<Conversation> Create(Guid participant1Id, Guid participant2Id, Guid? propertyId = null)
    {
        if (participant1Id == Guid.Empty || participant2Id == Guid.Empty)
            return Result<Conversation>.Failure(Error.Validation("chat.invalid_participants", "Participants required."));
        if (participant1Id == participant2Id)
            return Result<Conversation>.Failure(Error.Validation("chat.self_conversation", "Cannot chat with yourself."));

        return Result<Conversation>.Success(new Conversation
        {
            Participant1Id = participant1Id,
            Participant2Id = participant2Id,
            PropertyId = propertyId
        });
    }

    public bool HasParticipant(Guid userId) => Participant1Id == userId || Participant2Id == userId;
}

public sealed class ChatMessage : Entity
{
    public Guid ConversationId { get; private set; }
    public Guid SenderId { get; private set; }
    public string Body { get; private set; } = default!;

    private ChatMessage() { }

    public static Result<ChatMessage> Create(Guid conversationId, Guid senderId, string body)
    {
        if (conversationId == Guid.Empty) return Result<ChatMessage>.Failure(Error.Validation("chat.invalid_conversation", "Invalid conversation."));
        if (senderId == Guid.Empty) return Result<ChatMessage>.Failure(Error.Validation("chat.invalid_sender", "Invalid sender."));
        if (string.IsNullOrWhiteSpace(body)) return Result<ChatMessage>.Failure(Error.Validation("chat.empty_body", "Message body cannot be empty."));

        return Result<ChatMessage>.Success(new ChatMessage
        {
            ConversationId = conversationId,
            SenderId = senderId,
            Body = body.Trim()
        });
    }
}

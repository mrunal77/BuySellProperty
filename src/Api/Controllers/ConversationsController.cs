using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using BuildingBlocks.Api;
using Chat.Domain;
using Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Route("api/v1/conversations")]
[Authorize]
public sealed class ConversationsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IResult> GetConversations(CancellationToken ct)
    {
        var userId = CurrentUserId();
        if (userId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var convs = await db.Conversations
            .Where(c => c.Participant1Id == userId.Value || c.Participant2Id == userId.Value)
            .OrderByDescending(c => c.UpdatedAt)
            .ToListAsync(ct);

        var convIds = convs.Select(c => c.Id).ToList();
        var lastMessages = await db.ChatMessages
            .Where(m => convIds.Contains(m.ConversationId))
            .GroupBy(m => m.ConversationId)
            .Select(g => g.OrderByDescending(m => m.CreatedAt).First())
            .ToDictionaryAsync(m => m.ConversationId, ct);

        return Results.Ok(convs.Select(c => new
        {
            c.Id,
            c.PropertyId,
            c.Participant1Id,
            c.Participant2Id,
            otherParticipantId = c.Participant1Id == userId.Value ? c.Participant2Id : c.Participant1Id,
            lastMessage = lastMessages.TryGetValue(c.Id, out var msg) ? new { msg.Id, msg.SenderId, msg.Body, msg.CreatedAt } : null,
            c.UpdatedAt
        }));
    }

    [HttpPost]
    public async Task<IResult> StartConversation([FromBody] StartConversationRequest req, CancellationToken ct)
    {
        var senderId = CurrentUserId();
        if (senderId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var existing = await db.Conversations.FirstOrDefaultAsync(c =>
            (c.Participant1Id == senderId.Value && c.Participant2Id == req.RecipientId) ||
            (c.Participant1Id == req.RecipientId && c.Participant2Id == senderId.Value), ct);

        if (existing is not null)
            return Results.Ok(new { existing.Id, isNew = false });

        var created = Conversation.Create(senderId.Value, req.RecipientId, req.PropertyId);
        if (created.IsFailure) return Errors.Problem(created.Error!.Code, created.Error.Message, 400);

        db.Conversations.Add(created.Value!);

        if (!string.IsNullOrWhiteSpace(req.InitialMessage))
        {
            var msg = ChatMessage.Create(created.Value!.Id, senderId.Value, req.InitialMessage);
            if (msg.IsSuccess) db.ChatMessages.Add(msg.Value!);
        }

        await db.SaveChangesAsync(ct);
        return Results.Created($"/api/v1/conversations/{created.Value!.Id}", new { created.Value.Id, isNew = true });
    }

    [HttpGet("{id:guid}/messages")]
    public async Task<IResult> GetMessages(Guid id, CancellationToken ct)
    {
        var userId = CurrentUserId();
        if (userId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var conv = await db.Conversations.FirstOrDefaultAsync(c => c.Id == id, ct);
        if (conv is null) return Errors.Problem("chat.not_found", "Conversation not found.", 404);
        if (!conv.HasParticipant(userId.Value)) return Errors.Problem("auth.forbidden", "Not a participant.", 403);

        var messages = await db.ChatMessages
            .Where(m => m.ConversationId == id)
            .OrderBy(m => m.CreatedAt)
            .Select(m => new { m.Id, m.ConversationId, m.SenderId, m.Body, m.CreatedAt })
            .ToListAsync(ct);

        return Results.Ok(messages);
    }

    [HttpPost("{id:guid}/messages")]
    public async Task<IResult> SendMessage(Guid id, [FromBody] SendMessageRequest req, CancellationToken ct)
    {
        var userId = CurrentUserId();
        if (userId is null) return Errors.Problem("auth.unauthorized", "Unauthorized.", 401);

        var conv = await db.Conversations.FirstOrDefaultAsync(c => c.Id == id, ct);
        if (conv is null) return Errors.Problem("chat.not_found", "Conversation not found.", 404);
        if (!conv.HasParticipant(userId.Value)) return Errors.Problem("auth.forbidden", "Not a participant.", 403);

        var created = ChatMessage.Create(id, userId.Value, req.Body);
        if (created.IsFailure) return Errors.Problem(created.Error!.Code, created.Error.Message, 400);

        db.ChatMessages.Add(created.Value!);
        await db.SaveChangesAsync(ct);

        return Results.Created($"/api/v1/conversations/{id}/messages", new
        {
            created.Value!.Id,
            created.Value.ConversationId,
            created.Value.SenderId,
            created.Value.Body,
            created.Value.CreatedAt
        });
    }

    private Guid? CurrentUserId()
    {
        var sub = User.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(sub, out var id) ? id : null;
    }
}

public sealed record StartConversationRequest(Guid RecipientId, Guid? PropertyId = null, string? InitialMessage = null);
public sealed record SendMessageRequest(string Body);

using Microsoft.AspNetCore.SignalR;
using MiniChatWeb.Data;
using MiniChatWeb.Models;
using System;
using System.Threading.Tasks;

namespace MiniChatWeb.Hubs
{
    public class ChatHub : Hub
    {
        private readonly ChatDbContext _context;

        public ChatHub(ChatDbContext context)
        {
            _context = context;
        }

        public async Task SendMessage(string senderId, string senderName, string receiverId, string message, bool isAdmin)
        {
            if (string.IsNullOrWhiteSpace(message)) return;

            var chatMessage = new ChatMessage
            {
                SenderId = senderId,
                SenderName = senderName,
                ReceiverId = receiverId,
                Content = message,
                Timestamp = DateTime.Now,
                IsAdmin = isAdmin
            };

            _context.ChatMessages.Add(chatMessage);
            await _context.SaveChangesAsync();

            await Clients.All.SendAsync(
                "ReceiveMessage",
                senderId,
                senderName,
                receiverId,
                message,
                chatMessage.Timestamp.ToString("HH:mm:ss dd/MM/yyyy"),
                isAdmin
            );
        }
    }
}
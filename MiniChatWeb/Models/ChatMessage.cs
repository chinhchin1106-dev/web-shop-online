using System;
using System.ComponentModel.DataAnnotations;

namespace MiniChatWeb.Models
{
    public class ChatMessage
    {
        [Key]
        public int Id { get; set; }
        public string SenderId { get; set; } = string.Empty;
        public string SenderName { get; set; } = string.Empty;
        public string ReceiverId { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.Now;
        public bool IsAdmin { get; set; }
    }
}
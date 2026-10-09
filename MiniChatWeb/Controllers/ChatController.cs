using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MiniChatWeb.Data;
using MiniChatWeb.Models;
using System.Linq;
using System.Threading.Tasks;

namespace MiniChatWeb.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ChatController : ControllerBase
    {
        private readonly ChatDbContext _context;

        public ChatController(ChatDbContext context)
        {
            _context = context;
        }

        [HttpGet("history")]
        public async Task<IActionResult> GetChatHistory([FromQuery] string user1, [FromQuery] string user2)
        {
            var history = await _context.ChatMessages
                .Where(m => (m.SenderId == user1 && m.ReceiverId == user2) ||
                            (m.SenderId == user2 && m.ReceiverId == user1))
                .OrderBy(m => m.Timestamp)
                .Select(m => new
                {
                    m.Id,
                    m.SenderId,
                    m.SenderName,
                    m.ReceiverId,
                    m.Content,
                    Timestamp = m.Timestamp.ToString("HH:mm:ss dd/MM/yyyy"),
                    m.IsAdmin
                })
                .ToListAsync();

            return Ok(history);
        }
    }
}
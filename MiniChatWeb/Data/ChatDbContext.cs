using Microsoft.EntityFrameworkCore;
using MiniChatWeb.Models;

namespace MiniChatWeb.Data
{
    public class ChatDbContext : DbContext
    {
        public ChatDbContext(DbContextOptions<ChatDbContext> options) : base(options) { }

        public DbSet<ChatMessage> ChatMessages { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.Entity<ChatMessage>().HasIndex(m => m.Timestamp);
        }
    }
}
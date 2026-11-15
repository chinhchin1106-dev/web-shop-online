#nullable disable

namespace KiemTraTH_25DH110330
{
    internal class IntNode
    {
        public int Data { get; set; }
        public IntNode Next { get; set; }

        public IntNode(int data)
        {
            Data = data;
            Next = null;
        }
    }
}
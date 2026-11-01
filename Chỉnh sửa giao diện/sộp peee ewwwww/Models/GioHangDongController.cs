
namespace SopPe.Models
{
    public class GioHangDong
    {
        public int Ma { get; set; }
        public string Ten { get; set; }
        public decimal Gia { get; set; }
        public int SoLuong { get; set; }
        public string HinhAnh {  get; set; }

        public decimal ThanhTien
        {
            get { return Gia * SoLuong; }
        }
    }
}

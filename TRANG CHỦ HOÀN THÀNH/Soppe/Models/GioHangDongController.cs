
namespace Soppe.Models
{
    public class GioHangDong
    {
        // Mã sản phẩm
        public int Ma { get; set; }

        // Tên sản phẩm
        public string Ten { get; set; }

        // Giá bán
        public decimal Gia { get; set; }

        // Số lượng trong giỏ
        public int SoLuong { get; set; }

        // Hình ảnh sản phẩm
        public string HinhAnh { get; set; }

        // Số lượng tồn kho từ SQL
        public int SLTonKho { get; set; }

        // Thành tiền
        public decimal ThanhTien
        {
            get { return Gia * SoLuong; }
        }
    }
}


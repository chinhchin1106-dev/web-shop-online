using System.Collections.Generic;
using System.Linq;

namespace SopPe.Models
{
    public static class KhoDuLieu
    {
        public static readonly List<SanPham> SanPhams = new List<SanPham>
        {
            new SanPham { Ma = 1, Ten = "Áo thun basic", DanhMuc = "Thời trang", Gia = 129000, Hinh = "👕" },
            new SanPham { Ma = 2, Ten = "Giày thể thao", DanhMuc = "Thời trang", Gia = 399000, Hinh = "👟" },
            new SanPham { Ma = 3, Ten = "Tai nghe không dây", DanhMuc = "Điện tử", Gia = 289000, Hinh = "🎧" },
            new SanPham { Ma = 4, Ten = "Đồng hồ thông minh", DanhMuc = "Điện tử", Gia = 690000, Hinh = "⌚" },
            new SanPham { Ma = 5, Ten = "Balo đi học", DanhMuc = "Phụ kiện", Gia = 249000, Hinh = "🎒" },
            new SanPham { Ma = 6, Ten = "Bình nước giữ nhiệt", DanhMuc = "Gia dụng", Gia = 159000, Hinh = "🥤" }
        };

      
        public static List<SanPham> DanhSach
        {
            get { return SanPhams; }
        }

        public static SanPham Tim(int ma)
        {
            return SanPhams.FirstOrDefault(sp => sp.Ma == ma);
        }
    }
}

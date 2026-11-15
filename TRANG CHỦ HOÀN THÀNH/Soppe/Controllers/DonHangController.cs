using Soppe.Data;
using Soppe.Security;
using System.Data;
using System.Data.SqlClient;
using System.Web.Mvc;

namespace Soppe.Controllers
{
    [PhanQuyenAuthorize]
    public class DonHangController : Controller
    {
        [HttpGet]
        public ActionResult Index()
        {
            int? maKH = AuthHelper.LayMaKHHienTai(HttpContext);
            if (!maKH.HasValue)
                return RedirectToAction("Dangnhap", "TrangChu");

            var factory = new SqlConnectionFactory();
            using (var conn = factory.CreateConnection())
            {
                conn.Open();
                const string sql = @"
                    SELECT MaDH, NgayDat, TongTien, TrangThai
                    FROM dbo.DonHang
                    WHERE MaKH = @MaKH
                    ORDER BY NgayDat DESC";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@MaKH", SqlDbType.Int).Value = maKH.Value;
                    // Đọc danh sách đơn hàng của riêng maKH và truyền vào View
                }
            }

            return View();
        }

        [HttpGet]
        public ActionResult ChiTiet(int id)
        {
            int? maKH = AuthHelper.LayMaKHHienTai(HttpContext);
            if (!maKH.HasValue)
                return RedirectToAction("Dangnhap", "TrangChu");

            bool laAdmin = User.IsInRole("Admin");
            var factory = new SqlConnectionFactory();

            using (var conn = factory.CreateConnection())
            {
                conn.Open();
                string sql = laAdmin
                    ? "SELECT * FROM dbo.DonHang WHERE MaDH = @MaDH"
                    : "SELECT * FROM dbo.DonHang WHERE MaDH = @MaDH AND MaKH = @MaKH";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@MaDH", SqlDbType.Int).Value = id;
                    if (!laAdmin)
                    {
                        cmd.Parameters.Add("@MaKH", SqlDbType.Int).Value = maKH.Value;
                    }

                    using (var reader = cmd.ExecuteReader())
                    {
                        if (!reader.Read())
                        {
                            // Trả về 404 thay vì 403 để không tiết lộ mã đơn hàng có tồn tại hay không
                            return HttpNotFound();
                        }
                        // Đọc thông tin đơn hàng và truyền ra View
                    }
                }
            }

            return View();
        }
    }
}
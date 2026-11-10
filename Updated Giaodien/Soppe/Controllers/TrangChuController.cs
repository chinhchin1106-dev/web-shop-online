using Soppe.Models;
using Soppe.Data;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Security.Cryptography;
using System.Web.Mvc;
using System.Web.ModelBinding;
using Microsoft.Win32;

namespace Soppe.Controllers
{
    public class TrangChuController : Controller
    {
        // =====================================
        // 1. TRANG CHỦ
        // =====================================
        [HttpGet]
        public ActionResult Index()
        {
            return View();
        }

        // =====================================
        // 2. ĐĂNG KÝ - GET
        // =====================================
        [HttpGet]
        public ActionResult Dangky()
        {
            return View();
        }

        // =====================================
        // 3. BĂM MẬT KHẨU PBKDF2
        // =====================================
        private string BamMatKhau(string matKhau)
        {
            byte[] salt = new byte[16];

            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(salt);
            }

            const int soLanLap = 210000;

            using (var pbkdf2 = new Rfc2898DeriveBytes(
                matKhau,
                salt,
                soLanLap,
                HashAlgorithmName.SHA256))
            {
                byte[] hash = pbkdf2.GetBytes(32);

                return "PBKDF2-SHA256$" +
                       soLanLap + "$" +
                       Convert.ToBase64String(salt) + "$" +
                       Convert.ToBase64String(hash);
            }
        }

        // =====================================
        // 4. KIỂM TRA MẬT KHẨU
        // =====================================
        private bool KiemTraMatKhau(
            string matKhau,
            string matKhauDaBam)
        {
            try
            {
                string[] parts = matKhauDaBam.Split('$');

                if (parts.Length != 4 ||
                    parts[0] != "PBKDF2-SHA256")
                    return false;

                int soLanLap = int.Parse(parts[1]);

                if (soLanLap < 100000 ||
                    soLanLap > 1000000)
                    return false;

                byte[] salt =
                    Convert.FromBase64String(parts[2]);

                byte[] hashCu =
                    Convert.FromBase64String(parts[3]);

                if (salt.Length != 16 ||
                    hashCu.Length != 32)
                    return false;

                using (var pbkdf2 = new Rfc2898DeriveBytes(
                    matKhau,
                    salt,
                    soLanLap,
                    HashAlgorithmName.SHA256))
                {
                    byte[] hashMoi =
                        pbkdf2.GetBytes(hashCu.Length);

                    int khacNhau = 0;

                    for (int i = 0; i < hashCu.Length; i++)
                    {
                        khacNhau |= hashCu[i] ^ hashMoi[i];
                    }

                    return khacNhau == 0;
                }
            }
            catch
            {
                return false;
            }
        }

        // =====================================
        // 5. ĐĂNG KÝ - POST - SQL
        // =====================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Dangky(
            string hoTen,
            string email,
            string password,
            string confirmPassword)
        {
            hoTen = (hoTen ?? "").Trim();
            email = (email ?? "").Trim();

            if (string.IsNullOrWhiteSpace(hoTen) ||
                hoTen.Length > 30 ||
                string.IsNullOrWhiteSpace(email) ||
                email.Length > 100 ||
                !email.Contains("@"))
            {
                ViewBag.Error =
                    "Họ tên hoặc email không hợp lệ!";
                return View();
            }

            if (string.IsNullOrEmpty(password) ||
                password.Length < 8)
            {
                ViewBag.Error =
                    "Mật khẩu phải có ít nhất 8 ký tự!";
                return View();
            }

            if (password != confirmPassword)
            {
                ViewBag.Error =
                    "Mật khẩu xác nhận không khớp!";
                return View();
            }

            try
            {
                var factory = new SqlConnectionFactory();

                using (var conn = factory.CreateConnection())
                {
                    conn.Open();

                    string sqlCheck = @"
                        SELECT COUNT(*)
                        FROM dbo.KhachHang
                        WHERE Email = @Email";

                    using (var cmd = new SqlCommand(sqlCheck, conn))
                    {
                        cmd.Parameters.Add(
                            "@Email", SqlDbType.VarChar, 100
                        ).Value = email;

                        int count = Convert.ToInt32(
                            cmd.ExecuteScalar());

                        if (count > 0)
                        {
                            ViewBag.Error =
                                "Email đã được đăng ký!";
                            return View();
                        }
                    }

                    string sqlInsert = @"
                        INSERT INTO dbo.KhachHang
                        (HoTen, Email, MatKhauTK, PhanQuyen)
                        VALUES
                        (@HoTen, @Email, @MatKhauTK, @PhanQuyen)";

                    using (var cmd = new SqlCommand(sqlInsert, conn))
                    {
                        cmd.Parameters.Add(
                            "@HoTen", SqlDbType.NVarChar, 30
                        ).Value = hoTen;

                        cmd.Parameters.Add(
                            "@Email", SqlDbType.VarChar, 100
                        ).Value = email;

                        cmd.Parameters.Add(
                            "@MatKhauTK", SqlDbType.VarChar, 255
                        ).Value = BamMatKhau(password);

                        cmd.Parameters.Add(
                            "@PhanQuyen", SqlDbType.VarChar, 20
                        ).Value = "KhachHang";

                        cmd.ExecuteNonQuery();
                    }
                }

                TempData["ThongBao"] =
                    "Đăng ký thành công! Vui lòng đăng nhập.";

                return RedirectToAction("Dangnhap");
            }
            catch (SqlException ex)
            {
                System.Diagnostics.Debug.WriteLine(ex);

                ViewBag.Error =
                    "Đăng ký thất bại. Vui lòng thử lại.";

                return View();
            }
        }

        // =====================================
        // 6. ĐĂNG NHẬP - GET
        // =====================================
        [HttpGet]
        public ActionResult Dangnhap()
        {
            return View();
        }

        // =====================================
        // 7. ĐĂNG NHẬP - POST - SQL
        // =====================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Dangnhap(
            string email,
            string password)
        {
            email = (email ?? "").Trim();

            if (string.IsNullOrWhiteSpace(email) ||
                string.IsNullOrWhiteSpace(password))
            {
                ViewBag.Error =
                    "Vui lòng nhập email và mật khẩu!";
                return View();
            }

            try
            {
                var factory = new SqlConnectionFactory();

                using (var conn = factory.CreateConnection())
                {
                    conn.Open();

                    string sql = @"
                        SELECT MaKH, HoTen, Email,
                               MatKhauTK, PhanQuyen
                        FROM dbo.KhachHang
                        WHERE Email = @Email";

                    using (var cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.Add(
                            "@Email", SqlDbType.VarChar, 100
                        ).Value = email;

                        using (var reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                string matKhauSQL =
                                    reader["MatKhauTK"].ToString();

                                if (KiemTraMatKhau(
                                    password, matKhauSQL))
                                {
                                    int maKH = Convert.ToInt32(
                                        reader["MaKH"]);

                                    string hoTen =
                                        reader["HoTen"].ToString();

                                    string phanQuyen =
                                        reader["PhanQuyen"].ToString();

                                    Session.Clear();

                                    Session["MaKH"] = maKH;

                                    Session["HoTen"] = hoTen;
                                    Session["Email"] = email;
                                    Session["PhanQuyen"] = phanQuyen;

                                    TempData["ThongBao"] =
                                        "Đăng nhập thành công!";

                                    return RedirectToAction("Index");
                                }
                            }
                        }
                    }
                }

                ViewBag.Error =
                    "Email hoặc mật khẩu không đúng!";

                return View();
            }
            catch (SqlException ex)
            {
                System.Diagnostics.Debug.WriteLine(ex);

                ViewBag.Error =
                    "Không thể đăng nhập. Vui lòng thử lại.";

                return View();
            }
        }

        // =====================================
        // 8. ĐĂNG XUẤT
        // =====================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Dangxuat()
        {
            Session.Clear();
            Session.Abandon();

            return RedirectToAction("Dangnhap");

        }



        // =====================================
        // 9. GIỎ HÀNG - SQL SERVER
        // =====================================
        [HttpGet]
        public ActionResult Giohang()
        {
            if (Session["MaKH"] == null)
                return RedirectToAction("Dangnhap");

            int maKH = Convert.ToInt32(Session["MaKH"]);
            return View(LayGioHangSql(maKH));
        }

        private List<GioHangDong> LayGioHangSql(int maKH)
        {
            var danhSach = new List<GioHangDong>();
            var factory = new SqlConnectionFactory();

            using (var conn = factory.CreateConnection())
            {
                conn.Open();
                const string sql = @"
                    SELECT sp.MaSP, sp.TenSP, sp.GiaBan, sp.HinhAnh,
                           sp.SLTonKho, SUM(CONVERT(int, ct.SoLuong)) AS SoLuong
                    FROM dbo.GioHang gh
                    INNER JOIN dbo.ChiTietGioHang ct ON ct.MaGH = gh.MaGH
                    INNER JOIN dbo.SanPham sp ON sp.MaSP = ct.MaSP
                    WHERE gh.MaKH = @MaKH
                    GROUP BY sp.MaSP, sp.TenSP, sp.GiaBan,
                             sp.HinhAnh, sp.SLTonKho";
                using (var cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@MaKH", SqlDbType.Int).Value = maKH;
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            danhSach.Add(new GioHangDong
                            {
                                Ma = Convert.ToInt32(reader["MaSP"]),
                                Ten = Convert.ToString(reader["TenSP"]),
                                Gia = Convert.ToDecimal(reader["GiaBan"]),
                                HinhAnh = Convert.ToString(reader["HinhAnh"]),
                                SLTonKho = Convert.ToInt32(reader["SLTonKho"]),
                                SoLuong = Convert.ToInt32(reader["SoLuong"])
                            });
                        }
                    }
                }
            }
            return danhSach;
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ThemVaoGio(int ma)
        {
            if (Session["MaKH"] == null)
                return RedirectToAction("Dangnhap");

            int maKH = Convert.ToInt32(Session["MaKH"]);
            var factory = new SqlConnectionFactory();

            try
            {
                using (var conn = factory.CreateConnection())
                {
                    conn.Open();
                    using (var tx = conn.BeginTransaction(IsolationLevel.Serializable))
                    {
                        try
                        {
                            int tonKho;
                            using (var cmd = new SqlCommand(
                                "SELECT SLTonKho FROM dbo.SanPham WITH (UPDLOCK, HOLDLOCK) WHERE MaSP = @MaSP", conn, tx))
                            {
                                cmd.Parameters.Add("@MaSP", SqlDbType.Int).Value = ma;
                                object result = cmd.ExecuteScalar();
                                if (result == null || result == DBNull.Value)
                                {
                                    tx.Rollback();
                                    return HttpNotFound();
                                }
                                tonKho = Convert.ToInt32(result);
                            }

                            int maGH;
                            using (var cmd = new SqlCommand(
                                "SELECT TOP (1) MaGH FROM dbo.GioHang WITH (UPDLOCK, HOLDLOCK) WHERE MaKH = @MaKH ORDER BY MaGH", conn, tx))
                            {
                                cmd.Parameters.Add("@MaKH", SqlDbType.Int).Value = maKH;
                                object result = cmd.ExecuteScalar();
                                maGH = result == null ? 0 : Convert.ToInt32(result);
                            }

                            if (maGH == 0)
                            {
                                // Yêu cầu dbo.GioHang.MaGH là IDENTITY.
                                using (var cmd = new SqlCommand(
                                    "INSERT INTO dbo.GioHang (MaKH, NgayTao) OUTPUT INSERTED.MaGH VALUES (@MaKH, GETDATE())", conn, tx))
                                {
                                    cmd.Parameters.Add("@MaKH", SqlDbType.Int).Value = maKH;
                                    maGH = Convert.ToInt32(cmd.ExecuteScalar());
                                }
                            }

                            int soLuongHienTai;
                            using (var cmd = new SqlCommand(
                                "SELECT SoLuong FROM dbo.ChiTietGioHang WITH (UPDLOCK, HOLDLOCK) WHERE MaGH = @MaGH AND MaSP = @MaSP", conn, tx))
                            {
                                cmd.Parameters.Add("@MaGH", SqlDbType.Int).Value = maGH;
                                cmd.Parameters.Add("@MaSP", SqlDbType.Int).Value = ma;
                                object result = cmd.ExecuteScalar();
                                soLuongHienTai = result == null ? 0 : Convert.ToInt32(result);
                            }

                            if (soLuongHienTai >= tonKho || soLuongHienTai >= short.MaxValue)
                            {
                                tx.Rollback();
                                TempData["ThongBao"] = "Sản phẩm đã hết hàng hoặc vượt số lượng tồn kho.";
                                return RedirectToAction("Giohang");
                            }

                            if (soLuongHienTai == 0)
                            {
                                using (var cmd = new SqlCommand(
                                    "INSERT INTO dbo.ChiTietGioHang (MaGH, MaSP, SoLuong) VALUES (@MaGH, @MaSP, 1)", conn, tx))
                                {
                                    cmd.Parameters.Add("@MaGH", SqlDbType.Int).Value = maGH;
                                    cmd.Parameters.Add("@MaSP", SqlDbType.Int).Value = ma;
                                    cmd.ExecuteNonQuery();
                                }
                            }
                            else
                            {
                                using (var cmd = new SqlCommand(
                                    "UPDATE dbo.ChiTietGioHang SET SoLuong = SoLuong + 1 WHERE MaGH = @MaGH AND MaSP = @MaSP", conn, tx))
                                {
                                    cmd.Parameters.Add("@MaGH", SqlDbType.Int).Value = maGH;
                                    cmd.Parameters.Add("@MaSP", SqlDbType.Int).Value = ma;
                                    cmd.ExecuteNonQuery();
                                }
                            }

                            tx.Commit();
                        }
                        catch
                        {
                            tx.Rollback();
                            throw;
                        }
                    }
                }
                TempData["ThongBao"] = "Đã thêm sản phẩm vào giỏ hàng!";
            }
            catch (SqlException ex)
            {
                System.Diagnostics.Debug.WriteLine(ex);
                TempData["ThongBao"] = "Không thể cập nhật giỏ hàng. Hãy kiểm tra cấu trúc bảng SQL.";
            }
            return RedirectToAction("Giohang");
        }

        // =====================================
        // 10. THÔNG BÁO
        // =====================================
        [HttpGet]
        public ActionResult ThongBao()
        {
            if (Session["MaKH"] == null)
            {
                return RedirectToAction("Dangnhap", "TrangChu");
            }
            int MaKH = Convert.ToInt32(Session["MaKH"]);
            var danhSach = new List< Soppe.Models.ThongBao>();
            try
            {
                var factory = new SqlConnectionFactory();
                using (var conn = factory.CreateConnection())
                {
                    conn.Open();

                    string sql = @"
                   SELECT MaTB, MaKH, TieuDe,NoiDung,LoaiTB,MaDH,NgayTao,DaDoc
                   FROM dbo.ThongBao
                   WHERE MaKH =@MaKH
                    ORDER BY NgayTao DESC, MaTB DESC";

                    using (var cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.Add("@MaKH", SqlDbType.Int).Value = MaKH;

                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                danhSach.Add(new Soppe.Models.ThongBao
                                {
                                    MaTB = Convert.ToInt32(reader["MaTB"]),
                                    MaKH = Convert.ToInt32(reader["MaKH"]),
                                    TieuDe = Convert.ToString(reader["TieuDe"]),
                                    NoiDung = Convert.ToString(reader["NoiDung"]),
                                    LoaiTB = Convert.ToString(reader["LoaiTB"]),
                                    MaDH = reader["MaDH"] == DBNull.Value ? (int?)null : Convert.ToInt32(reader["MaDH"]),
                                    NgayTao = Convert.ToDateTime(reader["NgayTao"]),
                                    DaDoc = Convert.ToBoolean(reader["DaDoc"])
                                });
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(ex);
                TempData["ThongBaoLoi"] = "Không thể thông báo.Vui lòng thử lại.";
            }
            return View(danhSach);
        }

    
           [HttpGet]
        public ActionResult KiemTraGioHangSQL()
        {
            if (Session["MaKH"] == null)
            {
                return Content("Bạn chưa đăng nhập!");
            }

            try
            {
                int maKH = Convert.ToInt32(Session["MaKH"]);

                var gioHang = LayGioHangSql(maKH);

                return Content(
                    "KẾT NỐI GIỎ HÀNG SQL THÀNH CÔNG!\n" +
                    "Mã khách hàng: " + maKH + "\n" +
                    "Số sản phẩm: " + gioHang.Count,
                    "text/plain"
                );
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(ex);

                return Content(
                    "Không đọc được giỏ hàng SQL. " +
                    "Kiểm tra cửa sổ Output trong Visual Studio.",
                    "text/plain"
                );
            }
        }

    }
}

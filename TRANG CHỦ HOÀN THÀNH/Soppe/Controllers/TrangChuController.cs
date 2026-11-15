using Soppe.Data;
using Soppe.Models;
using Soppe.Security;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Net.Mail;
using System.Web.Mvc;

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
            if (User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Index");
            }
            return View(new DangKyViewModel());
        }

        // =====================================
        // 3. ĐĂNG KÝ - POST
        // =====================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Dangky(DangKyViewModel model)
        {
            if (model == null)
            {
                return View(new DangKyViewModel());
            }

            model.HoTen = (model.HoTen ?? "").Trim();
            model.Email = (model.Email ?? "").Trim().ToLowerInvariant();

            if (!ModelState.IsValid)
            {
                return View(model);
            }

            if (!EmailHopLe(model.Email))
            {
                ModelState.AddModelError("Email", "Địa chỉ email không hợp lệ.");
                return View(model);
            }

            if (!PasswordHasher.KiemTraDoManhMatKhau(model.Password, model.Email, model.HoTen, out string loiMatKhau))
            {
                ModelState.AddModelError("Password", loiMatKhau);
                return View(model);
            }

            try
            {
                var factory = new SqlConnectionFactory();
                using (var conn = factory.CreateConnection())
                {
                    conn.Open();

                    const string sqlCheck = "SELECT COUNT(1) FROM dbo.KhachHang WHERE Email = @Email";
                    using (var cmd = new SqlCommand(sqlCheck, conn))
                    {
                        cmd.Parameters.Add("@Email", SqlDbType.VarChar, 100).Value = model.Email;
                        if (Convert.ToInt32(cmd.ExecuteScalar()) > 0)
                        {
                            ModelState.AddModelError("Email", "Email này đã được sử dụng. Vui lòng chọn email khác.");
                            return View(model);
                        }
                    }

                    // Máy chủ tự ấn định quyền KhachHang, TrangThai = 1 và SecurityStamp ngẫu nhiên
                    const string sqlInsert = @"
                        INSERT INTO dbo.KhachHang
                            (HoTen, Email, MatKhauTK, PhanQuyen, TrangThai, SoLanDangNhapSai, SecurityStamp)
                        OUTPUT INSERTED.MaKH
                        VALUES
                            (@HoTen, @Email, @MatKhauTK, @PhanQuyen, 1, 0, @SecurityStamp)";

                    int maKHMoi;
                    using (var cmd = new SqlCommand(sqlInsert, conn))
                    {
                        cmd.Parameters.Add("@HoTen", SqlDbType.NVarChar, 30).Value = model.HoTen;
                        cmd.Parameters.Add("@Email", SqlDbType.VarChar, 100).Value = model.Email;
                        cmd.Parameters.Add("@MatKhauTK", SqlDbType.VarChar, 255).Value = PasswordHasher.BamMatKhau(model.Password);
                        cmd.Parameters.Add("@PhanQuyen", SqlDbType.VarChar, 20).Value = "KhachHang";
                        cmd.Parameters.Add("@SecurityStamp", SqlDbType.VarChar, 64).Value = Guid.NewGuid().ToString("N");

                        maKHMoi = Convert.ToInt32(cmd.ExecuteScalar());
                    }

                    SecurityAuditLogger.GhiNhatKy(HttpContext, "DANG_KY", true, maKHMoi, model.Email, "Tạo tài khoản khách hàng mới");
                }

                TempData["ThongBao"] = "Đăng ký thành công! Vui lòng đăng nhập.";
                return RedirectToAction("Dangnhap");
            }
            catch (SqlException ex)
            {
                System.Diagnostics.Debug.WriteLine(ex);
                if (ex.Number == 2627 || ex.Number == 2601)
                {
                    ModelState.AddModelError("Email", "Email này đã được đăng ký.");
                }
                else
                {
                    ViewBag.Error = "Không thể hoàn tất đăng ký lúc này. Vui lòng thử lại sau.";
                }
                return View(model);
            }
        }

        // =====================================
        // 4. ĐĂNG NHẬP - GET
        // =====================================
        [HttpGet]
        public ActionResult Dangnhap(string returnUrl)
        {
            if (User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Index");
            }

            return View(new DangNhapViewModel { ReturnUrl = returnUrl });
        }

        // =====================================
        // 5. ĐĂNG NHẬP - POST
        // =====================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Dangnhap(DangNhapViewModel model)
        {
            if (model == null)
            {
                return View(new DangNhapViewModel());
            }

            model.Email = (model.Email ?? "").Trim().ToLowerInvariant();
            string clientIp = SecurityAuditLogger.LayDiaChiIP(HttpContext);

            // 1. Kiểm tra chặn IP nếu đang dò quét hàng loạt
            if (AuthHelper.IPDangBiTamKhoa(clientIp, out int phutKhoaIP))
            {
                ViewBag.Error = $"Hệ thống tạm chặn yêu cầu từ mạng của bạn do thử sai quá nhiều lần. Vui lòng thử lại sau {phutKhoaIP} phút.";
                return View(model);
            }

            if (!ModelState.IsValid)
            {
                return View(model);
            }

            try
            {
                var factory = new SqlConnectionFactory();
                using (var conn = factory.CreateConnection())
                {
                    conn.Open();

                    const string sql = @"
                        SELECT MaKH, HoTen, Email, MatKhauTK, PhanQuyen,
                               TrangThai, SoLanDangNhapSai, KhoaDenLuc, SecurityStamp
                        FROM dbo.KhachHang
                        WHERE Email = @Email";

                    int? maKH = null;
                    string hoTen = null;
                    string matKhauSQL = null;
                    string phanQuyen = null;
                    bool trangThai = true;
                    int soLanSai = 0;
                    DateTime? khoaDenLuc = null;
                    string securityStamp = null;

                    using (var cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.Add("@Email", SqlDbType.VarChar, 100).Value = model.Email;
                        using (var reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                maKH = Convert.ToInt32(reader["MaKH"]);
                                hoTen = Convert.ToString(reader["HoTen"]);
                                matKhauSQL = Convert.ToString(reader["MatKhauTK"]);
                                phanQuyen = Convert.ToString(reader["PhanQuyen"]);
                                trangThai = reader["TrangThai"] == DBNull.Value || Convert.ToBoolean(reader["TrangThai"]);
                                soLanSai = reader["SoLanDangNhapSai"] == DBNull.Value ? 0 : Convert.ToInt32(reader["SoLanDangNhapSai"]);
                                khoaDenLuc = reader["KhoaDenLuc"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(reader["KhoaDenLuc"]);
                                securityStamp = Convert.ToString(reader["SecurityStamp"]);
                            }
                        }
                    }

                    // 2. Tài khoản không tồn tại -> chạy băm giả chống Timing Attack
                    if (!maKH.HasValue)
                    {
                        PasswordHasher.KiemTraMatKhau(model.Password, PasswordHasher.DUMMY_HASH, out _);
                        AuthHelper.GhiNhanIPSai(clientIp);
                        SecurityAuditLogger.GhiNhatKy(HttpContext, "DANG_NHAP_SAI", false, null, model.Email, "Email không tồn tại");

                        ViewBag.Error = "Email hoặc mật khẩu không đúng!";
                        return View(model);
                    }

                    // 3. Kiểm tra tài khoản có đang bị khóa tạm thời do nhập sai nhiều lần không
                    if (khoaDenLuc.HasValue && khoaDenLuc.Value > DateTime.UtcNow)
                    {
                        int phutConLai = (int)Math.Ceiling((khoaDenLuc.Value - DateTime.UtcNow).TotalMinutes);
                        SecurityAuditLogger.GhiNhatKy(HttpContext, "DANG_NHAP_BI_CHAN", false, maKH, model.Email, "Đang trong thời gian khóa tạm thời");

                        ViewBag.Error = $"Tài khoản tạm khóa do nhập sai mật khẩu nhiều lần. Vui lòng thử lại sau {phutConLai} phút.";
                        return View(model);
                    }

                    // 4. Kiểm tra tài khoản có bị Admin vô hiệu hóa vĩnh viễn không
                    if (!trangThai)
                    {
                        SecurityAuditLogger.GhiNhatKy(HttpContext, "DANG_NHAP_BI_CHAN", false, maKH, model.Email, "Tài khoản bị khóa bởi Admin");
                        ViewBag.Error = "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên Soppe.";
                        return View(model);
                    }

                    // 5. Đối chiếu mật khẩu PBKDF2
                    bool matKhauDung = PasswordHasher.KiemTraMatKhau(model.Password, matKhauSQL, out bool canNangCapBam);

                    if (!matKhauDung)
                    {
                        int soLanSaiMoi = soLanSai + 1;
                        DateTime? mocKhoaMoi = null;
                        string thongBaoLoi = "Email hoặc mật khẩu không đúng!";

                        if (soLanSaiMoi >= AuthHelper.SO_LAN_SAI_TAI_KHOAN_TOI_DA)
                        {
                            mocKhoaMoi = DateTime.UtcNow.AddMinutes(AuthHelper.PHUT_KHOA_TAI_KHOAN);
                            thongBaoLoi = $"Bạn đã nhập sai {AuthHelper.SO_LAN_SAI_TAI_KHOAN_TOI_DA} lần. Tài khoản tạm khóa trong {AuthHelper.PHUT_KHOA_TAI_KHOAN} phút.";
                        }

                        const string sqlFail = @"
                            UPDATE dbo.KhachHang
                            SET SoLanDangNhapSai = @SoLanSai,
                                KhoaDenLuc = @KhoaDenLuc
                            WHERE MaKH = @MaKH";

                        using (var cmdFail = new SqlCommand(sqlFail, conn))
                        {
                            cmdFail.Parameters.Add("@SoLanSai", SqlDbType.Int).Value = soLanSaiMoi;
                            cmdFail.Parameters.Add("@KhoaDenLuc", SqlDbType.DateTime2).Value = (object)mocKhoaMoi ?? DBNull.Value;
                            cmdFail.Parameters.Add("@MaKH", SqlDbType.Int).Value = maKH.Value;
                            cmdFail.ExecuteNonQuery();
                        }

                        AuthHelper.GhiNhanIPSai(clientIp);
                        SecurityAuditLogger.GhiNhatKy(
                            HttpContext,
                            mocKhoaMoi.HasValue ? "KHOA_TAI_KHOAN" : "DANG_NHAP_SAI",
                            false,
                            maKH,
                            model.Email,
                            $"Sai lần thứ {soLanSaiMoi}"
                        );

                        ViewBag.Error = thongBaoLoi;
                        return View(model);
                    }

                    // 6. Đăng nhập thành công: Reset bộ đếm sai, cập nhật giờ đăng nhập & rehash nếu cần
                    string hashCapNhat = canNangCapBam ? PasswordHasher.BamMatKhau(model.Password) : matKhauSQL;
                    const string sqlSuccess = @"
                        UPDATE dbo.KhachHang
                        SET SoLanDangNhapSai = 0,
                            KhoaDenLuc = NULL,
                            LanDangNhapCuoi = SYSUTCDATETIME(),
                            MatKhauTK = @MatKhauTK
                        WHERE MaKH = @MaKH";

                    using (var cmdOk = new SqlCommand(sqlSuccess, conn))
                    {
                        cmdOk.Parameters.Add("@MatKhauTK", SqlDbType.VarChar, 255).Value = hashCapNhat;
                        cmdOk.Parameters.Add("@MaKH", SqlDbType.Int).Value = maKH.Value;
                        cmdOk.ExecuteNonQuery();
                    }

                    // Cấp cookie xác thực + xoay vòng Session ID
                    AuthHelper.TaoPhienDangNhap(
                        HttpContext,
                        maKH.Value,
                        model.Email,
                        hoTen,
                        phanQuyen,
                        securityStamp,
                        model.GhiNho
                    );

                    SecurityAuditLogger.GhiNhatKy(HttpContext, "DANG_NHAP_OK", true, maKH, model.Email, "Đăng nhập thành công");
                    TempData["ThongBao"] = "Đăng nhập thành công!";

                    if (AuthHelper.LaUrlNoiBoAnToan(Url, model.ReturnUrl))
                    {
                        return Redirect(model.ReturnUrl);
                    }

                    if (string.Equals(phanQuyen, "Admin", StringComparison.OrdinalIgnoreCase))
                    {
                        return RedirectToAction("Index", "Admin");
                    }

                    return RedirectToAction("Index", "TrangChu");
                }
            }
            catch (SqlException ex)
            {
                System.Diagnostics.Debug.WriteLine(ex);
                ViewBag.Error = "Hệ thống đang bận, không thể đăng nhập lúc này. Vui lòng thử lại.";
                return View(model);
            }
        }

        // =====================================
        // 6. ĐĂNG XUẤT (CHỈ CHẤP NHẬN POST + CSRF TOKEN)
        // =====================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Dangxuat()
        {
            int? maKH = AuthHelper.LayMaKHHienTai(HttpContext);
            string email = User?.Identity?.Name;

            SecurityAuditLogger.GhiNhatKy(HttpContext, "DANG_XUAT", true, maKH, email, "Người dùng chủ động đăng xuất");
            AuthHelper.DangXuat(HttpContext);

            TempData["ThongBao"] = "Bạn đã đăng xuất an toàn.";
            return RedirectToAction("Dangnhap");
        }

        // =====================================
        // 7. GIỎ HÀNG & THÔNG BÁO (ĐÃ BẢO VỆ XÁC THỰC)
        // =====================================
        [HttpGet]
        [PhanQuyenAuthorize]
        public ActionResult Giohang()
        {
            int? maKH = AuthHelper.LayMaKHHienTai(HttpContext);
            if (!maKH.HasValue)
                return RedirectToAction("Dangnhap");

            return View(LayGioHangSql(maKH.Value));
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
        [PhanQuyenAuthorize]
        public ActionResult ThemVaoGio(int ma)
        {
            int? maKHOpt = AuthHelper.LayMaKHHienTai(HttpContext);
            if (!maKHOpt.HasValue)
                return RedirectToAction("Dangnhap");

            int maKH = maKHOpt.Value;
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
                TempData["ThongBao"] = "Không thể cập nhật giỏ hàng. Vui lòng thử lại.";
            }
            return RedirectToAction("Giohang");
        }

        [HttpGet]
        [PhanQuyenAuthorize]
        public ActionResult ThongBao()
        {
            int? maKHOpt = AuthHelper.LayMaKHHienTai(HttpContext);
            if (!maKHOpt.HasValue)
            {
                return RedirectToAction("Dangnhap", "TrangChu");
            }

            int MaKH = maKHOpt.Value;
            var danhSach = new List<Soppe.Models.ThongBao>();
            try
            {
                var factory = new SqlConnectionFactory();
                using (var conn = factory.CreateConnection())
                {
                    conn.Open();
                    const string sql = @"
                        SELECT MaTB, MaKH, TieuDe, NoiDung, LoaiTB, MaDH, NgayTao, DaDoc
                        FROM dbo.ThongBao
                        WHERE MaKH = @MaKH
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
                TempData["ThongBaoLoi"] = "Không thể tải thông báo. Vui lòng thử lại.";
            }
            return View(danhSach);
        }

        private bool EmailHopLe(string email)
        {
            if (string.IsNullOrWhiteSpace(email) || email.Length > 100)
                return false;

            try
            {
                var addr = new MailAddress(email);
                return addr.Address == email && email.Contains(".");
            }
            catch
            {
                return false;
            }
        }
    }
}
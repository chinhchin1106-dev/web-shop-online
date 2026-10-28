using sộp_peee_ewwwww.Models;
using SopPe.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web.Mvc;

namespace SopPe.Controllers
{
    public class TrangChuController : Controller
    {
        [HttpGet]
        public ActionResult Dangky()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Dangky(string hoTen,
                                   string email,
                                   string password,
                                  string confirmPassword)
        {


            // 1. Loại bỏ khoảng trắng thừa
            hoTen = (hoTen ?? "").Trim();
            email = (email ?? "").Trim();
            // 2. Kiểm tra họ tên
            if (hoTen.Length == 0 || hoTen.Length > 30)
            {
                ViewBag.Error = "Họ tên phải từ 1 đến 30 ký tự.";
                return View();
            }
            // 3. Kiểm tra email
            if (email.Length == 0 || email.Length > 100)
            {
                ViewBag.Error = "Vui lòng nhập email hợp lệ";
                return View();
            }
            //4. Kiểm tra mật khẩu
            if (string.IsNullOrEmpty(password) || password.Length < 8)
            {
                ViewBag.Error = "Mật khẩu phải có ít nhất 8 ký tự";
                return View();
            }
            //5. Kiểm tra mật khẩu xác nhận
            if (password != confirmPassword)
            {
                ViewBag.Error = "Mật khẩu xác nhận không khớp";
                return View();
            }
            //6. Lấy chuỗi kết nối trong Web.config
            string connectionString = ConfigurationManager.ConnectionStrings["SopPeConnection"]
                .ConnectionString;
            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    //7.Kiểm tra email đã tồn tại chưa
                    string checkSql = "SELECT COUNT (*) FROM KhachHang WHERE Email = @Email";
                    using (SqlCommand checkCmd = new SqlCommand(checkSql, conn))
                    {
                        checkCmd.Parameters.Add("@Email", System.Data.SqlDbType.VarChar, 100).Value = email;
                        int count = (int)checkCmd.ExecuteScalar();
                        if (count > 0)
                        {
                            ViewBag.Error = "Email này đã được đăng ký";
                            return View();
                        }
                    }
                    //8. Mã hóa mật khẩu bằng BCrypt
                    string matKhauHash = BCrypt.Net.BCrypt.HashPassword(password);
                    //9.Thêm khách hàng vào SQL Server
                    string insertSql = @"INSERT INTO KhachHang
                    (HoTen, Email, MatKhauTK, PhanQuyen)
                     VALUES
                    (@HoTen, @Email, @MatKhauTK, @PhanQuyen)";
                    using (SqlCommand cmd = new SqlCommand(insertSql, conn))
                    {
                        cmd.Parameters.Add("@HoTen", SqlDbType.NVarChar, 30).Value = hoTen;
                        cmd.Parameters.Add("@Email", SqlDbType.VarChar, 100).Value = email;
                        cmd.Parameters.Add("@MatKhauTK", SqlDbType.Char, 60).Value = matKhauHash;
                        cmd.Parameters.Add("@PhanQuyen", SqlDbType.VarChar, 20).Value = "Customer";
                        cmd.ExecuteNonQuery();

                    }
                }
                //10.Thông báo thành công và chuyển sang đăng nhập
                TempData["ThongBao"] = "Đăng ký thành công! Hãy đăng nhập";
                return RedirectToAction("Dangnhap");

            }
            catch (SqlException)
            {
                ViewBag.Error =
             "Không thể đăng ký. Hãy kiểm tra dữ liệu và kết nối SQL Server.";

                return View();
            }
        }
       

        public ActionResult Index()
        {
            return View();
        }


        public ActionResult Giohang()
        {
            if (Session["MaKH"]==null)
            {
                return RedirectToAction("Dangnhap");
            }
            int maKH = Convert.ToInt32(Session["MaKH"]);
            var danhSach = new List<GioHangDong>();
            string connectionString = ConfigurationManager.ConnectionStrings["SopPeConnection"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string sql = @"SELECT sp.MaSP,sp.TenSP,sp.GiaBan,sp.HinhAnh,ct.SoLuong
                                FROM GioHang gh
                                INNER JOIN ChiTietGioHang ct ON gh.MaGH = ct.MaGH
                                 INNER JOIN SanPham sp ON ct.MaSP = sp.MaSP
                                 WHERE gh.MaKH = @MaKH
                                 ORDER BY sp.MaSP";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@MaKH", SqlDbType.Int).Value = maKH;
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            danhSach.Add(new GioHangDong()
                            {
                                Ma = Convert.ToInt32(reader["MaSP"]),
                                Ten = reader["TenSP"].ToString(),
                                Gia = Convert.ToDecimal(reader["GiaBan"]),
                                HinhAnh = reader["HinhAnh"] == DBNull.Value
                               ? "" : reader["HinhAnh"].ToString(),
                                SoLuong = Convert.ToInt32(reader["SoLuong"])
                            });
                        }
                    }
                }
            }
            return View(danhSach);
        }

        public ActionResult ThongBao()
        {
            // Kiểm tra khách hàng đăng nhập chưa
            if (Session["MaKH"] == null)
            {
                return RedirectToAction("Dangnhap", "TrangChu");
            }
            int maKH = Convert.ToInt32(Session["MaKH"]);
            List<ThongBao> danhSach = new List<ThongBao>();
            string connectionString = ConfigurationManager.ConnectionStrings["SopPeConnection"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                string sql = @"SELECT MaTB,TieuDe,NoiDung,LoaiTB,MaDH,NgayTao,DaDoc
                                FROM ThongBao
                                WHERE MaKH =@MaKH
                                ORDER BY NgayTao DESC";
                using (SqlCommand cmd = new SqlCommand(sql,conn))
                {
                    cmd.Parameters.Add("@MaKH",SqlDbType.Int).Value = maKH;
                    conn.Open();
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            ThongBao tb = new ThongBao();
                            tb.MaTB = Convert.ToInt32(reader["MaTB"]);
                            tb.TieuDe = reader["TieuDe"].ToString();
                            tb.NoiDung = reader["NoiDung"].ToString();
                            tb.LoaiTB = reader["LoaiTB"].ToString();
                            tb.MaDH = reader["MaDH"] == DBNull.Value ? (int?)null : Convert.ToInt32(reader["MaDH"]);
                            tb.NgayTao = Convert.ToDateTime(reader["NgayTao"]);
                            tb.DaDoc = Convert.ToBoolean(reader["DaDoc"]);

                            danhSach.Add(tb);
                        }
                    }
                }
            }
            return View(danhSach);
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult DanhDauDaDoc(int maTB)
        {
            // Kiểm tra khách hàng đã đăng nhập 
            if (Session["MaKH"] == null)
            {
                return RedirectToAction("Dangnhap", "TrangChu");
            }
            int maKH = Convert.ToInt32(Session["MaKH"]);
            string connectionString = ConfigurationManager.ConnectionStrings["SopPeConnection"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                string sql = @"UPDATE ThongBao
                             SET DaDoc = 1
                              WHERE MaTB =@MaTB
                             AND MaKH = @MaKH";

                using (SqlCommand cmd = new SqlCommand(sql,conn))
                {
                    cmd.Parameters.Add("@MaTB",SqlDbType.Int).Value = maTB;
                    cmd.Parameters.Add("@MaKH", SqlDbType.Int).Value = maKH;
                    conn.Open();
                    cmd.ExecuteNonQuery();
                }
            }
            return RedirectToAction("ThongBao", "TrangChu");
        }
        [HttpGet]
        public ActionResult Dangnhap()
        {
            return View();
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Dangnhap(string email,string password)
        {
            email = (email ?? "").Trim();
            if (string.IsNullOrWhiteSpace(email)||string.IsNullOrEmpty(password))
            {
                ViewBag.Error = "Vui lòng nhập email và mật khẩu";
                      return View();
            }
           string connectionString = ConfigurationManager.ConnectionStrings["SopPeConnection"]
                                                         .ConnectionString;
            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    string sql = @"SELECT MaKH,HoTen,MatKhauTK
                                   From KhachHang 
                                   Where Email =@Email";
                    using (SqlCommand cmd = new SqlCommand(sql,conn))
                    {
                        cmd.Parameters.Add("@Email", SqlDbType.VarChar, 100).Value = email;
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            if (!reader.Read())
                            {
                                ViewBag.Error = "Email hoặc mật khẩu không chính xác";
                                return View();
                            }
                            int maKH = Convert.ToInt32(reader["MaKH"]);
                            string hoTen = reader["Hoten"].ToString();
                            string matKhauHash = reader["MatkhauTk"].ToString().Trim();
                            bool hopLe;
                            try
                            {
                                hopLe = BCrypt.Net.BCrypt.Verify(password, matKhauHash);

                            }
                            catch (BCrypt.Net.SaltParseException)
                            {
                                hopLe = false;
                            }
                            if (!hopLe)
                            {
                                ViewBag.Error = "Email hoặc mật khẩu không chính xác";
                                return View();
                            }
                            // Lưu thông tin khách hàng đăng nhập
                            Session["MaKH"] = maKH;
                            Session["HoTen"] = hoTen;
                        }
                    }
                }
                TempData["ThongBao"] = "Đăng nhập thành công";
                // Chuyển về trang chủ
                return RedirectToAction("Index");
            }
            catch (SqlException ex)
            {
                ViewBag.Error = "Lỗi SQL: " + ex.Message;
                return View();
            }
        }

        private List<GioHangDong> LayGioHang()
        {
            var gio = Session["GioHang"] as List<GioHangDong>;

            if (gio == null)
            {
                gio = new List<GioHangDong>();
                Session["GioHang"] = gio;
            }

            return gio;
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ThemVaoGio(int ma)
        {
            if (Session["MaKH"] == null)
            {
                return RedirectToAction("Dangnhap");
            }
            int maKH = Convert.ToInt32(Session["MaKH"]);
            string connectionString = ConfigurationManager.ConnectionStrings["SopPeConnection"]
                                                          .ConnectionString;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
               using (SqlTransaction transaction = conn.BeginTransaction())
               {
                    try
                    {
                        //1. Kiểm tra sản phẩm và số lượng tồn kho
                        string sqlSanPham = @"SELECT SLTonKho
                                               FROM SanPham
                                               WHERE MaSP = @MaSP";
                        int tonKho;
                        using (SqlCommand cmd = new SqlCommand(sqlSanPham, conn, transaction))
                        {
                            cmd.Parameters.Add("@MaSP", SqlDbType.Int).Value = ma;
                            object result = cmd.ExecuteScalar();
                            if (result == null || result == DBNull.Value)
                            {
                                transaction.Rollback();
                                return HttpNotFound();
                            }
                            tonKho = Convert.ToInt32(result);
                        }
                        //2.Tìm giỏ hàng của khách;chưa có thì tạo mới.
                        string sqlGioHang = @"
                                     IF NOT EXISTS(SELECT 1 FROM GioHang WHERE MaKH =@MaKH)
                                       BEGIN
                                        INSERT INTO GioHang (MaKH) VALUES (@MaKH)
                                       END;
                                       SELECT MaKH FROM GioHang WHERE MaKH = @MaKH;";
                        int maGH;
                        using (SqlCommand cmd = new SqlCommand(sqlGioHang,conn,transaction))
                        {
                            cmd.Parameters.Add("@MaKH",SqlDbType.Int).Value = maKH;
                            maGH = Convert.ToInt32(cmd.ExecuteScalar());
                        }
                        // 3.Kiểm tra sản phẩm đã có trong giỏ hàng chưa
                        string sqlKiemTra = @"SELECT SoLuong
                                             FROM ChiTietGioHang
                                              WHERE MaGH = @MaGH AND MaSP =@MaSP";
                        object ketQua;
                        using (SqlCommand cmd = new SqlCommand(sqlKiemTra,conn,transaction))
                        {
                            cmd.Parameters.Add("@MaGH", SqlDbType.Int).Value = maGH;
                            cmd.Parameters.Add("@MaSP", SqlDbType.Int).Value = ma;
                            ketQua = cmd.ExecuteScalar();
                        }
                        int soLuongMoi = ketQua == null ? 1 : Convert.ToInt32(ketQua) + 1;
                        // 4. Không cho thêm vượt quá tồn kho
                        if (tonKho < soLuongMoi)
                        {
                            transaction.Rollback();
                            TempData["ThongBao"] = "Số lượng tồn kho không đủ";
                            return RedirectToAction("Giohang");
                        }
                        // 5. Thêm mới hoặc tăng số lượng sản phẩm
                        string sqlCapNhat;
                        if(ketQua == null)
                        {
                            sqlCapNhat = @"INSERT INRO ChiTietGioHang(MaGH,MaSP,SoLuong)
                                           VALUES (@MaGH,@MaSP,1)";               
                        }
                        else
                        {
                            sqlCapNhat = @"UPDATE ChiTietGioHang
                                           SET SoLuong =@SoLuong
                                           WHERE MaGH =@MaGH AND MaSP = @MaSP";
                        }
                        using (SqlCommand cmd = new SqlCommand(sqlCapNhat, conn, transaction))
                        {
                            cmd.Parameters.Add("@MaGH", SqlDbType.Int).Value = maGH;
                            cmd.Parameters.Add("@MaSP", SqlDbType.Int).Value = ma;
                            if(ketQua !=null)
                            {
                                cmd.Parameters.Add("@SoLuong", SqlDbType.SmallInt).Value = soLuongMoi;
                            }
                            cmd.ExecuteNonQuery();
                        }
                        transaction.Commit();
                        TempData["ThongBao"] = "Đã thêm sản phẩm vào giỏ hàng";
                    }
                    catch
                    {
                        transaction.Rollback();
                        throw;
                    }
               }
            }
            return RedirectToAction("Giohang");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult XoaKhoiGio(int ma)
        {
            if (Session["MaKH"] == null)
            {
                return RedirectToAction("Dangnhap");
            }
            int maKH = Convert.ToInt32(Session["MaKH"]);
            string connectionString = ConfigurationManager.ConnectionStrings["SopPeConnection"]
                                                           .ConnectionString;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string sql = @"DELETE FROM ChiTietGioHang
                                WHERE MaSP =@MaSP
                                AND MaGH IN(
                                     SELECT MaGH
                                     FROM GioHang
                                    WHERE MaKH =@MaKH)";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@MaSP",SqlDbType.Int).Value = ma;
                    cmd.Parameters.Add("@MaKH", SqlDbType.Int).Value = maKH;
                    cmd.ExecuteNonQuery ();
                }
            }
            TempData["ThongBao"] = "Đã xóa sản phẩm khỏi giỏ hàng";
                return RedirectToAction("Giohang");
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult CapNhatSoLuong(int ma,int soLuong)
        {
            if (Session["MaKH"] == null)
            {
                return RedirectToAction("Dangnhap");
            }
            if (soLuong < 1 || soLuong > short.MaxValue)
            {
                TempData["ThongBao"] = "Số lượng không hợp lệ";
                return RedirectToAction("Giohang");
            }
            int maKH = Convert.ToInt32(Session["MaKH"]);
            string connectionString = ConfigurationManager.ConnectionStrings["SopPeConnection"]
                                                           .ConnectionString;
            using (SqlConnection conn = new SqlConnection(connectionString))
            { 
                conn.Open ();
                string sql = @"UPDATE ct
                              SET ct.SoLuong =@SoLuong
                               FROM ChiTietGioHang ct
                               INNER JOIN GioHang gh ON ct.MaGH = gh.MaGH
                                INNER JOIN SanPham sp ON ct.MaSP = sp.MaSP
                                WHERE gh.MaKH =@MaKH
                                   AND ct.MaSP =@MaSP
                                    AND @SoLuong <= sp.SLTonKho";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.Add("@SoLuong", SqlDbType.SmallInt).Value = soLuong;
                    cmd.Parameters.Add("@MaKH", SqlDbType.Int).Value = maKH;
                    cmd.Parameters.Add("@SoLuong", SqlDbType.Int).Value = ma;
                    int rows = cmd.ExecuteNonQuery();
                    TempData["ThongBao"] = rows > 0 ? "Đã cập nhật số lượng" : "Không thể cập nhật.Hãy kiểm tra sản phẩm và tồn kho";
                }
            }
            return RedirectToAction("Giohang");
        }
    }
}

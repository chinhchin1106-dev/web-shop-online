using Soppe.Data;
using System;
using System.Collections.Concurrent;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Mvc;
using System.Web.Security;
using System.Web.SessionState;

namespace Soppe.Security
{
    public static class AuthHelper
    {
        private class TrangThaiIP
        {
            public int SoLanSai { get; set; }
            public DateTime MocBatDauUtc { get; set; }
            public DateTime? KhoaDenUtc { get; set; }
        }

        // Chống Credential Stuffing: 1 IP thử sai quá 15 lần trong 10 phút -> khóa IP 15 phút
        private static readonly ConcurrentDictionary<string, TrangThaiIP> _boDemIP
            = new ConcurrentDictionary<string, TrangThaiIP>(StringComparer.OrdinalIgnoreCase);

        public const int SO_LAN_SAI_TAI_KHOAN_TOI_DA = 5;
        public const int PHUT_KHOA_TAI_KHOAN = 15;

        private const int SO_LAN_SAI_IP_TOI_DA = 15;
        private const int PHUT_CUA_SO_IP = 10;
        private const int PHUT_KHOA_IP = 15;

        // ==========================================
        // 1. GIỚI HẠN THỬ SAI TẦNG IP
        // ==========================================
        public static bool IPDangBiTamKhoa(string ip, out int soPhutConLai)
        {
            soPhutConLai = 0;
            if (string.IsNullOrWhiteSpace(ip)) return false;

            if (_boDemIP.TryGetValue(ip, out var state) && state.KhoaDenUtc.HasValue)
            {
                if (state.KhoaDenUtc.Value > DateTime.UtcNow)
                {
                    soPhutConLai = (int)Math.Ceiling((state.KhoaDenUtc.Value - DateTime.UtcNow).TotalMinutes);
                    return true;
                }
                _boDemIP.TryRemove(ip, out _);
            }
            return false;
        }

        public static void GhiNhanIPSai(string ip)
        {
            if (string.IsNullOrWhiteSpace(ip)) return;

            _boDemIP.AddOrUpdate(
                ip,
                _ => new TrangThaiIP { SoLanSai = 1, MocBatDauUtc = DateTime.UtcNow },
                (_, cu) =>
                {
                    if ((DateTime.UtcNow - cu.MocBatDauUtc).TotalMinutes > PHUT_CUA_SO_IP)
                    {
                        cu.SoLanSai = 1;
                        cu.MocBatDauUtc = DateTime.UtcNow;
                        cu.KhoaDenUtc = null;
                        return cu;
                    }

                    cu.SoLanSai++;
                    if (cu.SoLanSai >= SO_LAN_SAI_IP_TOI_DA)
                    {
                        cu.KhoaDenUtc = DateTime.UtcNow.AddMinutes(PHUT_KHOA_IP);
                    }
                    return cu;
                });
        }

        // ==========================================
        // 2. TẠO PHIÊN ĐĂNG NHẬP & CHỐNG SESSION FIXATION
        // ==========================================
        public static void TaoPhienDangNhap(
            HttpContextBase httpContext,
            int maKH,
            string email,
            string hoTen,
            string phanQuyen,
            string securityStamp,
            bool ghiNho = false)
        {
            string roleChuan = string.IsNullOrWhiteSpace(phanQuyen) ? "KhachHang" : phanQuyen.Trim();
            string stampChuan = string.IsNullOrWhiteSpace(securityStamp) ? Guid.NewGuid().ToString("N") : securityStamp.Trim();

            // Đóng gói thông tin định danh vào UserData của Ticket đã mã hóa
            string userData = $"{maKH}|{roleChuan}|{stampChuan}|{hoTen}";

            int thoiHanPhut = ghiNho ? 10080 : 45; // 7 ngày nếu chọn Ghi nhớ, ngược lại 45 phút
            var ticket = new FormsAuthenticationTicket(
                version: 1,
                name: email,
                issueDate: DateTime.Now,
                expiration: DateTime.Now.AddMinutes(thoiHanPhut),
                isPersistent: ghiNho,
                userData: userData,
                cookiePath: FormsAuthentication.FormsCookiePath
            );

            string encryptedTicket = FormsAuthentication.Encrypt(ticket);

            var authCookie = new HttpCookie(FormsAuthentication.FormsCookieName, encryptedTicket)
            {
                HttpOnly = true,
                Secure = httpContext.Request.IsSecureConnection,
                SameSite = SameSiteMode.Lax,
                Path = FormsAuthentication.FormsCookiePath
            };

            if (ghiNho)
            {
                authCookie.Expires = ticket.Expiration;
            }

            httpContext.Response.Cookies.Add(authCookie);

            // Xoay vòng mã Session ID để chặn tấn công Session Fixation
            try
            {
                if (System.Web.HttpContext.Current != null)
                {
                    var manager = new SessionIDManager();
                    string newSessionId = manager.CreateSessionID(System.Web.HttpContext.Current);
                    manager.SaveSessionID(System.Web.HttpContext.Current, newSessionId, out _, out _);
                }
            }
            catch
            {
                // Bỏ qua nếu header đã gửi
            }

            // Nạp dữ liệu vào Session mới
            if (httpContext.Session != null)
            {
                httpContext.Session.Clear();
                httpContext.Session["MaKH"] = maKH;
                httpContext.Session["HoTen"] = hoTen;
                httpContext.Session["Email"] = email;
                httpContext.Session["PhanQuyen"] = roleChuan;
                httpContext.Session["SecurityStamp"] = stampChuan;
                httpContext.Session["StampCheckedUtc"] = DateTime.UtcNow;
            }
        }

        // ==========================================
        // 3. ĐĂNG XUẤT SẠCH SẼ (COOKIE + SESSION)
        // ==========================================
        public static void DangXuat(HttpContextBase httpContext)
        {
            FormsAuthentication.SignOut();

            var expiredAuthCookie = new HttpCookie(FormsAuthentication.FormsCookieName, "")
            {
                Expires = DateTime.Now.AddYears(-1),
                HttpOnly = true,
                Secure = httpContext.Request.IsSecureConnection,
                SameSite = SameSiteMode.Lax,
                Path = FormsAuthentication.FormsCookiePath
            };
            httpContext.Response.Cookies.Add(expiredAuthCookie);

            if (httpContext.Session != null)
            {
                httpContext.Session.Clear();
                httpContext.Session.Abandon();
            }

            var expiredSessionCookie = new HttpCookie("SOPPE_SID", "")
            {
                Expires = DateTime.Now.AddYears(-1),
                HttpOnly = true,
                Secure = httpContext.Request.IsSecureConnection,
                SameSite = SameSiteMode.Lax
            };
            httpContext.Response.Cookies.Add(expiredSessionCookie);
        }

        // ==========================================
        // 4. LẤY MaKH & KIỂM TRA TRẠNG THÁI + SECURITY STAMP
        // ==========================================
        public static int? LayMaKHHienTai(HttpContextBase httpContext)
        {
            if (httpContext?.User?.Identity is FormsIdentity formsIdentity && formsIdentity.IsAuthenticated)
            {
                string[] parts = (formsIdentity.Ticket.UserData ?? "").Split('|');
                if (parts.Length >= 4 && int.TryParse(parts[0], out int maKH))
                {
                    string role = parts[1];
                    string stampCookie = parts[2];
                    string hoTen = parts[3];

                    // Kiểm tra định kỳ mỗi 2 phút với DB xem tài khoản có bị Admin khóa hay đổi SecurityStamp không
                    bool canKiemTraDB = true;
                    if (httpContext.Session != null && httpContext.Session["StampCheckedUtc"] is DateTime lastCheck)
                    {
                        if ((DateTime.UtcNow - lastCheck).TotalMinutes < 2)
                        {
                            canKiemTraDB = false;
                        }
                    }

                    if (canKiemTraDB && !XacMinhTrangThaiVaStampTuDB(maKH, stampCookie))
                    {
                        DangXuat(httpContext);
                        return null;
                    }

                    if (httpContext.Session != null)
                    {
                        httpContext.Session["MaKH"] = maKH;
                        httpContext.Session["PhanQuyen"] = role;
                        httpContext.Session["HoTen"] = hoTen;
                        httpContext.Session["Email"] = formsIdentity.Name;
                        if (canKiemTraDB)
                        {
                            httpContext.Session["StampCheckedUtc"] = DateTime.UtcNow;
                        }
                    }

                    return maKH;
                }
            }

            return null;
        }

        private static bool XacMinhTrangThaiVaStampTuDB(int maKH, string stampCookie)
        {
            try
            {
                var factory = new SqlConnectionFactory();
                using (var conn = factory.CreateConnection())
                {
                    conn.Open();
                    const string sql = @"
                        SELECT TrangThai, SecurityStamp
                        FROM dbo.KhachHang
                        WHERE MaKH = @MaKH";

                    using (var cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.Add("@MaKH", SqlDbType.Int).Value = maKH;
                        using (var reader = cmd.ExecuteReader())
                        {
                            if (!reader.Read()) return false;

                            bool trangThai = reader["TrangThai"] != DBNull.Value && Convert.ToBoolean(reader["TrangThai"]);
                            string stampDB = Convert.ToString(reader["SecurityStamp"]);

                            return trangThai && string.Equals(stampCookie, stampDB, StringComparison.Ordinal);
                        }
                    }
                }
            }
            catch
            {
                return true; // Tránh ngắt phiên người dùng nếu DB gián đoạn tức thời
            }
        }

        // ==========================================
        // 5. CHỐNG OPEN REDIRECT KHI CHUYỂN HƯỚNG
        // ==========================================
        public static bool LaUrlNoiBoAnToan(UrlHelper urlHelper, string returnUrl)
        {
            if (string.IsNullOrWhiteSpace(returnUrl)) return false;
            return urlHelper.IsLocalUrl(returnUrl)
                   && !returnUrl.StartsWith("//")
                   && !returnUrl.StartsWith("/\\");
        }
    }
}
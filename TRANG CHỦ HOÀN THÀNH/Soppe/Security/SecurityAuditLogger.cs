using Soppe.Data;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Web;

namespace Soppe.Security
{
    public static class SecurityAuditLogger
    {
        public static void GhiNhatKy(
            HttpContextBase httpContext,
            string hanhDong,
            bool thanhCong,
            int? maKH = null,
            string emailNhap = null,
            string ghiChu = null)
        {
            try
            {
                string ip = LayDiaChiIP(httpContext);
                string userAgent = httpContext?.Request?.UserAgent ?? "";
                if (userAgent.Length > 250) userAgent = userAgent.Substring(0, 250);
                if (ghiChu != null && ghiChu.Length > 250) ghiChu = ghiChu.Substring(0, 250);

                var factory = new SqlConnectionFactory();
                using (var conn = factory.CreateConnection())
                {
                    conn.Open();
                    const string sql = @"
                        INSERT INTO dbo.NhatKyBaoMat
                            (MaKH, EmailNhap, HanhDong, ThanhCong, DiaChiIP, TrinhDuyet, GhiChu)
                        VALUES
                            (@MaKH, @EmailNhap, @HanhDong, @ThanhCong, @DiaChiIP, @TrinhDuyet, @GhiChu)";

                    using (var cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.Add("@MaKH", SqlDbType.Int).Value = (object)maKH ?? DBNull.Value;
                        cmd.Parameters.Add("@EmailNhap", SqlDbType.VarChar, 100).Value = (object)emailNhap ?? DBNull.Value;
                        cmd.Parameters.Add("@HanhDong", SqlDbType.VarChar, 50).Value = hanhDong;
                        cmd.Parameters.Add("@ThanhCong", SqlDbType.Bit).Value = thanhCong;
                        cmd.Parameters.Add("@DiaChiIP", SqlDbType.VarChar, 45).Value = (object)ip ?? DBNull.Value;
                        cmd.Parameters.Add("@TrinhDuyet", SqlDbType.NVarChar, 255).Value = userAgent;
                        cmd.Parameters.Add("@GhiChu", SqlDbType.NVarChar, 255).Value = (object)ghiChu ?? DBNull.Value;
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("[SecurityAuditLogger] " + ex.Message);
            }
        }

        public static string LayDiaChiIP(HttpContextBase httpContext)
        {
            if (httpContext?.Request == null) return "unknown";
            string ip = httpContext.Request.UserHostAddress ?? "unknown";
            return ip.Length > 45 ? ip.Substring(0, 45) : ip;
        }
    }
}
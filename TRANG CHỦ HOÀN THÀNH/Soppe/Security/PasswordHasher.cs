using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;

namespace Soppe.Security
{
    public static class PasswordHasher
    {
        public const int SO_LAN_LAP_CHUAN = 210000;
        private const int SALT_SIZE = 16;
        private const int HASH_SIZE = 32;

        // Chuỗi băm giả dùng khi email không tồn tại để cân bằng thời gian xử lý
        public const string DUMMY_HASH =
            "PBKDF2-SHA256$210000$AAAAAAAAAAAAAAAAAAAAAA==$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

        private static readonly HashSet<string> MatKhauPhoBien = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "12345678", "123456789", "1234567890", "password", "password1",
            "qwerty123", "admin123", "soppe123", "11111111", "abc12345"
        };

        public static bool KiemTraDoManhMatKhau(string matKhau, string email, string hoTen, out string thongBaoLoi)
        {
            thongBaoLoi = null;

            if (string.IsNullOrEmpty(matKhau) || matKhau.Length < 8 || matKhau.Length > 128)
            {
                thongBaoLoi = "Mật khẩu phải có độ dài từ 8 đến 128 ký tự.";
                return false;
            }

            if (MatKhauPhoBien.Contains(matKhau))
            {
                thongBaoLoi = "Mật khẩu này quá phổ biến và dễ bị đoán. Vui lòng chọn mật khẩu khác.";
                return false;
            }

            bool coChuHoa = matKhau.Any(char.IsUpper);
            bool coChuThuong = matKhau.Any(char.IsLower);
            bool coChuSo = matKhau.Any(char.IsDigit);

            if (!coChuHoa || !coChuThuong || !coChuSo)
            {
                thongBaoLoi = "Mật khẩu phải chứa ít nhất 1 chữ hoa, 1 chữ thường và 1 chữ số.";
                return false;
            }

            if (!string.IsNullOrWhiteSpace(email))
            {
                string phanTenEmail = email.Split('@')[0];
                if (phanTenEmail.Length >= 4 &&
                    matKhau.IndexOf(phanTenEmail, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    thongBaoLoi = "Mật khẩu không được chứa tên tài khoản email của bạn.";
                    return false;
                }
            }

            if (!string.IsNullOrWhiteSpace(hoTen) && hoTen.Trim().Length >= 4 &&
                matKhau.IndexOf(hoTen.Trim(), StringComparison.OrdinalIgnoreCase) >= 0)
            {
                thongBaoLoi = "Mật khẩu không được chứa họ tên của bạn.";
                return false;
            }

            return true;
        }

        public static string BamMatKhau(string matKhau)
        {
            byte[] salt = new byte[SALT_SIZE];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(salt);
            }

            using (var pbkdf2 = new Rfc2898DeriveBytes(
                matKhau,
                salt,
                SO_LAN_LAP_CHUAN,
                HashAlgorithmName.SHA256))
            {
                byte[] hash = pbkdf2.GetBytes(HASH_SIZE);
                return $"PBKDF2-SHA256${SO_LAN_LAP_CHUAN}${Convert.ToBase64String(salt)}${Convert.ToBase64String(hash)}";
            }
        }

        public static bool KiemTraMatKhau(string matKhau, string matKhauDaBam, out bool canNangCapBam)
        {
            canNangCapBam = false;

            try
            {
                if (string.IsNullOrEmpty(matKhau) || string.IsNullOrEmpty(matKhauDaBam))
                    return false;

                string[] parts = matKhauDaBam.Split('$');
                if (parts.Length != 4 || parts[0] != "PBKDF2-SHA256")
                    return false;

                if (!int.TryParse(parts[1], out int soLanLap) || soLanLap < 100000 || soLanLap > 1000000)
                    return false;

                byte[] salt = Convert.FromBase64String(parts[2]);
                byte[] hashCu = Convert.FromBase64String(parts[3]);

                if (salt.Length != SALT_SIZE || hashCu.Length != HASH_SIZE)
                    return false;

                using (var pbkdf2 = new Rfc2898DeriveBytes(
                    matKhau,
                    salt,
                    soLanLap,
                    HashAlgorithmName.SHA256))
                {
                    byte[] hashMoi = pbkdf2.GetBytes(hashCu.Length);
                    int khacNhau = 0;

                    // So sánh từng byte theo thời gian hằng (chống Timing Attack)
                    for (int i = 0; i < hashCu.Length; i++)
                    {
                        khacNhau |= hashCu[i] ^ hashMoi[i];
                    }

                    if (khacNhau == 0)
                    {
                        canNangCapBam = soLanLap < SO_LAN_LAP_CHUAN;
                        return true;
                    }

                    return false;
                }
            }
            catch
            {
                return false;
            }
        }
    }
}
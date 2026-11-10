using System;

namespace Soppe.Models
{
    public class ThongBao
    {
        public int MaTB { get; set; }
        public int MaKH { get; set; }
        public string TieuDe { get; set; }
        public string NoiDung { get; set; }
        public string LoaiTB { get; set; }
        public int? MaDH { get; set; }
        public DateTime NgayTao { get; set; }
        public bool DaDoc { get; set; }
    }
}
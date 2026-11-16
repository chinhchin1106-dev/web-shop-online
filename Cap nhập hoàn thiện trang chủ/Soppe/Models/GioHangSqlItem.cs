using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Soppe.Models
{
    public class GioHangSqlItem
    {
        public int MaSP {  get; set; }
        public string TenSP {  get; set; }
        public string HinhAnh {  get; set; }
        public decimal GiaBan { get; set; }
        public int SoLuong { get; set; }
        public int SLTonKho {  get; set; }
        public decimal ThanhTien
        {
            get {  return GiaBan * SoLuong; }
        }
    }
}
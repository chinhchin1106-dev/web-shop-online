using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace sộp_peee_ewwwww.Models
{
    public class ThongBao
    {
        public int MaTB {  get; set; }
        public string TieuDe {  get; set; }
        public string NoiDung {  get; set; }
        public string LoaiTB { get; set; }
        public int? MaDH { get; set; }
        public System.DateTime NgayTao { get; set; }
        public bool DaDoc {  get; set; }
    }
}
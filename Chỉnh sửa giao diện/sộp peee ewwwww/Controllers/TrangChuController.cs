using sộp_peee_ewwwww.Models;
using SopPe.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Web.Mvc;

namespace SopPe.Controllers
{
    public class TrangChuController : Controller
    {
       
        public ActionResult Dangky()
        {
            return View();
        }

      
        public ActionResult Index()
        {
            return View();
        }


        public ActionResult Giohang()
        {
            return View();
        }

        public ActionResult ThongBao()
        {
           
            return View();
        }
       
        public ActionResult Dangnhap()
        {
            return View();
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

        
        public ActionResult ThemVaoGio(int ma)
        {
            var sanPham = KhoDuLieu.DanhSach
         .FirstOrDefault(x => x.Ma == ma);

            if (sanPham == null)
                return HttpNotFound();

            var gio = LayGioHang();
            var dong = gio.FirstOrDefault(x => x.Ma == ma);

            if (dong == null)
            {
                gio.Add(new GioHangDong
                {
                    Ma = sanPham.Ma,
                    Ten = sanPham.Ten,
                    Gia = sanPham.Gia,
                    SoLuong = 1
                });
            }
            else
            {
                dong.SoLuong++;
            }

            TempData["ThongBao"] = "Đã thêm sản phẩm vào giỏ hàng!";
            return RedirectToAction("Giohang");
        }
        

        
    }
}

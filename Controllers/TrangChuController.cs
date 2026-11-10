
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using SopPe.Models;

namespace SopPe.Controllers
{
    public class TrangChuController : Controller
    {


        [HttpGet]
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
            return View(LayGioHang());
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

        [HttpPost]
        [ValidateAntiForgeryToken]
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

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult XoaKhoiGio(int ma)
        {
            var gio = LayGioHang();
            gio.RemoveAll(x => x.Ma == ma);
            return RedirectToAction("Giohang");
        }
    }
}

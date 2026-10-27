using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Sộp_Pe.Controllers
{
    public class TrangChuController : Controller
    {
        // GET: TrangChu
        public ActionResult Index()
        {
            return View("~/Views/Index/Index.cshtml");
        }
        public ActionResult Dangnhap()
        {
            return View();
        }
        public ActionResult DangKy()
        {
            return View();
        }
        public ActionResult ThongBao()
        {
            return View();
        }
        public ActionResult Giohang()
        {
            return View();
        }
    }
}
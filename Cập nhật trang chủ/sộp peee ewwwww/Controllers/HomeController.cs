using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Configuration;
using System.Data.SqlClient;

namespace sộp_peee_ewwwww.Controllers
{
    public class HomeController : Controller
    {

        public ActionResult Index()
        {
            return RedirectToAction("Index", "TrangChu");
        }

        public ActionResult About()
        {
            ViewBag.Message = "Your application description page.";

            return View();
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "Your contact page.";

            return View();
        }

        public ActionResult KiemTraSQL()
        {
            string configPath = System.Web.Hosting.HostingEnvironment.MapPath("~/Web.config");

            string configText = System.IO.File.ReadAllText(configPath);

            if (!configText.Contains("SopPeConnection"))
            {
                return Content("Web.config đang chạy chưa có SopPeConnection: " + configPath);
            }

            var setting = ConfigurationManager.ConnectionStrings["SopPeConnection"];

            if (setting == null)
            {
                return Content("Có tên trong file nhưng ứng dụng không đọc được cấu hình: " + configPath);
            }

            try
            {
                using (SqlConnection conn = new SqlConnection(setting.ConnectionString))
                {
                    conn.Open();
                    return Content("Kết nối SQL thành công!");
                }
            }
            catch (Exception ex)
            {
                return Content("Lỗi kết nối SQL: " + ex.Message);
            }
        }

    }
}
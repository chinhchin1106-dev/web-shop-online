using System.Web.Mvc;

namespace Soppe.Controllers
{
    public class UuDaiController : Controller
    {
        [HttpGet]
        public ActionResult Index()
        {
            return View();
        }
    }
}
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;

namespace Soppe.Security
{
    public class PhanQuyenAuthorizeAttribute : AuthorizeAttribute
    {
        protected override bool AuthorizeCore(HttpContextBase httpContext)
        {
            if (!base.AuthorizeCore(httpContext))
            {
                return false;
            }

            // Đảm bảo đồng bộ Session["MaKH"] và xác minh SecurityStamp
            int? maKH = AuthHelper.LayMaKHHienTai(httpContext);
            return maKH.HasValue;
        }

        protected override void HandleUnauthorizedRequest(AuthorizationContext filterContext)
        {
            // Chưa đăng nhập -> chuyển thẳng về trang Đăng nhập kèm đường dẫn cũ (returnUrl)
            if (!filterContext.HttpContext.User.Identity.IsAuthenticated)
            {
                filterContext.Result = new RedirectToRouteResult(
                    new RouteValueDictionary(new
                    {
                        controller = "TrangChu",
                        action = "Dangnhap",
                        returnUrl = filterContext.HttpContext.Request.RawUrl
                    })
                );
                return;
            }

            // Đã đăng nhập nhưng vượt quyền (vd: KhachHang truy cập Admin)
            int? maKH = AuthHelper.LayMaKHHienTai(filterContext.HttpContext);
            SecurityAuditLogger.GhiNhatKy(
                filterContext.HttpContext,
                "TRUY_CAP_TRAI_PHEP",
                false,
                maKH,
                filterContext.HttpContext.User.Identity.Name,
                "URL: " + filterContext.HttpContext.Request.RawUrl
            );

            filterContext.Result = new ContentResult
            {
                Content = "403 Forbidden - Tài khoản của bạn không có quyền truy cập chức năng này.",
                ContentType = "text/plain; charset=utf-8"
            };
            filterContext.HttpContext.Response.StatusCode = 403;
            filterContext.HttpContext.Response.TrySkipIisCustomErrors = true;
        }
    }
}
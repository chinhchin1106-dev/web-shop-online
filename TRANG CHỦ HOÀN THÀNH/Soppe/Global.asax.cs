using System;
using System.Security.Principal;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;
using System.Web.Security;

namespace SopPe
{
    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            RouteConfig.RegisterRoutes(RouteTable.Routes);
        }

        protected void Application_PostAuthenticateRequest(object sender, EventArgs e)
        {
            HttpCookie authCookie = Request.Cookies[FormsAuthentication.FormsCookieName];
            if (authCookie == null || string.IsNullOrEmpty(authCookie.Value))
            {
                return;
            }

            try
            {
                FormsAuthenticationTicket ticket = FormsAuthentication.Decrypt(authCookie.Value);
                if (ticket == null || ticket.Expired)
                {
                    return;
                }

                string[] parts = (ticket.UserData ?? "").Split('|');
                string role = parts.Length >= 2 && !string.IsNullOrWhiteSpace(parts[1])
                    ? parts[1]
                    : "KhachHang";

                var identity = new FormsIdentity(ticket);
                HttpContext.Current.User = new GenericPrincipal(identity, new[] { role });
            }
            catch
            {
                // Cookie bị can thiệp hoặc sai khóa MachineKey -> bỏ qua như khách vãng lai
            }
        }
    }
}
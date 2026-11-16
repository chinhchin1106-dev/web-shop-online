using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Soppe.Models;

namespace Soppe.Services
{
    public class DonHangDemoService
    {
        private readonly HttpSessionStateBase session;

        private const string DonKey = "Dat_DonHangDemo";
        private const string PhienKey = "Dat_PhienDatHangDemo";

        public DonHangDemoService(HttpSessionStateBase session)
        {
            if (session == null)
                throw new ArgumentNullException("session");

            this.session = session;
        }

        // SQL-1: Thay phần đọc sản phẩm tại đây.
        // Luôn lấy giá từ máy chủ, không lấy giá từ trình duyệt.
        private ChiTietDonDemo LaySanPham(int ma, int soLuong)
        {
            var sp = KhoDuLieu.DanhSach.FirstOrDefault(x => x.Ma == ma);

            if (sp == null)
                throw new InvalidOperationException(
                    "Sản phẩm mã " + ma + " không còn tồn tại.");

            if (sp.Gia < 0)
                throw new InvalidOperationException(
                    "Giá sản phẩm không hợp lệ.");

            return new ChiTietDonDemo
            {
                Ma = sp.Ma,
                Ten = sp.Ten,
                Gia = sp.Gia,
                SoLuong = soLuong
            };
        }

        // SQL-2: Thay bằng truy vấn đơn hàng của tài khoản đang đăng nhập.
        private List<DonHangDemo> DocDon()
        {
            var don = session[DonKey] as List<DonHangDemo>;

            if (don == null)
            {
                don = new List<DonHangDemo>();
                session[DonKey] = don;
            }

            return don;
        }

        private Dictionary<Guid, PhienDatHangDemo> DocPhien()
        {
            var phien = session[PhienKey]
                as Dictionary<Guid, PhienDatHangDemo>;

            if (phien == null)
            {
                phien = new Dictionary<Guid, PhienDatHangDemo>();
                session[PhienKey] = phien;
            }

            return phien;
        }

        // SQL-3: Thay danh sách mẫu bằng bảng mã giảm giá.
        public List<MaGiamGiaDemo> DanhSachMa()
        {
            return new List<MaGiamGiaDemo>
            {
                new MaGiamGiaDemo
                {
                    Ma = "SOPPE20",
                    MoTa = "Giảm 20%, tối đa 100.000đ",
                    DonToiThieu = 200000m,
                    PhanTram = 20m,
                    GiamToiDa = 100000m
                },
                new MaGiamGiaDemo
                {
                    Ma = "GIAM50K",
                    MoTa = "Giảm trực tiếp 50.000đ",
                    DonToiThieu = 500000m,
                    SoTien = 50000m
                }
            };
        }

        private List<DongGioGui> ChuanHoa(List<DongGioGui> dong)
        {
            if (dong == null || dong.Count == 0 || dong.Count > 50)
                throw new InvalidOperationException(
                    "Giỏ hàng phải có từ 1 đến 50 dòng sản phẩm.");

            foreach (var d in dong)
            {
                if (d == null || d.Id <= 0 ||
                    d.Quantity < 1 || d.Quantity > 99)
                {
                    throw new InvalidOperationException(
                        "Mã sản phẩm hoặc số lượng không hợp lệ.");
                }
            }

            var ketQua = dong.GroupBy(x => x.Id)
                .Select(g => new DongGioGui
                {
                    Id = g.Key,
                    Quantity = g.Sum(x => x.Quantity)
                }).ToList();

            if (ketQua.Any(x => x.Quantity > 99))
                throw new InvalidOperationException(
                    "Mỗi sản phẩm được đặt tối đa 99 đơn vị.");

            return ketQua;
        }

        public BaoGiaDemo TinhTien(
            List<DongGioGui> dong, string maGiamGia)
        {
            var hopLe = ChuanHoa(dong);
            var q = new BaoGiaDemo();

            foreach (var d in hopLe)
                q.Dong.Add(LaySanPham(d.Id, d.Quantity));

            q.TamTinh = q.Dong.Sum(x => x.ThanhTien);
            q.PhiVanChuyen = 0m;

            string ma = (maGiamGia ?? "").Trim().ToUpperInvariant();

            if (ma.Length > 30)
                throw new InvalidOperationException(
                    "Mã giảm giá tối đa 30 ký tự.");

            if (ma != "")
            {
                var uuDai = DanhSachMa().FirstOrDefault(x => x.Ma == ma);

                if (uuDai == null)
                    throw new InvalidOperationException(
                        "Mã giảm giá không tồn tại.");

                if (q.TamTinh < uuDai.DonToiThieu)
                    throw new InvalidOperationException(
                        "Mã " + ma + " áp dụng cho đơn từ " +
                        uuDai.DonToiThieu.ToString("N0") + "đ.");

                decimal giam = uuDai.SoTien;

                if (uuDai.PhanTram > 0)
                {
                    giam = decimal.Round(
                        q.TamTinh * uuDai.PhanTram / 100m,
                        0, MidpointRounding.AwayFromZero);

                    if (uuDai.GiamToiDa > 0)
                        giam = Math.Min(giam, uuDai.GiamToiDa);
                }

                q.GiamGia = Math.Min(giam, q.TamTinh);
                q.MaGiamGia = ma;
            }

            return q;
        }

        public PhienDatHangDemo TaoPhien(List<DongGioGui> dong)
        {
            var hopLe = ChuanHoa(dong);
            var baoGia = TinhTien(hopLe, null);
            var ds = DocPhien();

            var hetHan = ds.Where(x => x.Value.HetHanUtc <= DateTime.UtcNow)
                .Select(x => x.Key).ToList();

            foreach (var key in hetHan)
                ds.Remove(key);

            if (ds.Count >= 10)
                throw new InvalidOperationException(
                    "Bạn đang mở quá nhiều phiên đặt hàng.");

            var phien = new PhienDatHangDemo
            {
                Token = Guid.NewGuid(),
                HetHanUtc = DateTime.UtcNow.AddMinutes(30),
                Dong = hopLe,
                BaoGia = baoGia
            };

            ds.Add(phien.Token, phien);
            session[PhienKey] = ds;

            return phien;
        }

        public PhienDatHangDemo LayPhien(Guid token)
        {
            var ds = DocPhien();
            PhienDatHangDemo phien;

            if (!ds.TryGetValue(token, out phien))
                return null;

            if (phien.HetHanUtc <= DateTime.UtcNow)
            {
                ds.Remove(token);
                session[PhienKey] = ds;
                return null;
            }

            return phien;
        }

        public void CapNhatBaoGia(
            PhienDatHangDemo phien, BaoGiaDemo baoGia)
        {
            phien.BaoGia = baoGia;

            var ds = DocPhien();
            ds[phien.Token] = phien;
            session[PhienKey] = ds;
        }

        public List<DonHangDemo> LichSu()
        {
            return DocDon().OrderByDescending(x => x.NgayDatUtc).ToList();
        }

        public DonHangDemo ChiTiet(Guid id)
        {
            return DocDon().FirstOrDefault(x => x.Id == id);
        }

        public DonHangDemo TimTheoToken(Guid token)
        {
            return DocDon().FirstOrDefault(x => x.Token == token);
        }

        private bool CungBaoGia(BaoGiaDemo cu, BaoGiaDemo moi)
        {
            if (cu == null || cu.Dong == null ||
                cu.MaGiamGia != moi.MaGiamGia ||
                cu.TamTinh != moi.TamTinh ||
                cu.GiamGia != moi.GiamGia ||
                cu.PhiVanChuyen != moi.PhiVanChuyen ||
                cu.Dong.Count != moi.Dong.Count)
                return false;

            return cu.Dong.All(a => moi.Dong.Any(b =>
                a.Ma == b.Ma &&
                a.Ten == b.Ten &&
                a.Gia == b.Gia &&
                a.SoLuong == b.SoLuong));
        }

        public DonHangDemo DatHang(
            PhienDatHangDemo phien, ThanhToanDemoVM input)
        {
            var daCo = TimTheoToken(input.Token);

            if (daCo != null)
                return daCo;

            if (phien == null || phien.Token != input.Token ||
                phien.HetHanUtc <= DateTime.UtcNow)
                throw new InvalidOperationException(
                    "Phiên đặt hàng hết hạn.");

            var moi = TinhTien(phien.Dong, input.MaGiamGia);

            if (!CungBaoGia(phien.BaoGia, moi))
            {
                CapNhatBaoGia(phien, moi);

                throw new InvalidOperationException(
                    "Giá hoặc ưu đãi đã thay đổi. Hãy kiểm tra tổng tiền " +
                    "và nhấn xác nhận đặt hàng lại.");
            }

            var don = new DonHangDemo
            {
                Id = Guid.NewGuid(),
                Token = phien.Token,
                NgayDatUtc = DateTime.UtcNow,
                HoTen = input.HoTen.Trim(),
                DienThoai = input.DienThoai.Trim(),
                DiaChi = input.DiaChi.Trim(),
                TrangThai = "Chờ xác nhận",
                BaoGia = moi
            };

            // SQL-4: Thay bằng lưu đơn và chi tiết đơn trong transaction.
            // Khi có tồn kho/lượt dùng mã, cập nhật trong cùng transaction.
            var danhSachDon = DocDon();
            danhSachDon.Add(don);
            session[DonKey] = danhSachDon;

            var danhSachPhien = DocPhien();
            danhSachPhien.Remove(phien.Token);
            session[PhienKey] = danhSachPhien;

            return don;
        }
    }
}
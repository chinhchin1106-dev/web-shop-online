using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Soppe.Models
{
    [Serializable]
    public class DongGioGui
    {
        public int Id { get; set; }
        public int Quantity { get; set; }
    }

    [Serializable]
    public class ChiTietDonDemo
    {
        public int Ma { get; set; }
        public string Ten { get; set; }
        public decimal Gia { get; set; }
        public int SoLuong { get; set; }

        public decimal ThanhTien
        {
            get { return Gia * SoLuong; }
        }
    }

    [Serializable]
    public class BaoGiaDemo
    {
        public BaoGiaDemo()
        {
            Dong = new List<ChiTietDonDemo>();
            MaGiamGia = "";
        }

        public List<ChiTietDonDemo> Dong { get; set; }
        public string MaGiamGia { get; set; }
        public decimal TamTinh { get; set; }
        public decimal GiamGia { get; set; }
        public decimal PhiVanChuyen { get; set; }

        public decimal TongTien
        {
            get { return TamTinh - GiamGia + PhiVanChuyen; }
        }
    }

    [Serializable]
    public class PhienDatHangDemo
    {
        public Guid Token { get; set; }
        public DateTime HetHanUtc { get; set; }
        public List<DongGioGui> Dong { get; set; }
        public BaoGiaDemo BaoGia { get; set; }
    }

    [Serializable]
    public class DonHangDemo
    {
        public Guid Id { get; set; }
        public Guid Token { get; set; }
        public DateTime NgayDatUtc { get; set; }

        public string HoTen { get; set; }
        public string DienThoai { get; set; }
        public string DiaChi { get; set; }
        public string TrangThai { get; set; }

        public BaoGiaDemo BaoGia { get; set; }
    }

    [Serializable]
    public class MaGiamGiaDemo
    {
        public string Ma { get; set; }
        public string MoTa { get; set; }
        public decimal DonToiThieu { get; set; }
        public decimal PhanTram { get; set; }
        public decimal SoTien { get; set; }
        public decimal GiamToiDa { get; set; }
    }

    public class ThanhToanDemoVM
    {
        public Guid Token { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập họ tên.")]
        [StringLength(100, ErrorMessage = "Họ tên tối đa 100 ký tự.")]
        public string HoTen { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập số điện thoại.")]
        [RegularExpression(
            @"^0[0-9]{9}$",
            ErrorMessage = "Số điện thoại gồm 10 chữ số, bắt đầu bằng 0.")]
        public string DienThoai { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập địa chỉ.")]
        [StringLength(300, ErrorMessage = "Địa chỉ tối đa 300 ký tự.")]
        public string DiaChi { get; set; }

        [StringLength(30, ErrorMessage = "Mã giảm giá tối đa 30 ký tự.")]
        public string MaGiamGia { get; set; }

        public BaoGiaDemo BaoGia { get; set; }
    }
}
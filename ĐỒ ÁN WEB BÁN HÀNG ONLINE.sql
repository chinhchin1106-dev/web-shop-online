USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'WebBanHangOnline_N6')
BEGIN
    ALTER DATABASE WebBanHangOnline_N6 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE WebBanHangOnline_N6;
    PRINT 'Existing WebBanHangOnline_N6 database has been dropped.';
END
GO

-- Giải thích code IDENTITY(1,1) : 
--là một thuộc tính  
--dùng để tự động tạo số thứ tự tăng dần cho một cột (thường dùng làm Khóa chính - Primary Key).
--Cấu trúc cú pháp IDENTITY(seed, increment) :
--Seed : giá trị bắt đầu (n)
--Increment : Bước nhảy (n + k)
--IDENTITY(1,1): hàng đầu tiên được tạo cột dùng IDENTITY có giá trị là 1 
--               hàng thứ 2 đc tạo cột dùng IDENTITY có giá trị là 2 = 1 + 1(vì bước nhảy là 1) 
--Giải thích code CASCADE (Có trong CHAP2 CSDL gần slide cuối nhưng ko giải thích) : 
--là một tùy chọn đi kèm với ràng buộc Khóa ngoại (FOREIGN KEY).
--Có 2 dạng CASCADE chính thường dùng:
--ON DELETE CASCADE 
--Tác dụng:Khi DELETE một dòng ở Bảng Cha, 
--SQL Server sẽ tự động xóa sạch tất cả các dòng ở Bảng Con có liên kết tới dòng vừa bị xóa.
-- ON UPDATE CASCADE 
-- Tác dụng :Khi  UPDATE giá trị Khóa chính ở Bảng Cha, 
-- SQL Server sẽ tự động cập nhật giá trị Khóa ngoại ở các dòng tương ứng thuộc Bảng Con để giữ đúng mối liên kết.

CREATE DATABASE WebBanHangOnline_N6;
GO

USE WebBanHangOnline_N6;
GO 
--- BẢNG DANH MỤC (LOẠI SẢN PHẨM)
CREATE TABLE DanhMuc (
    MaDM SMALLINT IDENTITY(1,1),
    TenDM NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_DanhMuc PRIMARY KEY (MaDM), -- Khoá chính
);
GO

--- BẢNG SẢN PHẨM 
CREATE TABLE SanPham (
    MaSP INT IDENTITY(1,1),
    TenSP NVARCHAR(200) NOT NULL,
    HinhAnh VARCHAR(255),
    GiaBan DECIMAL(12,2) NOT NULL DEFAULT 0,
    MoTa NVARCHAR(Max),
    SLTonKho INT NOT NULL DEFAULT 0,
    MaDM SMALLINT NOT NULL,
    
    -- Ràng buộc: Giá bán và tồn kho không được âm
    CONSTRAINT CHK_GiaBan CHECK (GiaBan >= 0), -- kiểm tra giá bán ko âm
    CONSTRAINT CHK_SoLuongTonKho CHECK (SLTonKho >= 0), -- kiểm tra số lượng tồn kho ko âm
    CONSTRAINT PK_SanPham PRIMARY KEY (MaSP),  -- Khoá chính
    CONSTRAINT FK_SanPham_MaDM_DM  FOREIGN KEY (MaDM) REFERENCES DanhMuc(MaDM), -- khoá ngoại
);
GO
--- BẢNG KHÁCH HÀNG
CREATE TABLE KhachHang
(
  MaKH INT IDENTITY(1,1) PRIMARY KEY,
  HoTen NVARCHAR(30) NOT NULL,        -- Thông tin cá nhân
  ĐiaChi NVARCHAR(255),               -- Thông tin cá nhân
  SĐT VARCHAR(15),                    -- Thông tin cá nhân
  Email VARCHAR(100) UNIQUE,                 -- Tài khoản
  MatKhauTK  CHAR(60) NOT NULL,              -- Tài khoản
  PhanQuyen VARCHAR(20) DEFAULT 'Customer'
);
GO
--- BẢNG GIỎ HÀNG
CREATE TABLE GioHang
(
MaGH INT IDENTITY(1,1),
MaKH INT UNIQUE NOT NULL, -- Ràng buộc UNIQUE đảm bảo mỗi khách chỉ có 1 giỏ
NgayTao DATETIME DEFAULT GETDATE(),
CONSTRAINT PK_GioHang PRIMARY KEY (MaGH),  -- Khoá chính
 CONSTRAINT FK_GioHang_MaKH_KH  FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH), -- khoá ngoại
)
    GO
--- BẢNG CHI TIẾT GIỎ HÀNG
CREATE TABLE ChiTietGioHang (
    MaGH INT NOT NULL,
    MaSP INT NOT NULL,
    SoLuong SMALLINT NOT NULL ,
    
    CONSTRAINT PK_ChiTietGioHang_MaGH_MaSP PRIMARY KEY (MaGH, MaSP),
    CONSTRAINT FK_ChiTietGioHang_MaGH_GH FOREIGN KEY (MaGH) REFERENCES GioHang(MaGH) ON DELETE CASCADE, -- khoá ngoại + tự xoá nếu bảng cha xoá
    CONSTRAINT FK_ChiTietGioHang_MaSP_SP FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP),
    CONSTRAINT CHK_SoLuongMua_GH CHECK (SoLuong > 0)
);
GO
--- BẢNG ĐƠN HÀNG
CREATE TABLE DonHang
(
    MaDH INT IDENTITY(1,1),
    MaKH INT NOT NULL,
    TrangThai NVARCHAR(10) DEFAULT N'Chờ xác nhận',
    NgayDat DATETIME DEFAULT GETDATE(),
    TongTienTT DECIMAL(12, 2) NOT NULL DEFAULT 0,
    CONSTRAINT PK_DonHang PRIMARY KEY (MaDH),  -- Khoá chính
    CONSTRAINT FK_DonHang_MaKH_KH  FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH), -- khoá ngoại
    CONSTRAINT CHK_TrangThai CHECK ( TrangThai IN ( N'Chờ xác nhận', 
                                                    N'Đã xác nhận', 
                                                    N'Đang xử lý', 
                                                    N'Đã giao', 
                                                    N'Hoàn thành', 
                                                    N'Đã hủy'
                                                   )
                                     )
)
GO
--- BẢNG CHI TIẾT ĐƠN HÀNG
CREATE TABLE ChiTietDonHang (
    MaDH INT NOT NULL,
    MaSP INT NOT NULL,
    SoLuong SMALLINT NOT NULL,
    DonGia DECIMAL(18,2) NOT NULL, -- đơn giá tại thời điểm mua
    
    CONSTRAINT PK_ChiTietDonHang_MaDH_MaSP PRIMARY KEY (MaDH, MaSP), -- Khoá chính
    CONSTRAINT FK_ChiTietDonHang_MaDH_DH  FOREIGN KEY (MaDH) REFERENCES DonHang(MaDH) ON DELETE CASCADE, -- khoá ngoại + tự xoá nếu bảng cha xoá
    CONSTRAINT FK_ChiTietDonHang_MaSP_SP FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP), -- khoá ngoại
    CONSTRAINT CHK_SoLuong_DH CHECK (SoLuong > 0)
);
GO
INSERT INTO DanhMuc (TenDM) VALUES
 ( N'Thời trang'),
 ( N'Công nghệ'),
 ( N'Đồ gia dụng'),
 ( N'Làm đẹp');

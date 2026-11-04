
USE master;
GO

-- KIỂM TRA DATABASE CÓ TỒN TẠI KHÔNG
IF DB_ID(N'WebBanHangOnline_N6') IS NULL
BEGIN
    PRINT N'LỖI: Database WebBanHangOnline_N6 không tồn tại!';
    RETURN;
END
ELSE
BEGIN
    PRINT N'THÀNH CÔNG: Database đã tồn tại!';
END
GO

USE WebBanHangOnline_N6;
GO

PRINT N'========== 1. KIỂM TRA TÊN DATABASE ==========';
SELECT
    DB_NAME() AS TenDatabase,
    GETDATE() AS ThoiGianKiemTra;
GO

PRINT N'========== 2. KIỂM TRA CÁC BẢNG ==========';
-- Danh sách các bảng cần có
DECLARE @DanhSachBang TABLE
(
    TenBang NVARCHAR(100)
);

INSERT INTO @DanhSachBang VALUES
(N'DanhMuc'),
(N'SanPham'),
(N'KhachHang'),
(N'GioHang'),
(N'ChiTietGioHang'),
(N'DonHang'),
(N'ChiTietDonHang'),
(N'ThongBao'),
(N'LuotXemSP'),
(N'TinNhan');

SELECT
    DS.TenBang,
    CASE
        WHEN T.name IS NOT NULL THEN N'Đã tồn tại'
        ELSE N'Chưa tồn tại'
    END AS TrangThai
FROM @DanhSachBang DS
LEFT JOIN sys.tables T
    ON DS.TenBang = T.name;

-- Đếm tổng số bảng
SELECT COUNT(*) AS TongSoBang
FROM sys.tables;
GO

PRINT N'========== 3. KIỂM TRA SỐ LƯỢNG DỮ LIỆU ==========';
SELECT N'DanhMuc' AS TenBang, COUNT(*) AS SoLuong FROM DanhMuc
UNION ALL
SELECT N'SanPham', COUNT(*) FROM SanPham
UNION ALL
SELECT N'KhachHang', COUNT(*) FROM KhachHang
UNION ALL
SELECT N'GioHang', COUNT(*) FROM GioHang
UNION ALL
SELECT N'ChiTietGioHang', COUNT(*) FROM ChiTietGioHang
UNION ALL
SELECT N'DonHang', COUNT(*) FROM DonHang
UNION ALL
SELECT N'ChiTietDonHang', COUNT(*) FROM ChiTietDonHang
UNION ALL
SELECT N'ThongBao', COUNT(*) FROM ThongBao
UNION ALL
SELECT N'LuotXemSP', COUNT(*) FROM LuotXemSP
UNION ALL
SELECT N'TinNhan', COUNT(*) FROM TinNhan;
GO

PRINT N'========== 4. KIỂM TRA DANH MỤC VÀ SẢN PHẨM ==========';
SELECT
    DM.MaDM,
    DM.TenDM,
    COUNT(SP.MaSP) AS SoLuongSanPham
FROM DanhMuc DM
LEFT JOIN SanPham SP
    ON DM.MaDM = SP.MaDM
GROUP BY DM.MaDM, DM.TenDM;
GO

PRINT N'========== 5. KIỂM TRA KHÓA NGOẠI VÀ RÀNG BUỘC ==========';
DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;
GO

PRINT N'========== 6. KIỂM TRA TÍNH TOÀN VẸN DATABASE ==========';
DBCC CHECKDB (N'WebBanHangOnline_N6')
WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO

PRINT N'========== HOÀN TẤT KIỂM TRA DATABASE ==========';

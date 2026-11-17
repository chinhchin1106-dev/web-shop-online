

USE WebBanHangOnline_N6;
GO
--=====================================================
-- TRUY VẤN CHO SẢN PHẨM NỔI BẬT
--===================================================

--- THÊM KHÁCH HÀNG ĐỂ TEST (Lưu ý test hết truy vấn r mới xoá):
INSERT INTO KhachHang(HoTen,Email,MatKhauTK)
VALUES(N'Nguyễn Văn A','NgVanA@gmail.com','123456'),
        (N'Khách B','B@gmail.com','987654'),
        (N'Khách C','C @gmail.com','123098')
GO
-- Kiểm tra dữ liệu đã thêm vào ?
SELECT * FROM KhachHang
GO
 -- THÊM LƯỢT XEM ĐỂ TEST
INSERT INTO LuotXemSP (MaSP, MaKH)
VALUES (3,2), (3,2),(3,3),(2,3), (4,2), (1,2),(1,2), (1,3)
GO

-- Kiểm tra xem xoá đc chưa
SELECT * FROM LuotXemSP
GO
--======================================
-- CHỨC NĂNG: LẤY RA TỐI ĐA 4 SẢN PHẨM NỔI BẬT (có thể tự điều chỉnh lại số lượng lấy ra) 
-- Tiêu chí: Số khách hàng khác nhau đã xem sản phẩm
-- Mỗi khách (đã đăng ký tài khoản) chỉ được tính một lần cho mỗi sản phẩm
--==================================

SELECT TOP (4) -- hiển thị tối đa 4 sp, có thể tự đổi lại số lượng hiển thị tối đa nếu muốn
    SP.MaSP,
    SP.TenSP,
    SP.GiaBan,
    SP.HinhAnh,
    COUNT(DISTINCT LX.MaKH) AS SoKhachHangDaXem -- đếm số lượng khách hàng khác nhau đã xem sp
FROM SanPham AS SP
INNER JOIN LuotXemSP AS LX
    ON LX.MaSP = SP.MaSP
WHERE LX.MaKH IS NOT NULL     -- Chỉ tính khách có tài khoản
GROUP BY                      -- Nhóm sp lại để ko hiển thị 1 sp 2lần 
    SP.MaSP,
    SP.TenSP,
    SP.GiaBan,
    SP.HinhAnh
ORDER BY
    SoKhachHangDaXem DESC; -- sắp xếp giảm dần => các giá trị cao nhất luôn ở hàng đầu

GO
--=====================================
-- Chức năng kèm theo :
-- Ghi nhận một lần xem sp của khách (đã đăng nhập hoặc chưa đều đc) 
  ---------------KHAI BÁO ĐỂ TEST chức năng KÈM THEO -------- 
DECLARE   @MaKH INT = 1,  -- Khai báo biến
          @MaSP INT = 3
--------------- 
INSERT INTO LuotXemSP  (MaSP, MaKH)
VALUES (@MaSP, @MaKH);
    GO

--======================================

--===================================
-- CHỨC NĂNG: LẤY RA TỐI ĐA 4 SẢN PHẨM ĐỂ ĐỀ XUẤT CHO 1 KHÁCH HÀNG CỤ THỂ NÀO ĐÓ 
-- Tiêu chí: Số lần chính khách hàng đó xem từng sản phẩm (đã đăng ký tài khoản và đăng nhập r mới xem đc)
--====================================
 -- THÊM LƯỢT XEM ĐỂ TEST
INSERT INTO LuotXemSP (MaSP, MaKH)
VALUES (3, 1), (3,1),(3,1),(2,1), (4,1)
GO

 ---------------KHAI BÁO ĐỂ TEST  -------- 
DECLARE   @MaKH INT = 1  -- Khai báo biến
--------------- 

SELECT TOP (4)    -- lấy tối đa 4 sp 
    SP.MaSP,
    SP.TenSP,
    SP.Giaban,
    SP.HinhAnh,
    COUNT(*) AS SoLanKhachXem,
    MAX(LX.ThoiGianXem) AS LanXemGanNhat
FROM LuotXemSP AS LX
INNER JOIN SanPham AS SP
    ON SP.MaSP = LX.MaSP
WHERE LX.MaKH = @MaKH       -- Truyền MaKH từ java vào với khách có tài khoản mới hiện đề xuất
GROUP BY
    SP.MaSP,
    SP.TenSP,
    SP.GiaBan,
    SP.HinhAnh
ORDER BY
    SoLanKhachXem DESC, -- sắp xếp theo số lượt xem
    LanXemGanNhat DESC; -- sắp xếp theo thời gian xem gần đây nhất 
                        -- tránh thời gian xem sp đó đã quá lâu về trước mà vẫn đc hiển thị dù hiện tại ko hề xem nữa
GO

--======================================
-- SQL CHO YÊU THÍCH SẢN PHẨM
--=====================================

--====================================
-- CHỨC NĂNG LƯU LẠI SẢN PHẨM YÊU THÍCH CỦA 1 KHÁCH HÀNG CỤ THỂ 
-- Khai báo biến đầu vào (Mô phỏng khách có MaKH = 1 bấm thích sản phẩm MaSP = 5)
DECLARE @MaKH INT = 1,
        @MaSP INT = 5;

    INSERT INTO SPYeuThich (MaKH, MaSP)
    VALUES (@MaKH, @MaSP);
GO
-- Kiểm tra dữ liệu thêm vào ?
SELECT * FROM SPYeuThich
GO
--==========================================
-- CHỨC NĂNG XOÁ SẢN PHẨM YÊU THÍCH CỦA 1 KHÁCH HÀNG CỤ THỂ.
-- Khai báo biến đầu vào
DECLARE @MaKH INT = 1;
DECLARE @MaSP INT = 5;

-- Câu lệnh xóa sản phẩm khỏi danh sách yêu thích của khách
DELETE FROM SPYeuThich
WHERE MaKH = @MaKH AND MaSP = @MaSP;
GO

--============================================
-- CHỨC NĂNG XEM DANH SÁCH CÁC SẢN PHẨM YÊU THÍCH CỦA 1 KHÁCH HÀNG CỤ THỂ

-- Thêm sản phẩm yêu thích khác cho khách hàng có MakH = 1
    INSERT INTO SPYeuThich (MaKH, MaSP)
    VALUES (1,2), (1,7);

-- Khai báo biến Mã khách hàng khách hàng đang đăng nhập
DECLARE @MaKH INT = 1;
-- Câu truy vấn lấy danh sách sản phẩm yêu thích
SELECT 
    sp.MaSP,
    sp.TenSP,
    sp.HinhAnh,
    sp.GiaBan,
    sp.SLTonKho,
    yt.NgayThem
FROM SPYeuThich yt
JOIN SanPham sp ON yt.MaSP = sp.MaSP
WHERE yt.MaKH = @MaKH
ORDER BY yt.NgayThem DESC; -- Sản phẩm vừa thích sẽ hiển thị lên đầu tiên
GO

--================= KHÔI PHỤC LẠI DỮ LIỆU SAU KHI TEST
-- XOÁ SẢN PHẨM YÊU THÍCH CỦA TẤT CẢ KHÁCH HÀNG & RESET IDENTITY SAU KHI TEST
DELETE SPYeuThich WHERE MaKH IN (SELECT MaKH FROM KhachHang)
GO
DBCC CHECKIDENT ('SPYeuThich', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM SPYeuThich
GO

-- XOÁ LƯỢT XEM & RESET IDENTITY SAU KHI TEST
DELETE LuotXemSP WHERE MaKH IN (SELECT MaKH FROM KhachHang)
GO
DBCC CHECKIDENT ('LuotXemSP', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM LuotXemSP
GO
--- XOÁ KHÁCH HÀNG TẤT CẢ KHÁCH HÀNG ĐÃ THÊM Ở TRÊN
DELETE KhachHang WHERE MaKH IN (SELECT MaKH FROM KhachHang)
GO
--- RESET LẠI IDENTITY CỦA KHÁCH SAU KHI XOÁ KHÁCH MẪU
 DBCC CHECKIDENT ('KhachHang', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM KhachHang
GO
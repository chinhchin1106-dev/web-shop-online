USE master;
GO
---------------- CHỈ XOÁ NẾU CSDL BỊ LỖI--------------------------
/*
    IF EXISTS (SELECT name FROM sys.databases WHERE name = 'WebBanHangOnline_N6')
BEGIN
    ALTER DATABASE WebBanHangOnline_N6 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE WebBanHangOnline_N6;
    PRINT 'Existing WebBanHangOnline_N6 database has been dropped.';
END
GO
*/
------------------------------------------------

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
    HinhAnh VARCHAR(500),
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
  DiaChi NVARCHAR(255),               -- Thông tin cá nhân
  SDT VARCHAR(15),                    -- Thông tin cá nhân
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
);
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
    TrangThai NVARCHAR(30) DEFAULT N'Chờ xác nhận',
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
    DonGia DECIMAL(12,2) NOT NULL, -- đơn giá tại thời điểm mua
    
    CONSTRAINT PK_ChiTietDonHang_MaDH_MaSP PRIMARY KEY (MaDH, MaSP), -- Khoá chính
    CONSTRAINT FK_ChiTietDonHang_MaDH_DH  FOREIGN KEY (MaDH) REFERENCES DonHang(MaDH) ON DELETE CASCADE, -- khoá ngoại + tự xoá nếu bảng cha xoá
    CONSTRAINT FK_ChiTietDonHang_MaSP_SP FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP), -- khoá ngoại
    CONSTRAINT CHK_SoLuong_DH CHECK (SoLuong > 0)
);
GO

--================ Thêm bảng mới phát sinh theo yêu cầu của nhóm ===================
-- TẠO THÊM BẢNG THÔNG BÁO
CREATE TABLE ThongBao(
MaTB INT IDENTITY(1,1),
MaKH INT NOT NULL,
TieuDe NVARCHAR(200) NOT NULL,
NoiDung NVARCHAR(1000) NOT NULL,
LoaiTB NVARCHAR(30) NOT NULL,
MaDH INT NULL,
NgayTao DATETIME2 NOT NULL
    CONSTRAINT DF_ThongBao_NgayTao DEFAULT GETDATE(),
DaDoc BIT NOT NULL   -- 0 là chưa đọc 1 là đọc rồi
    CONSTRAINT DF_ThongBao_DaDoc DEFAULT 0
    CONSTRAINT CK_ThongBao_DaDoc CHECK(DaDoc IN(0,1)),
CONSTRAINT PK_ThongBao PRIMARY KEY (MaTB),  -- Khoá chính
CONSTRAINT FK_ThongBao_KhachHang  FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH), -- khoá ngoại 
CONSTRAINT FK_ThongBao_DonHang  FOREIGN KEY (MaDH) REFERENCES DonHang(MaDH) -- khoá ngoại 
)
GO
-- TẠO THÊM BẢNG LƯỢT XEM SẢN PHẨM 
 CREATE TABLE LuotXemSP (
 MaLX BIGINT IDENTITY(1,1) ,
 MaSP INT NOT NULL,
 MaKH INT NULL,
 ThoiGianXem DATETIME NOT NULL 
 CONSTRAINT DF_LuotXemSanPham DEFAULT  GETDATE(),
 CONSTRAINT FK_LuotXemSanPham_SanPham FOREIGN KEY (MaSP) REFERENCES SanPham(MaSP),
 CONSTRAINT FK_LuotXemSanPham_KhachHang FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH),
 CONSTRAINT PK_LuotXemSanPham PRIMARY KEY (MaLX)
)
GO

-- =================THÊM DỮ LIỆU DANH MỤC=================
INSERT INTO DanhMuc (TenDM) VALUES
 ( N'Thời trang'),
 ( N'Công nghệ'),
 ( N'Đồ gia dụng'),
 ( N'Làm đẹp');
 GO

    
 -- ====================THÊM DỮ LIỆU SẢN PHẨM =====================

 -- THÊM DỮ LIỆU SẢN PHẨM TRONG DANH MỤC THỜI TRANG MaDM 1
 INSERT INTO SanPham   (TenSP, HinhAnh, GiaBan, MoTa, SLTonKho, MaDM) VALUES
 -- SanPham 1
 (N'ÁO HOODIE 2 MÀU - HÌNH MÈO CÓ TÚI ', N'https://res.cloudinary.com/jw935dos/image/upload/v1791277387/%E1%BA%A2nh_ch%E1%BB%A5p_m%C3%A0n_h%C3%ACnh_2026-10-06_160235.png', 100000,
 N'THÔNG TIN SẢN PHẨM
    •	Xuất xứ: Việt Nam
    •	Chất liệu: Vải nỉ
    •	Gửi từ: Tỉnh Tây Ninh
    HƯỚNG DẪN CHỌN SIZE
    •	Size S: Từ 30kg – 40kg
    •	Size M: Từ 40kg – 55kg
    Cam kết & Lưu ý:
    •	Sản phẩm thực tế đảm bảo chuẩn kiểu dáng và màu sắc như hình ảnh.
    •	Màu sắc thực tế có thể chênh lệch không đáng kể do độ phân giải và ánh sáng hiển thị của từng màn hình
    ĐIỂM NỔI BẬT CỦA SẢN PHẨM:
    •	Chất liệu nỉ cao cấp: Giữ nhiệt vượt trội, chắn gió tốt và đặc biệt ít nhăn, giúp bạn luôn chỉn chu suốt cả ngày.
    •	Thích hợp mùa Thu - Đông: Mang lại cảm giác ấm áp, dễ chịu trong những ngày se lạnh.
    •	Kiểu dáng tối giản & Linh hoạt: Thiết kế đơn giản, trẻ trung, không lỗi mốt và phù hợp với nhiều lứa tuổi.
    GỢI Ý PHỐI ĐỒ 
    •	Lịch sự đi làm, đi chơi: Kết hợp cùng quần jeans dài hoặc quần âu.
    •	Thoải mái dạo phố, du lịch: Phối cùng quần short đơn giản, năng động.
    ', 300, 1),
    -- SanPham 2
    ( N'Quần dài kaki jogger nam LADOS-4160', N'https://res.cloudinary.com/jw935dos/image/upload/v1791277936/%E1%BA%A2nh_ch%E1%BB%A5p_m%C3%A0n_h%C3%ACnh_2026-10-04_105637.png', 300000, 
    N'THÔNG TIN SẢN PHẨM:
    •	Chất liệu: Kaki nhập khẩu cao cấp
    •	Sản xuất & bảo hành : Công ty TNHH MTV LADOS 
    •	Thương hiệu : LADOS
    •	Xuất xứ: Việt Nam
    •	Gửi từ: Thành phố Hồ Chí Minh
    CHÍNH SÁCH.
    •	Cam kết chất lượng và mẫu mã sản phẩm giống với hình ảnh.
    •	Hoàn tiền nếu sản phẩm không giống với mô tả.
    ĐIỂM NỔI BẬT CỦA SẢN PHẨM:
    •	Chất vải cao cấp, mềm mịn, mặc vào cực kì thoải mái
    •	Không ra màu, không xù lông,thấm hút mồ hôi
    •	Form suông , tôn dáng, mặc trẻ trung
    •	Đường may cực tỉ mỉ cực đẹp
    •	Có thể mặc đi làm, đi chơi, dễ phối đồ, không kén người mặc
    HƯỚNG DẪN CHỌN SIZE
    •	Size S: 45 – 53 kg
    •	Size M: 53 – 57 kg
    •	Size L: 57 – 65 kg
    •	Size XL: 65 – 75 kg
    •	Size XXL: 75 – 80 kg 
    ', 50, 1),
 -- SanPham 3
    (N'Giày nhựa Duwa', N'https://res.cloudinary.com/jw935dos/image/upload/v1791277946/%E1%BA%A2nh_ch%E1%BB%A5p_m%C3%A0n_h%C3%ACnh_2026-10-04_112420.png', 70000,
    N'THÔNG TIN SẢN PHẨM:
•	Chất liệu: Nhựa dẻo EVA (Ethylene Vinyl Acetate) 
•	Thương hiệu : Duwa
•	Xuất xứ: Việt Nam
•	Gửi từ: Thành phố Hồ Chí Minh
SIZE : từ 35 đến 42
MÔ TẢ SẢN PHẨM : 
•	Thiết kế : kiểu cổ điển, thân trong có vân nhẹ tăng độ bám , mũi giày bo tròn.
•	Đế được làm từ nhựa với độ dầy (~2cm) chịu được trọng lượng người mang trong thời gian dài mà không bị xẹp
ĐIỂM NỔI BẬT CỦA SẢN PHẨM :
•	Kiểu dáng hợp thời trang, năng động, trẻ trung, dễ phối đồ, phù hợp cho cả nam và nữ
•	Đế nhựa chống trơn trượt, dễ vệ sinh
HƯỚNG DẪN SỬ DỤNG VÀ BẢO QUẢN
•	Bảo quản nơi khô ráo tránh ánh nắng trực tiếp để giữ sản phẩm được độ bền cao
•	Không sử dụng hóa chất mạnh cho sản phẩm
', 80, 1),
-- SanPham 4
(N'Áo Thun Trơn – Trắng', 'https://res.cloudinary.com/jw935dos/image/upload/v1791277960/%E1%BA%A2nh_ch%E1%BB%A5p_m%C3%A0n_h%C3%ACnh_2026-10-04_114241.png', 60000, 
N'THÔNG TIN SẢN PHẨM:
•	Chất liệu: Vải Poly
•	Kiểu dáng: Cổ tròn
•	Tay áo: Tay ngắn
•	Form: Regular Fit
•	Màu sắc: Trắng 
•	Size: S, M, L, XL, 2XL, 3XL
•	Xuất xứ: Việt Nam
•	Gửi từ: Thành phố Hồ Chí Minh

ĐIỂM NỔI BẬT CỦA SẢN PHẨM :
•	Chất vải Poly mềm, nhẹ, nhanh khô.
•	Ít nhăn, không cần ủi nhiều.
•	Đường may chắc chắn, mặc hằng ngày bền đẹp.
•	Phù hợp đi học, đi làm, đi chơi hoặc mặc ở nhà.

HƯỚNG DẪN CHỌN SIZE
•	Size S: 45 kg ( chiều cao 1m5 – 1m65)
•	Size M: 45 kg – 50 kg 
•	Size L:  50 kg – 55 kg 
•	Size XL: 55 kg – 65 kg 
•	Size 2XL: 70 – 75 kg
•	Size 3XL: 80 – 90 kg

Cam kết
Hàng mới 100%.
Kiểm tra kỹ trước khi giao.
Hỗ trợ đổi trả nếu sản phẩm lỗi từ nhà sản xuất.

', 120, 1);

GO

-- THÊM DỮ LIỆU SẢN PHẨM TRONG DANH MỤC ĐỒ GIA DỤNG  MaDM 3
 INSERT INTO SanPham   (TenSP, HinhAnh, GiaBan, MoTa, SLTonKho, MaDM) VALUES
 -- SanPham 1
 (N'Dụng cụ gắp đĩa, chén bát, nồi chống nóng bằng thép không gỉ cao cấp','https://res.cloudinary.com/jw935dos/image/upload/v1792162107/%E1%BA%A2nh_ch%E1%BB%A5p_m%C3%A0n_h%C3%ACnh_2026-10-16_214810.png', 30000,
 N'THÔNG TIN SẢN PHẨM 
• Chất liệu: Thép không gỉ và nhựa 
• Màu sắc: Hồng, xanh lá, xanh dương 
• Trọng lượng: Khoảng 120g 
• Loại sản phẩm: Kẹp gắp bát đĩa 

 CÔNG DỤNG 
• Dùng gắp bát, đĩa, tô chén 
• Dùng khi lấy vật dụng từ nồi hấp hoặc lò vi sóng 
• Dùng trong nhà bếp hàng ngày 
• Phù hợp cho nhiều nhu cầu sử dụng 

 HƯỚNG DẪN SỬ DỤNG & BẢO QUẢN 
• Đặt vật dụng vào giữa phần kẹp trước khi sử dụng 
• Giữ lực tay phù hợp khi thao tác 
• Vệ sinh sau khi sử dụng 
• Bảo quản nơi khô ráo, sạch sẽ	 
'
,150,3),
-- SanPham 2
(N'Ky Hốt Rác','https://res.cloudinary.com/jw935dos/image/upload/v1792162210/%E1%BA%A2nh_ch%E1%BB%A5p_m%C3%A0n_h%C3%ACnh_2026-10-16_214955.png',69000,
N'THÔNG TIN CHI TIẾT 

- Số lượng mỗi gói : 1 cái  
- Chất liệu : cán inox, hốt rác thép mạ kẽm 
- Màu sắc : như hình 
- Kích thước : 30cm x 30cm x 70cm 

TIỆN ÍCH CÔNG NĂNG 
- Ky hốt rác được thiết kế với cán là inox, sáng bóng, chống gỉ sét.  
- Đế hốt được làm bằng thép mã kẽm nên có độ bền cao, hốt dễ dàng, tiện lợi.  
- Đầu cán được làm bằng nhựa có sẵn lỗ treo gọn gàng, ngăn nắp.  
- Sản phẩm khi khách mua về đã được tháo rời có vít sẵn, khách chỉ cần ráp vào vặn thật chắc là có thể sử dụng.  
- Sản phẩm tiện dụng và dễ sử dụng giúp không gian nhà bạn trở nên sạch sẽ và đẹp mắt. 
'
,600,3),
-- SanPham 3
(N'QUẠT CẦM TAY ANRMESUN','https://res.cloudinary.com/jw935dos/image/upload/v1792162689/%E1%BA%A2nh_ch%E1%BB%A5p_m%C3%A0n_h%C3%ACnh_2026-10-16_215756.png',106136,
N'THÔNG TIN CHI TIẾT  
Thương hiệu: ANRMESUN 
Tốc độ gió: 9m/s (Luồng gió mạnh) 
Cài đặt tốc độ: 3 tốc độ gió điều chỉnh 
Thời lượng pin: Lên đến 24 giờ 
Chất liệu: Nhựa ABS thân thiện với môi trường 
Màu sắc: Hồng hoa anh đào / Đen cổ điển / Cà phê sữa / Tím khoai môn 
Ứng dụng phù hợp: Văn phòng, đi làm, ngoài trời, du lịch, nhà cửa, v.v. 

ĐIỂM NỔI BẬT CHÍNH CỦA SẢN PHẨM 
Gió Tuabin Mạnh Mẽ 9m/s: Động cơ hiệu suất cao, thổi bay mệt mỏi chỉ trong nháy mắt, gió mạnh ngay cả ở khoảng cách xa. 
3 Cấp Tốc Độ Gió: Gió nhẹ, gió mạnh, gió bão, phù hợp với văn phòng, đi lại, hoạt động ngoài trời, đáp ứng mọi nhu cầu làm mát. 
Thời Lượng Pin 24 Giờ: Viên pin dung lượng lớn, sạc một lần sử dụng cả ngày, không còn lo hết pin giữa chừng. 
Thiết Kế Nhẹ Nhàng Dễ Mang: Tay cầm học kỹ thuật con người, thân máy nhẹ, dễ bỏ túi hoặc túi xách, mang theo bên mình mọi lúc mọi nơi. 
4 Màu Macaron Đẹp Mắt: Hồng anh đào, đen cổ điển, cà phê sữa, tím khoai lang – vừa là chiến binh giải nhiệt, vừa là món đồ phối đồ thời trang. 
'
,48,3),
-- SanPham 4
(N' Bộ Chảo Chống Dính Cao Cấp Dùng Mọi Loại Bếp Tay Cầm Cách Nhiệt','https://res.cloudinary.com/jw935dos/image/upload/v1792163221/%E1%BA%A2nh_ch%E1%BB%A5p_m%C3%A0n_h%C3%ACnh_2026-10-16_220646.png',59000,
N'THÔNG TIN CHI TIẾT 
Chống Dính Cao Cấp 
Chiên trứng đẹp 
Nấu mì nhanh 
Nấu cháo mịn 
Hâm sữa tiện lợi 
Ít bám thức ăn – Dễ vệ sinh sau khi dùng. 
Truyền Nhiệt Đều 
Nhiệt lan tỏa nhanh và đều giúp món ăn chín ngon hơn. 

✔ Tiết kiệm năng lượng 
✔ Hạn chế cháy khét 
✔ Nấu ăn dễ dàng hơn 
'
,373,3),
-- SanPham 5
(N'Kệ nhựa đa năng nhà tắm nhà vệ sinh','https://res.cloudinary.com/jw935dos/image/upload/v1792163330/Ke-nhua-da-nang.png',43645,
N'THÔNG TIN CHI TIẾT 
- Chất liệu: Nhựa PP nguyên sinh và khung inox 
- Kích thước gồm chân: Cao 52cm. ngang 30cm, phần gía đựng rộng 14cm, cao 16cm. 
- Màu sắc: ghi xám và trắng 
- Trọng lượng: 400g 
- Dán siêu chắc, bền bỉ chịu nước thoái mái 
'
,521,3),
-- SanPham 6
(N'Cọ thép chà nồi tay không rỉ sét đa năng','https://res.cloudinary.com/jw935dos/image/upload/v1792163457/co-thep-da-nang.png',30000,
N'THÔNG TIN CHI TIẾT 
Chất liệu : Sợi thép inox mảnh , mềm dẻo bền bỉ và có độ đàn hồi cực tốt giúp uốn lượn linh hoạt mà không lo bị gãy gập. 
Bảo vệ vật dụng: Làm sạch mạnh mẽ các vết bám bẩn, dầu mỡ cứng đầu nhưng không lo trầy xước hay làm hỏng bề mặt xoong nồi, bát đĩa. 

Đa năng tiện lợi (4 trong 1): Thiết kế cán cầm inox sạch sẽ, chuyên dùng để: 
Chà rửa xoong, nồi, chảo chống dính. 
Rửa bát đĩa, khay nướng. 
Cọ rửa bồn rửa bát (lavabo). 
Vệ sinh mặt bếp ga, bếp từ và các góc khuất dễ dàng. '
,89,3);

GO
-- THÊM DỮ LIỆU SẢN PHẨM TRONG DANH MỤC LÀM ĐẸP  MaDM 4
 INSERT INTO SanPham   (TenSP, HinhAnh, GiaBan, MoTa, SLTonKho, MaDM) VALUES
 -- SanPham 1
 (N'Nước tẩy trang Simple','https://res.cloudinary.com/jw935dos/image/upload/v1792164753/SuaRuaMat-Simple.png',150000,
 N'Thông tin sản phẩm: Giúp loại bỏ đi các vi khuẩn, cặn trang điểm và dầu nhờn trên mặt'
 ,685,4),
 -- SanPham 2
 (N'Serum dưỡng da L’OReal','https://res.cloudinary.com/jw935dos/image/upload/v1792164722/Serum-duong-da.png',350000,
 N'Tinh chất dưỡng da chứa Hyaluronic Acid giúp cấp ẩm sâu, làm mờ nếp nhăn và mang lại làn da căng bóng, mịn màng.'
 ,22,4),
 -- SanPham 3
 (N'Sữa rửa mặt Hada Labo','https://res.cloudinary.com/jw935dos/image/upload/v1792164999/SuaRuaMat-Hada-Labo.png',80000,
 N'Sữa rửa mặt dịu nhẹ với hệ dưỡng ẩm Hyaluronic Acid giúp làm sạch sâu bụi bẩn, bã nhờn mà vẫn giữ cho da mềm mại, không bị khô căng.'
 ,232,4),
 -- SanPham 4
 (N'Toner Centella 1004','https://res.cloudinary.com/jw935dos/image/upload/v1792165113/ToneCentella.png',200000,
 N'Nước hoa hồng chiết xuất từ rau má Madagascar giúp làm dịu da nhạy cảm, cân bằng độ pH và hỗ trợ phục hồi làn da tổn thương.'
 ,13,4);
 
GO
 -- THÊM DỮ LIỆU SẢN PHẨM TRONG DANH MỤC CÔNG NGHỆ  MaDM 2
 INSERT INTO SanPham   (TenSP, HinhAnh, GiaBan, MoTa, SLTonKho, MaDM) VALUES
 -- SanPham 1
 (N'Chuột Corsair Harpoon RGB PRO FPS / MOBA','https://res.cloudinary.com/jw935dos/image/upload/v1792168586/Chuot-coDay.png',656000,
 N'Chuột gaming có dây siêu nhẹ (85g), cảm biến quang học 12.000 DPI, switch Omron độ bền 20 triệu lần nhấn và hệ thống đèn LED RGB tùy chỉnh.',271,2),
  -- SanPham 2
 (N'Đèn Livestream Elgato Key Light Neo','https://res.cloudinary.com/jw935dos/image/upload/v1792168847/Den_LiveStream.png',2049000,
 N'Đèn LED livestream cao cấp thiết kế nhỏ gọn, độ sáng lên đến 1000 lumens, tùy chỉnh nhiệt độ màu 2900K - 7000K và chỉ số tái tạo màu CRI > 94%.',237,2),
  -- SanPham 3
 (N'Bộ Chia HDMI 1 Ra 2 Ugreen 40201 | Xuất 2 Màn Hình Song Song | Chuẩn 4K30Hz','https://res.cloudinary.com/jw935dos/image/upload/v1792168997/BoChia-HDMI-xuatManHinh.png',38000000,
 N'Thiết bị chia tín hiệu HDMI từ 1 nguồn ra 2 màn hình hiển thị song song, hỗ trợ độ phân giải chuẩn 4K@30Hz / Full HD 1080p vỏ kim loại tản nhiệt tốt.',162,2),
  -- SanPham 4
 (N'Tai nghe không dây JBL Wave Buds 2','https://res.cloudinary.com/jw935dos/image/upload/v1792169120/TaiNghe-KoDay.png',1550000,
 N'Tai nghe True Wireless chống ồn chủ động (ANC), chuẩn Bluetooth 5.3, thời lượng pin tổng lên đến 40 giờ (10 giờ tai nghe + 30 giờ hộp sạc).',768,2);

--=========================================================================
-------- TRUY VẤN BÌNH THƯỜNG KẾT HỢP KHAI BÁO BIẾN ---------

-- Khai báo biến để nhận dữ liệu từ phía người dùng mà kiểm tra
 -- Cú pháp khai báo ở SQL để test code trong sql
 -- DECLARE @TenBien KieuDuLieu;
 -- Cú pháp gán:
 -- SET @TenBien = giá trị theo kiểu dữ liệu đã khai báo
 -- Cú pháp gán giá trị từ 1 bảng vào biến
 -- Ví dụ:
-- DECLARE @MaSP INT
-- SELECT @MaSP = MaSP 
-- FROM SanPham
-- WHERE GiaBan > 100000

--- THÊM KHÁCH HÀNG ĐỂ TEST (Lưu ý test hết truy vấn r mới xoá):
INSERT INTO KhachHang(HoTen,Email,MatKhauTK)
VALUES(N'Nguyễn Văn A','NgVanA@gmail.com','123456')
SELECT * FROM KhachHang
--- XOÁ KHÁCH HÀNG ĐÃ THÊM Ở TRÊN
DELETE KhachHang WHERE MaKH = 1

--- RESET LẠI IDENTITY CỦA KHÁCH SAU KHI XOÁ KHÁCH MẪU
 DBCC CHECKIDENT ('KhachHang', RESEED, 0);
GO
--======================
-- CHỨC NĂNG ĐĂNG KÝ 
--=======================
--1 kiểm tra email có trùng ko 
DECLARE @Email VARCHAR(100)
        -- Khai báo biến 
-----        
SELECT MaKH
FROM KhachHang
WHERE Email = @Email;
GO
--2 Thêm tài khoản

DECLARE  @HoTen NVARCHAR(30) = N'Nguyễn Văn B',       -- Khai báo biến 
         @MatKhauHash  CHAR(60) = '7890ga',    -- Khai báo biến 
         @Email VARCHAR(100)  = 'NgVanB@gmail.com'   -- Khai báo biến 
------
INSERT INTO KhachHang ( HoTen, Email, MatKhauTK)
VALUES (@HoTen, @Email, @MatKhauHash);
GO
-- Xoá khác hàng đã thêm ở trên
SELECT * FROM KhachHang -- kiểm tra MaKH để xoá 
DELETE KhachHang WHERE MaKH = 2 -- Đổi mã khách hàng nếu khác

--- RESET LẠI IDENTITY CỦA KHÁCH SAU KHI XOÁ KHÁCH vừa thêm vì TEST CODE
 DBCC CHECKIDENT ('KhachHang', RESEED, 1);
GO



--===========================
-- CHỨC NĂNG ĐĂNG NHẬP
--===========================
DECLARE  @MatKhau CHAR(60),    -- Khai báo biến 
         @Email VARCHAR(100)    -- Khai báo biến
SELECT  MaKH, HoTen, Email, SDT, DiaChi, MatKhauTK,PhanQuyen
FROM KhachHang
WHERE Email = @Email AND MatKhauTK = @MatKhau;
GO

--==========================================================
-- CHỨC NĂNG: Kiểm tra tồn kho của một sản phẩm còn đủ với số lượng cần mua không
--==========================================================
DECLARE @SoLuong INT,     -- Khai báo biến 
        @MaSP INT    -- Khai báo biến 
-- Ví dụ cho giá trị như sau:
SET @SoLuong  = 3
SET @MaSP  = 4
---
SELECT
    MaSP,
    TenSP,
    GiaBan,
    SLTonKho
FROM SanPham
WHERE MaSP = @MaSP
  AND SLTonKho >= @SoLuong;

GO
--********************************************
-- GIỎ HÀNG
--********************************************
--====================================
-- Lưu sản phẩm khách hàng đã thêm có 2 trường hợp
--====================================
-- Thêm Giỏ hàng trước cho khách để TEST Trường hợp 1
INSERT INTO GioHang (MaKH)
VALUES (1);

----------------KHAI BÁO ĐỂ TEST Trường hợp 1--------
DECLARE @SoLuong INT = 2,     -- Khai báo biến 
        @MaSP INT = 3,    -- Khai báo biến 
        @MaKH INT  = 1,  -- Khai báo biến 
        @MaGH INT = 1
---------------
---- Tìm giỏ hàng để kiểm tra xem thuộc trường hợp 1 hay 2
SELECT MaGH
FROM GioHang
WHERE MaKH = @MaKH     -- ko trả về gì => trường hợp 1
 
-- 1 Nếu đã có sẵn giỏ hàng
--  Thêm vào giỏ hàng sản phẩm 
INSERT INTO ChiTietGioHang (MaGH, MaSP, SoLuong)
VALUES (@MaGH, @MaSP, @SoLuong);
GO
--- Dừng test
-- XOÁ GIỎ HÀNG & RESET IDENTITY SAU KHI TEST
DELETE GioHang WHERE MaKH = 1 -- vì chitietGioHang có on delete cascade nên tự xoá theo
GO
DBCC CHECKIDENT ('GioHang', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM GioHang
SELECT * FROM ChiTietGioHang
---------------------------------------------------------
----------------KHAI BÁO ĐỂ TEST Trường hợp 2 --------
DECLARE @SoLuong INT = 2,     -- Khai báo biến 
        @MaSP INT = 3,    -- Khai báo biến 
        @MaKH INT  = 1,  -- Khai báo biến 
        @MaGH INT  
---------------
-- 2 Chưa có giỏ hàng
-- Tạo giỏ hàng mới nếu khách chưa có giỏ
INSERT INTO GioHang (MaKH)
VALUES (@MaKH);

-- Lấy mã giỏ hàng vừa tạo
-- giải thích code:SCOPE_IDENTITY() lấy ra giá trị của cột tự tăng (IDENTITY) vừa mới được tạo ra gần nhất.
-- giải thích code:CAST(... AS INT) CAST dùng để chuyển đổi kiểu dữ liệu của một giá trị sang một kiểu dữ liệu khác.
SELECT SCOPE_IDENTITY()  AS MaGH;

-- TEST: khởi tạo giá trị @MaGH = MaGH sau khi thêm giỏ hàng cho khách ở trên
SET @MaGH = 
(SELECT MaGH
FROM GioHang
WHERE MaKH = @MaKH) -- Tìm giỏ hàng vừa tạo cho khách
------------------------------------------------
-- Thêm vào giỏ hàng sản phẩm 
INSERT INTO ChiTietGioHang (MaGH, MaSP, SoLuong)
VALUES (@MaGH, @MaSP, @SoLuong);
GO

-- XOÁ GIỎ HÀNG & RESET IDENTITY SAU KHI TEST
DELETE GioHang WHERE MaKH = 1 -- vì chitietGioHang có on delete cascade nên tự xoá theo
GO
DBCC CHECKIDENT ('GioHang', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM GioHang
SELECT * FROM ChiTietGioHang

-- Phần 3 Ngoài lề Nếu sản phẩm đã có trong giỏ hàng
-- Cập nhật số lượng sản phẩm
-- KHOAN XOÁ GIỎ HÀNG Ở TRÊN NẾU MUỐN TEST 
----------------KHAI BÁO ĐỂ TEST Phần 3 --------
DECLARE @SoLuongThem INT = 2,     -- Khai báo biến 
        @MaSP INT = 3,    -- Khai báo biến 
        @MaKH INT  = 1,  -- Khai báo biến 
        @MaGH INT = 1
--------------- 
UPDATE ChiTietGioHang
SET SoLuong = SoLuong + @SoLuongThem
WHERE MaGH = @MaGH
  AND MaSP = @MaSP;
-- Kiểm tra xem số lượng tăng chưa 
SELECT * FROM ChiTietGioHang
GO
-- XOÁ GIỎ HÀNG & RESET IDENTITY SAU KHI TEST
DELETE GioHang WHERE MaKH = 1 -- vì chitietGioHang có on delete cascade nên tự xoá theo
GO
DBCC CHECKIDENT ('GioHang', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM GioHang
SELECT * FROM ChiTietGioHang


--===========================
-- YÊU CẦU: Lưu số lượng và giá tại thời điểm đặt hàng
--===========================
-- Tình huống người dùng đặt hàng trong giỏ hàng chứa ko đặt hàng trực tiếp khi thấy sản phẩm
-- Tạo giỏ hàng cho khách để test
INSERT INTO GioHang (MaKH)
VALUES (1);
GO
-- Thêm vào giỏ hàng sp để test
INSERT INTO ChiTietGioHang (MaGH, MaSP, SoLuong)
VALUES (1, 3, 2);
GO
-- Kiểm tra xem tạo dữ liệu mẫu chưa
SELECT * FROM GioHang
SELECT * FROM ChiTietGioHang
----------------KHAI BÁO ĐỂ TEST Một lượt từ 1 đến 7 (quét từ 1 - 7)--------
DECLARE @SoLuong INT = 2,     -- Khai báo biến 
        @MaSP INT = 3,    -- Khai báo biến 
        @MaKH INT  = 1,  -- Khai báo biến 
        @MaGH INT = 1,
        @MaDH INT,
        @TongTien DECIMAL(12, 2)
--------------- 
-- 1.CHỨC NĂNG: Lấy thông tin 1 sản phẩm khách đã tích chọn
SELECT
    CT.MaSP,
    SP.TenSP,
    CT.SoLuong,
    SP.GiaBan,
    SP.SLTonKho,
    CT.SoLuong * SP.GiaBan AS ThanhTien
FROM ChiTietGioHang AS CT
INNER JOIN SanPham AS SP
    ON CT.MaSP = SP.MaSP
WHERE CT.MaGH = @MaGH
  AND CT.MaSP = @MaSP;

-- 2  Kiểm tra 1 sản phẩm có đủ hàng để đặt mua không (Kiểm tra số lượng tồn kho để xem có cho khách đặt ko)
-- LƯU Ý Phải kiểm tra hết tồn kho của tất cả sản phẩm (nếu chọn nhiều sp)

SELECT MaSP, TenSP, SLTonKho
FROM SanPham
WHERE MaSP = @MaSP
  AND SLTonKho >= @SoLuong;

-- 3  Tạo đơn hàng
INSERT INTO DonHang (MaKH, TongTienTT)
VALUES (@MaKH, @TongTien);

-- Lấy mã đơn hàng vừa sinh
SET @MaDH = SCOPE_IDENTITY();

-- 4.chuyển từ ChiTietGioHang sang  ChiTietDonHang 
-- a> Truờng hơp nếu người dùng chọn mua 1 sản phẩm trong giỏ hàng (có thể lặp nhiều lần nếu chọn mua nhiều sp khác nhau)

INSERT INTO ChiTietDonHang (MaDH, MaSP, SoLuong, DonGia)
SELECT 
    @MaDH,
    ghct.MaSP,
    ghct.SoLuong,    -- Lấy đúng số lượng người dùng đã chỉnh/lưu trong giỏ hàng
    sp.GiaBan      -- Lấy giá bán hiện tại từ bảng SanPham
FROM ChiTietGioHang ghct
JOIN GioHang gh ON ghct.MaGH = gh.MaGH
JOIN SanPham sp ON sp.MaSP = ghct.MaSP
WHERE gh.MaKH = @MaKH 
  AND ghct.MaSP = @MaSP; -- Lấy Mã sản phẩm người dùng tích chọn trong giỏ hàng để mua


-- 5 Chức năng cập nhật số lượng tồn kho khi thêm đc mỗi 1 chi tiết đơn hàng thành công ở trên
UPDATE SanPham
SET SLTonKho = SLTonKho - @SoLuong
WHERE MaSP = @MaSP
  AND SLTonKho >= @SoLuong;

-- 6 Xoá sản phẩm đã chuyển thành đơn đặt hàng trên khỏi giỏ hàng
DELETE ct
FROM ChiTietGioHang ct
JOIN GioHang gh ON ct.MaGH = gh.MaGH
WHERE gh.MaKH = @MaKH 
  AND ct.MaSP = @MaSP; -- 1 sản phẩm đã chọn

--  7 TÍNH + LƯU TỔNG TIỀN THANH TOÁN VÀO ĐƠN HÀNG
--CHỨC NĂNG: Tính tổng tiền của đơn hàng (chi tiêt các đơn hàng)
SELECT
    SUM(SoLuong * DonGia) AS TongTien
FROM ChiTietDonHang
WHERE MaDH = @MaDH;
-- CHỨC NĂNG: Lưu tổng tiền vừa tính vào đơn hàng (bảng đơn hàng)
UPDATE DonHang
SET TongTienTT = @TongTien
WHERE MaDH = @MaDH;

GO
-- DỪNG TEST
-- KHÔI PHỤC SAU KHI TEST
  -- XOÁ GIỎ HÀNG & RESET IDENTITY SAU KHI TEST
DELETE GioHang WHERE MaKH = 1 -- vì chitietGioHang có on delete cascade nên tự xoá theo
GO
DBCC CHECKIDENT ('GioHang', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM GioHang
SELECT * FROM ChiTietGioHang
-- XOÁ ĐƠN HÀNG & RESET IDENTITY SAU KHI TEST
DELETE FROM ChiTietDonHang WHERE MaDH = 1
DELETE DonHang WHERE MaKH = 1
GO
DBCC CHECKIDENT ('DonHang', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM DonHang
SELECT * FROM ChiTietDonHang
-- KHÔI PHỤC LẠI SỐ LƯỢNG TỒN KHO
UPDATE SanPham
SET SLTonKho = SLTonKho + 2
WHERE MaSP = 3
-- Kiểm tra 
SELECT * FROM SanPham WHERE MaSP=3



---------------------------------------------------------------------------------------
-- Với trường hợp " b> người dùng tích chọn nhiều sản phẩm nhưng ko phải tất cả:" khuyên nên truyền lần lượt (chạy truy vấn lặp lại nhiều lần) bằng cách chạy chức năng chuyển ChitietGioHang sang ChiTietDH ở a dễ hơn
-- Ví dụ : giỏ khách : có sp MaSP: 1 , 8 , 4 ,5 khách chọn 1, 8 
-- 1.chạy truy vấn trên lần lượt với maSP là 1 rồi tới 8 mỗi lần phải kiểm tra tồn kho có đủ ko 
-- 2. Nếu sl tồn kho của tất cả sản phẩm đủ hết tiến hành tạo đơn hàng và lần lượt chuyển sp từ giỏ hàng sang đơn hàng mỗi lượt Giảm số lượng tồn kho và xoá sp khỏi giỏ hàng  
-- 3.Tính tổng tiền đơn hàng và lưu lại
-- -----------------------------------------------------------------------------------

--===========================================
--Cho phép cập nhật số lượng và xóa sản phẩm
--============================================
-- Tạo giỏ hàng cho khách để test
INSERT INTO GioHang (MaKH)
VALUES (1);
GO
-- Thêm vào giỏ hàng sp để test
INSERT INTO ChiTietGioHang (MaGH, MaSP, SoLuong)
VALUES (1, 3, 2);
GO
-- Kiểm tra dữ liệu thêm vào
SELECT * FROM GioHang
SELECT * FROM ChiTietGioHang
----------------KHAI BÁO ĐỂ TEST --------
 DECLARE @MaSP INT = 3,    -- Khai báo biến 
         @MaGH INT = 1
--------------- 
-- Tăng số lượng sản phẩm trong giỏ lên 1 đơn vị 
UPDATE ChiTietGioHang
SET SoLuong = SoLuong + 1
WHERE MaGH = @MaGH
  AND MaSP = @MaSP;
GO

----------------KHAI BÁO ĐỂ TEST a--------
 DECLARE @MaSP INT = 3,    -- Khai báo biến 
         @MaGH INT = 1
--------------- 
--Giảm số lượng sản phẩm trong giỏ đi 1 đơn vị
-- a nếu số lượng sản phẩm vẫn còn dư lại 1
UPDATE ChiTietGioHang
SET SoLuong = SoLuong - 1
WHERE MaGH = @MaGH
  AND MaSP = @MaSP
  AND SoLuong > 1;
GO 
----------------KHAI BÁO ĐỂ TEST b --------
 DECLARE @MaSP INT = 3,    -- Khai báo biến 
         @MaGH INT = 1
--------------- 
-- b nếu chỉ còn 1 mà giảm về 0 thì xoá luôn sản phẩm đó khỏi bảng
DELETE FROM ChiTietGioHang
WHERE MaGH = @MaGH
  AND MaSP = @MaSP;
GO

----------------KHAI BÁO ĐỂ TEST  --------
 DECLARE @MaSP INT = 3,    -- Khai báo biến 
         @MaGH INT = 1
--------------- 
-- Ngoài lề : Làm trống giỏ hàng / xoá hết sản phẩm trong giỏ hàng
DELETE FROM ChiTietGioHang
WHERE MaGH = @MaGH;
GO
-- Xóa giỏ hàng cũ của khách ko còn tài khoản
----------------KHAI BÁO ĐỂ TEST  (Nếu chưa xoá ở trên xoá rổi lật lên thêm dữ liệu mẫu đã cấp để test) --------
 DECLARE @MaSP INT = 3,    -- Khai báo biến 
         @MaGH INT = 1,
         @MaKH INT  = 1
--------------- 
-- Xóa chi tiết giỏ hàng 
DELETE ct 
FROM ChiTietGioHang ct 
JOIN GioHang gh ON ct.MaGH = gh.MaGH 
WHERE gh.MaKH = @MaKH;
-- Xóa giỏ hàng
DELETE FROM GioHang 
WHERE MaKH = @MaKH;
GO  

-- XOÁ GIỎ HÀNG & RESET IDENTITY SAU KHI TEST
DELETE GioHang WHERE MaKH = 1 -- vì chitietGioHang có on delete cascade nên tự xoá theo
GO
DBCC CHECKIDENT ('GioHang', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM GioHang
SELECT * FROM ChiTietGioHang


--===========================================
--Gắn giỏ hàng với tài khoản người dùng
--============================================

----------------KHAI BÁO ĐỂ TEST --------
 DECLARE     @MaKH INT  = 1,  -- Khai báo biến 
             @MaGH INT = 1 -- Khai báo biến 
--------------- 

--------------- 
-- Lấy toàn bộ giỏ hàng của một khách hàng (Khách xem giỏ hàng)

SELECT
    gh.MaGH,
    gh.MaKH,
    ct.MaSP,
    sp.TenSP,
    sp.HinhAnh,
    sp.GiaBan,
    ct.SoLuong,
    sp.GiaBan * ct.SoLuong AS ThanhTien
FROM GioHang AS gh
INNER JOIN ChiTietGioHang AS ct
    ON gh.MaGH = ct.MaGH
INNER JOIN SanPham AS sp
    ON ct.MaSP = sp.MaSP
WHERE gh.MaKH = @MaKH
ORDER BY gh.NgayTao DESC;

GO
-- — Xem giỏ hàng và tính tổng tiền 

----------------KHAI BÁO ĐỂ TEST --------
DECLARE   @MaGH INT = 1 -- Khai báo biến 
--------------- 
-- CHỨC NĂNG: Hiển thị chi tiết giỏ hàng
SELECT
    SP.MaSP,
    SP.TenSP,
    SP.HinhAnh,
    SP.GiaBan,
    CT.SoLuong,
    SP.GiaBan * CT.SoLuong AS ThanhTien
FROM ChiTietGioHang AS CT
INNER JOIN SanPham AS SP
    ON CT.MaSP = SP.MaSP
WHERE CT.MaGH = @MaGH 
ORDER BY SP.TenSP;

GO



--***********************************
-- THÔNG BÁO
--***********************************



--================================
-- Lưu thông báo khuyến mãi cho khách hàng
--================================
----------------KHAI BÁO ĐỂ TEST --------
DECLARE @TieuDe NVARCHAR(200)= N'Thông báo kuyến mãi ngày 20/10',     -- Khai báo biến 
        @NoiDung NVARCHAR(1000) =N'Các sản phẩm thuộc loại mỹ phẩm hôm nay giảm giá sốc đến 10%' ,      -- Khai báo biến 
        @MaKH INT  = 1,  -- Khai báo biến
        @MaGH INT = 1       -- Khai báo biến
--------------- 
INSERT INTO ThongBao
    (MaKH, TieuDe, NoiDung, LoaiTB)
VALUES
    (@MaKH, @TieuDe, @NoiDung, N'Khuyến Mãi');


--  XOÁ THÔNG BÁO VỪA THÊM  & RESET IDENTITY SAU KHI TEST
DELETE ThongBao WHERE MaKH = 1 -- vì chitietGioHang có on delete cascade nên tự xoá theo
GO
DBCC CHECKIDENT ('ThongBao', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM ThongBao

--==========================================================
-- Lưu thông báo xác nhận đơn hàng hoặc cập nhật giao hàng
--==========================================================
-- Thêm đơn hàng để test
INSERT INTO DonHang
    (MaKH)
VALUES
    (1);
----------------KHAI BÁO ĐỂ TEST -------- 
DECLARE @NoiDung NVARCHAR(1000) =N'Đơn hàng của bạn đang được xử lý' ,      -- Khai báo biến 
        @MaKH INT  = 1,  -- Khai báo biến
         @MaDH INT = 1       -- Khai báo biến
--------------- 

-- Khi đơn hàng được xác nhận:
INSERT INTO ThongBao
    (MaKH, TieuDe, NoiDung, LoaiTB, MaDH)
VALUES
    ( @MaKH, N'Xác nhận đơn hàng',@NoiDung, N'Đơn Hàng', @MaDH);
GO
--  XOÁ THÔNG BÁO VỪA THÊM  & RESET IDENTITY SAU KHI TEST
DELETE ThongBao WHERE MaKH = 1 -- vì chitietGioHang có on delete cascade nên tự xoá theo
GO
DBCC CHECKIDENT ('ThongBao', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM ThongBao



----------------KHAI BÁO ĐỂ TEST -------- 
DECLARE @NoiDung NVARCHAR(1000) =N'Đơn hàng của bạn đang được giao tới' ,      -- Khai báo biến 
        @MaKH INT  = 1,  -- Khai báo biến
         @MaDH INT = 1       -- Khai báo biến
--------------- 
-- Khi trạng thái giao hàng thay đổi:
INSERT INTO ThongBao
    (MaKH, TieuDe, NoiDung, LoaiTB, MaDH)
VALUES
    (  @MaKH,N'Cập nhật giao hàng', @NoiDung, N'Giao Hàng', @MaDH );
GO
--  XOÁ THÔNG BÁO VỪA THÊM  & RESET IDENTITY SAU KHI TEST
DELETE ThongBao WHERE MaKH = 1 
GO
DBCC CHECKIDENT ('ThongBao', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM ThongBao

-- XOÁ ĐƠN HÀNG & RESET IDENTITY SAU KHI TEST
DELETE FROM ChiTietDonHang WHERE MaDH = 1
DELETE DonHang WHERE MaKH = 1
GO
DBCC CHECKIDENT ('DonHang', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM DonHang
SELECT * FROM ChiTietDonHang

--================================
-- Theo dõi thông báo đã đọc/chưa đọc
--================================
----------------KHAI BÁO ĐỂ TEST -------- 
DECLARE    @MaKH INT  = 1  -- Khai báo biến
--------------- 
-- Lấy tất cả thông báo của khách hàng:
SELECT
    MaTB,
    TieuDe,
    NoiDung,
    LoaiTB,
    MaDh,
    NgayTao,
    DaDoc
FROM ThongBao
WHERE MaKH = @MaKH
ORDER BY NgayTao DESC;

GO



---------------KHAI BÁO ĐỂ TEST -------- 
DECLARE    @MaKH INT  = 1  -- Khai báo biến
--------------- 
-- Chỉ lấy thông báo chưa đọc:
SELECT MaTB, TieuDe, NoiDung, NgayTao
FROM ThongBao
WHERE MaKH = @MaKH
  AND DaDoc = 0
ORDER BY NgayTao DESC;

GO

---------------KHAI BÁO ĐỂ TEST -------- 
DECLARE    @MaKH INT  = 1  -- Khai báo biến
--------------- 
-- Chỉ lấy thông báo đã đọc:
SELECT MaTB, TieuDe, NoiDung, NgayTao
FROM ThongBao
WHERE MaKH = @MaKH
  AND DaDoc = 1
ORDER BY NgayTao DESC;

GO
--------------------------
-- Thêm thông báo để test
INSERT INTO ThongBao
    (MaKH, TieuDe, NoiDung, LoaiTB)
VALUES
    ( 1, N'Xác nhận đơn hàng',N'Đơn hàng đang được xử lý', N'Đơn Hàng'),
    (1,  N'Huỷ đơn hàng',N'Đơn hàng bị huỷ vì số lượng tồn kho ko đủ', N'Đơn Hàng')
GO
-- kiểm tra thay đổi trong bảng Thông báo
SELECT * FROM ThongBao

---------------KHAI BÁO ĐỂ TEST -------- 
DECLARE    @MaKH INT  = 1,  -- Khai báo biến
           @MaTB INT = 1  -- Khai báo biến
--------------- 

-- Đánh dấu một thông báo đã đọc rồi:
UPDATE ThongBao
SET DaDoc = 1
WHERE MaTB = @MaTB
  AND MaKH = @MaKH;
GO
-- Đánh dấu tất cả thông báo là đã đọc:
---------------KHAI BÁO ĐỂ TEST -------- 
DECLARE    @MaKH INT  = 1  -- Khai báo biến
--------------- 
UPDATE ThongBao
SET DaDoc = 1
WHERE MaKH = @MaKH
  AND DaDoc = 0;
GO

---------------KHAI BÁO ĐỂ TEST -------- 
DECLARE    @MaKH INT  = 1  -- Khai báo biến
--------------- 
-- Đếm số thông báo chưa đọc
SELECT COUNT(*) AS SoThongBaoChuaDoc
FROM ThongBao
WHERE MaKH = @MaKH
  AND DaDoc = 0;


--  XOÁ THÔNG BÁO VỪA THÊM  & RESET IDENTITY SAU KHI TEST
DELETE ThongBao WHERE MaKH = 1 
GO
DBCC CHECKIDENT ('ThongBao', RESEED, 0);
GO
-- Kiểm tra xem xoá đc chưa
SELECT * FROM ThongBao

 --*******************************************
 --  ĐƠN HÀNG
 --******************************************
 --==========================
 --Lưu đơn hàng của khách
 --==========================

 ---------------KHAI BÁO ĐỂ TEST (quét từ 1 - 4)-------- 
DECLARE    @SoLuong INT = 2,     -- Khai báo biến 
           @MaSP INT = 3,    -- Khai báo biến
           @MaKH INT  = 1,  -- Khai báo biến
           @MaDH INT,        -- Khai báo biến
           @TongTien DECIMAL(12, 2) -- Khai báo biến
--------------- 
 -- 1.Tạo đơn hàng mới cho khách
INSERT INTO DonHang
    (MaKH)
VALUES
    (@MaKH);

-- Lấy về mã đơn hàng vừa tạo // gán giá trị cho biến @MaDH = mã đơn hàng vừa tạo ở trên
SET @MaDH = SCOPE_IDENTITY();

-- 2. Lưu chi tiết của 1 sản phẩm đã đặt hàng
INSERT INTO ChiTietDonHang (MaDH, MaSP, SoLuong, DonGia)
SELECT 
    @MaDH, 
    @MaSP, 
    @SoLuong, 
    sp.GiaBan -- Lấy giá bán hiện tại từ bảng SanPham
FROM SanPham sp
WHERE sp.MaSP = @MaSP;


-- 3 CHỨC NĂNG: Tính tổng tiền của đơn hàng (chi tiêt các đơn hàng)
SELECT
    SUM(SoLuong * DonGia) AS TongTien
FROM ChiTietDonHang
WHERE MaDH = @MaDH;
-- 4 CHỨC NĂNG: Lưu tổng tiền vừa tính vào đơn hàng (bảng đơn hàng)
UPDATE DonHang
SET TongTienTT = @TongTien
WHERE MaDH = @MaDH;
--- Dừng TEST

-- XOÁ ĐƠN HÀNG & RESET IDENTITY SAU KHI TEST
DELETE FROM ChiTietDonHang WHERE MaDH = 1
DELETE DonHang WHERE MaKH = 1
GO
DBCC CHECKIDENT ('DonHang', RESEED, 0);
GO

-- Kiểm tra xem xoá đc chưa
SELECT * FROM DonHang
SELECT * FROM ChiTietDonHang



--==========================
-- Theo dõi trạng thái đơn hàng
--==============================
-- Thêm đơn hàng để TEST
INSERT INTO DonHang
    (MaKH)
VALUES
    (1);

 ---------------KHAI BÁO ĐỂ TEST (quét từ 1 - 4)-------- 
DECLARE    @SoLuong INT = 2,     -- Khai báo biến 
           @MaSP INT = 3,    -- Khai báo biến
           @MaKH INT  = 1,  -- Khai báo biến
           @MaDH INT,        -- Khai báo biến
           @TongTien DECIMAL(12, 2) -- Khai báo biến
--------------- 

-- Khách hàng Xem trạng thái đơn hàng hiện tại
SELECT
    MaDH,
    NgayDat,
    TrangThai
FROM DonHang
WHERE MaKH = @MaKH
ORDER BY NgayDat DESC;
GO

----------------------------
-- Cập nhật trạng thái đơn hàng linh hoạt trên java với các trạng thái sau:
---------------------------- 
--   Chờ xác nhận (khi mới tạo đơn hàng mới luôn ở trạng thái này)
--   Đã xác nhận 
--   Đang xử lý
--   Đã giao
--   Hoàn thành
--   Đã hủy
---------------------------
 ---------------KHAI BÁO ĐỂ TEST -------- 
DECLARE    @TrangThaiMoi NVARCHAR(30) =N'Đang xử lý', 
           @MaDH INT = 1      -- Khai báo biến

--------------- 
UPDATE DonHang
SET TrangThai = @TrangThaiMoi
WHERE MaDH = @MaDH;
GO


-- Cập nhật trạng thái đơn hàng cố định
 ---------------KHAI BÁO ĐỂ TEST -------- 
DECLARE  @MaDH INT = 1      -- Khai báo biến
--------------- 
-- Trạng thái Đã xác nhận
UPDATE DonHang
SET TrangThai = N'Đã xác nhận'
WHERE MaDH = @MaDH;
GO 
-- Kiểm tra sau khi cập nhật trạng thái
SELECT * FROM DonHang

 ---------------KHAI BÁO ĐỂ TEST -------- 
DECLARE  @MaDH INT = 1      -- Khai báo biến
--------------- 
-- Trạng thái Đang xử lý
UPDATE DonHang
SET TrangThai = N'Đang xử lý'
WHERE MaDH = @MaDH;
GO 
-- Kiểm tra sau khi cập nhật trạng thái
SELECT * FROM DonHang


 ---------------KHAI BÁO ĐỂ TEST -------- 
DECLARE  @MaDH INT = 1      -- Khai báo biến
--------------- 
-- Trạng thái Đã giao
UPDATE DonHang
SET TrangThai = N'Đã giao'
WHERE MaDH = @MaDH;
GO 
-- Kiểm tra sau khi cập nhật trạng thái
SELECT * FROM DonHang

 ---------------KHAI BÁO ĐỂ TEST -------- 
DECLARE  @MaDH INT = 1      -- Khai báo biến
--------------- 
-- Trạng thái Hoàn thành
UPDATE DonHang
SET TrangThai = N'Hoàn thành'
WHERE MaDH = @MaDH;
GO 
-- Kiểm tra sau khi cập nhật trạng thái
SELECT * FROM DonHang

 ---------------KHAI BÁO ĐỂ TEST -------- 
DECLARE  @MaDH INT = 1      -- Khai báo biến
--------------- 
-- Trạng thái Đã hủy
UPDATE DonHang
SET TrangThai = N'Đã hủy'
WHERE MaDH = @MaDH;
GO 
-- Kiểm tra sau khi cập nhật trạng thái
SELECT * FROM DonHang


-- XOÁ ĐƠN HÀNG & RESET IDENTITY SAU KHI TEST
DELETE FROM ChiTietDonHang WHERE MaDH = 1
DELETE DonHang WHERE MaKH = 1
GO
DBCC CHECKIDENT ('DonHang', RESEED, 0);
GO

-- Kiểm tra xem xoá đc chưa
SELECT * FROM DonHang
SELECT * FROM ChiTietDonHang



 --==========================================================
-- CHỨC NĂNG: Hiển thị các đơn hàng của một khách hàng (lịch sử mua hàng)
--==========================================================
-- Thêm đơn hàng để test
INSERT INTO DonHang
    (MaKH)
VALUES
    (1),(1) -- Thêm 2 đơn cho 1 khách để xem
  ---------------KHAI BÁO ĐỂ TEST -------- 
DECLARE  @MaKH INT = 1      -- Khai báo biến
--------------- 
SELECT
    MaDH,
    NgayDat,
    TrangThai,
    TongTienTT
FROM DonHang
WHERE MaKH = @MaKH
ORDER BY NgayDat DESC, MaDH DESC;
GO
--==========================================================
-- CHỨC NĂNG: Hiển thị các sản phẩm trong một đơn hàng (xem chi tiết 1 đơn hàng)
--==========================================================
-- Thêm đơn hàng để test
INSERT INTO DonHang (MaKH)
VALUES (1);
GO
INSERT INTO ChiTietDonHang (MaDH, MaSP, SoLuong, DonGia)
SELECT 1, MaSP, 2, sp.GiaBan -- Lấy giá bán hiện tại từ bảng SanPham
FROM SanPham sp
WHERE sp.MaSP = 3
----------
  ---------------KHAI BÁO ĐỂ TEST -------- 
DECLARE  @MaKH INT = 1 ,     -- Khai báo biến
         @MaDH INT = 1      -- Khai báo biến
--------------- 

SELECT
    DH.MaDH,
    DH.NgayDat,
    DH.TrangThai,
    DH.TongTienTT,
    SP.MaSP,
    SP.TenSP,
    SP.HinhAnh,
    CT.SoLuong,
    CT.DonGia,
    CT.SoLuong * CT.DonGia AS ThanhTien
FROM DonHang AS DH
INNER JOIN ChiTietDonHang AS CT
    ON DH.MaDH = CT.MaDH
INNER JOIN SanPham AS SP
    ON CT.MaSP = SP.MaSP
WHERE DH.MaDH = @MaDH
  AND DH.MaKH = @MaKH
ORDER BY SP.TenSP;

GO


-- XOÁ ĐƠN HÀNG & RESET IDENTITY SAU KHI TEST
DELETE FROM ChiTietDonHang WHERE MaDH = 1
DELETE DonHang WHERE MaKH = 1
GO
DBCC CHECKIDENT ('DonHang', RESEED, 0);
GO

-- Kiểm tra xem xoá đc chưa
SELECT * FROM DonHang
SELECT * FROM ChiTietDonHang


--=========================================
-- Ngoài lề nếu huỷ đơn và hoàn kho (thực hiện từ 1  - 4)
--=========================================

  ---------------KHAI BÁO ĐỂ TEST cùng lúc chức năng 1 & 2 -------- 
DECLARE   @MaDH INT = 1      -- Khai báo biến
--------------- 

-- CHỨC NĂNG 1: Kiểm tra đơn hàng trước khi hủy
SELECT MaDH, MaKH, TrangThai
FROM DonHang
WHERE MaDH = @MaDH;

-- CHỨC NĂNG 2: Lấy số lượng từng sản phẩm của đơn cần hủy
SELECT MaSP, SoLuong
FROM ChiTietDonHang
WHERE MaDH = @MaDH;
Go

  ---------------KHAI BÁO ĐỂ TEST  chức năng 3 -------- 
DECLARE   @MaDH INT = 1 , -- Khai báo biến
          @MaSP INT = 3 ,
          @SoLuong INT = 2
--------------- 
-- CHỨC NĂNG 3: Hoàn số lượng về kho khi hủy đơn (hoàn lại cho từng sp)

UPDATE SanPham
SET SLTonKho = SLTonKho + @SoLuong
WHERE MaSP = @MaSP;

GO
-- KHÔI PHỤC SL TonKho ban đầu
UPDATE SanPham
SET SLTonKho = SLTonKho - 2
WHERE MaSP = 3;

-- Cập nhật lại trạng thái đơn hàng đã huỷ
-- Thêm đơn hàng để test
INSERT INTO DonHang (MaKH)
VALUES (1);
GO
  ---------------KHAI BÁO ĐỂ TEST chức năng 4 -------- 
DECLARE   @MaDH INT = 1  -- Khai báo biến
--------------- 
-- CHỨC NĂNG 4: Đánh dấu đơn hàng đã hủy
UPDATE DonHang
SET TrangThai = N'Đã hủy'
WHERE MaDH = @MaDH;

GO

-- XOÁ ĐƠN HÀNG & RESET IDENTITY SAU KHI TEST
DELETE FROM ChiTietDonHang WHERE MaDH = 1
DELETE DonHang WHERE MaKH = 1
GO
DBCC CHECKIDENT ('DonHang', RESEED, 0);
GO

-- Kiểm tra xem xoá đc chưa
SELECT * FROM DonHang
SELECT * FROM ChiTietDonHang




 --==========================================
 --         CODE TRUY VẤN ĐẠT CẦN
 --==========================================
-- TRANG CHỦ
--======================================
-- CHỨC NĂNG: Lấy ra tối đa 4 (có thể tự điều chỉnh lại số lượng lấy ra) sản phẩm nổi bật
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
GROUP BY             -- Nhóm sp lại để ko hiển thị 1 sp 2lần 
    SP.MaSP,
    SP.TenSP,
    SP.GiaBan,
    SP.HinhAnh
ORDER BY
    SoKhachHangDaXem DESC; -- sắp xếp giảm dần => các giá trị cao nhất luôn ở hàng đầu
GO

--=====================================
-- Chức năng kèm theo 
-- Ghi nhận một lần xem sp của khách (đã đăng nhập hoặc chưa đều đc) 
  ---------------KHAI BÁO ĐỂ TEST chức năng KÈM THEO -------- 
DECLARE   @MaKH INT = 1,  -- Khai báo biến
          @MaSP INT = 3
--------------- 
INSERT INTO LuotXemSP  (MaSP, MaKH)
VALUES (@MaSP, @MaKH);
    GO
-- 
-- XOÁ LƯỢT XEM & RESET IDENTITY SAU KHI TEST
DELETE LuotXemSP WHERE MaKH = 1
GO
DBCC CHECKIDENT ('LuotXemSP', RESEED, 0);
GO

-- Kiểm tra xem xoá đc chưa
SELECT * FROM LuotXemSP

--======================================

--===================================
-- CHỨC NĂNG: lấy ra tối đa 4 sản phẩm để đề xuất cho 1 khách hàng cụ thể
-- Tiêu chí: Số lần chính khách hàng đó xem từng sản phẩm (đã đăng ký tài khoản và đăng nhập r mới xem đc)
--====================================
 -- Thêm lượt xem để Test
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
-- XOÁ LƯỢT XEM & RESET IDENTITY SAU KHI TEST
DELETE LuotXemSP WHERE MaKH = 1
GO
DBCC CHECKIDENT ('LuotXemSP', RESEED, 0);
GO

-- Kiểm tra xem xoá đc chưa
SELECT * FROM LuotXemSP

-- Chức năng ngoài lề để giúp check xem sql có ghi lại đúng lịch sử xem của khách ko
-- CHỨC NĂNG: Kiểm tra lịch sử xem của khách hàng
SELECT
    MaSP,
    MaKH,
    COUNT(*) AS SoLanXem,
    MAX(ThoiGianXem) AS LanXemGanNhat
FROM LuotXemSP
GROUP BY
    MaSP,
    MaKH
ORDER BY
    SoLanXem DESC;
GO
--=======================
-- TANG BÁN HÀNG
--==========================
-- CHỨC NĂNG:  hiển thị hết tất cả sản phẩm kèm danh mục
-- Lấy thông tin sản phẩm và tên danh mục tương ứng
SELECT
    SP.MaSP,
    SP.TenSP,
    SP.HinhAnh,
    SP.GiaBan,
    SP.MoTa,
    SP.SLTonKho,
    DM.MaDM,    -- Bỏ nếu ko muốn hiển thị về danh mục
    DM.TenDM    -- Bỏ nếu ko muốn hiển thị về danh mục
FROM SanPham AS SP
INNER JOIN DanhMuc AS DM  -- Bỏ nếu ko muốn hiển thị về danh mục
    ON SP.MaDM = DM.MaDM  -- Bỏ nếu ko muốn hiển thị về danh mục
ORDER BY SP.MaSP DESC;
GO
--===============================
--- CHỨC NĂNG KHÁC 
-- ====================
-- CHỨC NĂNG: Tìm sản phẩm theo tên
 ---------------KHAI BÁO ĐỂ TEST  -------- 
DECLARE   @TuKhoa NVARCHAR(50) =N'Áo'  -- Khai báo biến
--------------- 
SELECT
    MaSP,
    TenSP,
    HinhAnh,
    GiaBan,
    MoTa,
    SLTonKho,
    MaDM
FROM SanPham
WHERE TenSP LIKE N'%' + @TuKhoa + N'%'   -- truyền từ khoá khách nhập vào
ORDER BY TenSP;
GO
--===========================
-- CHỨC NĂNG: Lọc sản phẩm theo danh mục
 ---------------KHAI BÁO ĐỂ TEST  -------- 
DECLARE   @MaDM SMALLINT = 1  -- Khai báo biến
--------------- 
SELECT
    SP.MaSP,
    SP.TenSP,
    SP.HinhAnh,
    SP.GiaBan,
    SP.MoTa,
    SP.SLTonKho,
    DM.TenDM
FROM SanPham AS SP
INNER JOIN DanhMuc AS DM
    ON SP.MaDM = DM.MaDM
WHERE SP.MaDM = @MaDM -- Truyền MaDM tương ứng mà khách tíc chọn
ORDER BY SP.TenSP;
GO
-- ===========================
-- CHỨC NĂNG: Lấy chi tiết một sản phẩm ra khi khách bấm xem 1 sản phẩm
 ---------------KHAI BÁO ĐỂ TEST  -------- 
DECLARE   @MaSP INT = 1  -- Khai báo biến
--------------- 
SELECT
    SP.MaSP,
    SP.TenSP,
    SP.HinhAnh,
    SP.GiaBan,
    SP.MoTa,
    SP.SLTonKho,
    SP.MaDM,
    DM.TenDM
FROM SanPham AS SP
INNER JOIN DanhMuc AS DM
    ON SP.MaDM = DM.MaDM
WHERE SP.MaSP = @MaSP ;
GO


--========================================================
-- XOÁ HẾT KHÁCH HÀNG ĐÃ TẠO KHI TEST & RESET IDENTITY
DELETE KhachHang WHERE MaKH IN(SELECT MaKH FROM KhachHang) 
GO
--- RESET LẠI IDENTITY CỦA KHÁCH SAU KHI XOÁ KHÁCH vừa thêm vì TEST CODE
 DBCC CHECKIDENT ('KhachHang', RESEED, 0);
GO
SELECT * FROM KhachHang
--=========================================================

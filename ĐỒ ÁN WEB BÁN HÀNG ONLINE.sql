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


-- =================THÊM DỮ LIỆU DANH MỤC=================
INSERT INTO DanhMuc (TenDM) VALUES
 ( N'Thời trang'),
 ( N'Công nghệ'),
 ( N'Đồ gia dụng'),
 ( N'Làm đẹp');
 GO

 -- tăng thêm để phòng link cloudinary dài hơn giới hạn 255
ALTER TABLE SanPham
ALTER COLUMN HinhAnh VARCHAR(500);
 GO


 -- ================THÊM DỮ LIỆU SẢN PHẨM ==================
 SELECT * FROM SanPham
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
 SELECT * FROM  SanPham -- CHECK XEM CÓ THIẾU KO
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
SELECT * FROM SanPham  -- CHECK XEM CÓ THIẾU KO
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
SELECT * FROM SanPham -- CHECK XEM CÓ THIẾU KO
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

USE WebBanHangOnline_N6;
GO
-- Kiểm tra các dữ liệu nạp vào
SELECT * FROM DanhMuc
SELECT * FROM SanPham
SELECT * FROM KhachHang
SELECT * FROM ChiTietGioHang
SELECT * FROM GioHang
SELECT * FROM DonHang
SELECT * FROM ChiTietGioHang
-- ================================================================
--   Chức năng 1: Xem danh sách, chi tiết và tìm kiếm/lọc sản phẩm 
-- ================================================================
-- 1.1. Xem danh sách tất cả sản phẩm
SELECT MaSP, TenSP, GiaBan, HinhAnh, SLTonKho 
FROM SanPham;
GO
-- 1.2. Xem chi tiết một sản phẩm cụ thể (Ví dụ MaSP = 1)
SELECT sp.*, dm.TenDM   -- sp.* giúp hiểp thị tất cả cột trong bảng SanPham
-- sp là bí danh / biệt danh giúp phân biệt các cột có tên trường giống nhau, giúp câu lệnh ngắn gọn và rõ ràng hơn khi tham chiếu đến các cột của bảng đó
FROM SanPham sp
INNER JOIN DanhMuc dm ON sp.MaDM = dm.MaDM   
WHERE sp.MaSP = 1; 
GO
-- 1.3. Tìm kiếm sản phẩm theo tên (Từ khóa: 'Áo')
SELECT * 
FROM SanPham 
WHERE TenSP LIKE N'%Áo%';
GO
-- 1.4. Lọc sản phẩm theo khoảng giá (Từ 50,000 đến 200,000) và sắp xếp tăng dần theo giá
SELECT * 
FROM SanPham 
WHERE GiaBan BETWEEN 50000 AND 200000 
ORDER BY GiaBan ASC;
GO
-- 1.5. Lọc sản phẩm theo Danh mục (Ví dụ danh mục MaDM = 1)
SELECT * 
FROM SanPham 
WHERE MaDM = 1;
GO

-- THÊM DỮ LIỆU MẪU CHO KHÁCH HÀNG
SELECT * FROM KhachHang

INSERT INTO KhachHang (HoTen, ĐiaChi, SĐT, Email, MatKhauTK, PhanQuyen) 
VALUES (N'Nguyễn Văn A', N'Quận 1, TP.HCM', '0901234567', 'vana@gmail.com', '123456', 'Customer');
-- KHÔI PHỤC LẠI SAU KHI THỬ NGHIỆM
-- XOÁ DỮ LIỆU + RESET THỨ TỰ MaKH - GIỮ LẠI BẢNG
-- 1. Xóa sạch dữ liệu các bảng liên quan theo đúng thứ tự (Con trước, Cha sau)
DELETE FROM ChiTietGioHang;
DELETE FROM GioHang;
DELETE FROM ChiTietDonHang;
DELETE FROM DonHang;
DELETE FROM KhachHang;
-- 2. Ép bộ đếm IDENTITY của bảng KhachHang quay lại từ đầu (về 0, để lần thêm tiếp theo là 1)
DBCC CHECKIDENT ('KhachHang', RESEED, 0);
GO

-- ================================================================
--   Chức năng 2: Giỏ hàng (Thêm, Xóa, Thay đổi số lượng)
-- ================================================================

-- LƯU Ý :trong SQL Server, cứ có khai báo biến DECLARE @TenBien thì câu lệnh DECLARE 
-- đó phải chạy chung một lượt với các dòng sử dụng biến @TenBien đó, không được bôi đen chạy tách rời từng dòng riêng lẻ nhé!
-- Chú thích thêm biến được khai báo = DECLARE @TenBien sẽ tự xoá sau khi chạy xong lệnh.Nó chỉ tồn tại khi chạy khối lệnh (tính từ lúc khai báo đến GO là 1 khối lệnh)

------------------------------------------------------------------------------------
-- 2.1. Thêm sản phẩm vào giỏ hàng (Nếu đã có sản phẩm đó trong giỏ thì tăng số lượng, nếu chưa thì thêm mới)
--LƯU Ý : phải nạp dữ liệu khách hàng mẫu ở trên vào
-- (Giả sử khách có MaKH = 1, muốn mua sản phẩm MaSP = 2, số lượng = 3)
GO
DECLARE @MaGH INT;                        -- Khai báo biến @MaGH và tìm mã giỏ hàng tương ứng với khách hàng MaKH = 1.
SELECT @MaGH = MaGH FROM GioHang WHERE MaKH = 1;

-- Nếu khách chưa có giỏ hàng thì tạo giỏ hàng mới tự động
IF @MaGH IS NULL
BEGIN
    INSERT INTO GioHang (MaKH) VALUES (1);  -- Tạo giỏ hàng cho khách hàng với MaKH=1
    SET @MaGH = SCOPE_IDENTITY(); -- lấy ra mã giỏ hàng vừa tạo gán vào biến @MaGH bằng hàm SCOPE_IDENTITY().
    --SCOPE_IDENTITY() : Lấy ID tự tăng của bảng GioHang vừa được tạo ra ở câu lệnh INSERT phía trên
END

-- Thêm vào ChiTietGioHang (Thêm hoặc cập nhật sản phẩm vào chi tiết giỏ hàng)
IF EXISTS (SELECT 1 FROM ChiTietGioHang WHERE MaGH = @MaGH AND MaSP = 2) -- Kiểm tra xem sản phẩm MaSP = 2 đã có trong giỏ hàng này chưa
    UPDATE ChiTietGioHang SET SoLuong = SoLuong + 3 WHERE MaGH = @MaGH AND MaSP = 2; -- Nếu đã có: tăng số lượng thêm 3 đơn vị 
ELSE
    INSERT INTO ChiTietGioHang (MaGH, MaSP, SoLuong) VALUES (@MaGH, 2, 3); -- Nếu chưa có: Thêm mới sản phẩm đó vào giỏ với số lượng là 3
GO
-- Kiểm tra dữ liệu sau khi chạy code trên:
SELECT * FROM ChiTietGioHang
SELECT * FROM GioHang
-----------------------------------------------------------------------------------
-- 2.2. Thay đổi số lượng sản phẩm trong giỏ hàng (Cập nhật số lượng thành 5 cho MaSP = 2)
UPDATE ChiTietGioHang 
SET SoLuong = 5 
WHERE MaGH = 1 AND MaSP = 2;

-- 2.3. Xóa một sản phẩm ra khỏi giỏ hàng
DELETE FROM ChiTietGioHang 
WHERE MaGH = 1 AND MaSP = 2;
-- ================================================================
--    Chức năng 3: Kiểm tra tồn kho trước khi đặt hàng
-- ================================================================


-- Kiểm tra xem các sản phẩm trong giỏ hàng của khách (MaKH = 1) có vượt quá số lượng tồn kho hay không?
-- Nếu câu lệnh này trả về dòng dữ liệu nghĩa là kho KHÔNG ĐỦ HÀNG.
SELECT sp.TenSP, ct.SoLuong AS SoLuongMua, sp.SLTonKho AS TonKhoCon
FROM ChiTietGioHang ct
JOIN GioHang gh ON ct.MaGH = gh.MaGH
JOIN SanPham sp ON ct.MaSP = sp.MaSP
WHERE gh.MaKH = 1 AND ct.SoLuong > sp.SLTonKho;

-- Kiểm tra số lượng tồn kho đơn thuần của sản phẩm 
SELECT MaSP,TenSP, SLTonKho
FROM SanPham

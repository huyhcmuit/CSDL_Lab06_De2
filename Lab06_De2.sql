CREATE DATABASE DE2 
CREATE TABLE PHONGBAN (
    MaPhong CHAR(5) PRIMARY KEY,
    TenPhong VARCHAR(25),
    TruongPhong CHAR(5) 
);
CREATE TABLE NHANVIEN (
    MaNV CHAR(5) PRIMARY KEY,
    HoTen VARCHAR(20),
    NgayVL SMALLDATETIME,
    HSLuong NUMERIC(4,2),
    MaPhong CHAR(5),
    FOREIGN KEY (MaPhong) REFERENCES PHONGBAN(MaPhong)
);
ALTER TABLE PHONGBAN
ADD CONSTRAINT FK_TruongPhong FOREIGN KEY (TruongPhong) REFERENCES NHANVIEN(MaNV);

CREATE TABLE XE (
    MaXe CHAR(5) PRIMARY KEY,
    LoaiXe VARCHAR(20),
    SoChoNgoi INT,
    NamSX INT
);

CREATE TABLE PHANCONG (
    MaPC CHAR(5) PRIMARY KEY,
    MaNV CHAR(5),
    MaXe CHAR(5),
    NgayDi SMALLDATETIME,
    NgayVe SMALLDATETIME,
    NoiDen VARCHAR(25),
    FOREIGN KEY (MaNV) REFERENCES NHANVIEN(MaNV),
    FOREIGN KEY (MaXe) REFERENCES XE(MaXe)
);
-- 2. 
-- 2.1.
GO
CREATE TRIGGER TR_NamSX_Toyota
ON XE
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED
        WHERE LoaiXe = 'Toyota' AND NamSX < 2006
    )
    BEGIN
        ROLLBACK;
        THROW 50001, 'Xe loai Toyota phai co nam san xuat tu 2006 tro ve sau.', 1;
    END
END;
GO
-- 2.2.
GO
CREATE TRIGGER TR_PhanCong_NgoaiThanh
ON PHANCONG
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        JOIN NHANVIEN N ON I.MaNV = N.MaNV
        JOIN PHONGBAN P ON N.MaPhong = P.MaPhong
        JOIN XE X ON I.MaXe = X.MaXe
        WHERE P.TenPhong = 'Ngoai thanh' AND X.LoaiXe <> 'Toyota'
    )
    BEGIN
        ROLLBACK;
        THROW 50002, 'Nhan vien phong Ngoai thanh chi duoc lai xe loai Toyota.', 1;
    END
END;
GO
-- 3. 
-- 3.1. 
SELECT DISTINCT N.MaNV, N.HoTen
FROM NHANVIEN N
JOIN PHONGBAN P ON N.MaPhong = P.MaPhong
JOIN PHANCONG PC ON N.MaNV = PC.MaNV
JOIN XE X ON PC.MaXe = X.MaXe
WHERE P.TenPhong = 'Noi thanh' AND X.LoaiXe = 'Toyota' AND X.SoChoNgoi = 4;

-- 3.2. 
SELECT N.MaNV, N.HoTen
FROM NHANVIEN N
JOIN PHONGBAN P ON N.MaNV = P.TruongPhong
WHERE NOT EXISTS (
    SELECT X.LoaiXe
    FROM XE X
    WHERE NOT EXISTS (
        SELECT 1
        FROM PHANCONG PC
        WHERE PC.MaNV = N.MaNV AND PC.MaXe = X.MaXe
    )
);

-- 3.3.
WITH PhongBan_Toyota AS (
    SELECT N.MaNV, N.HoTen, P.MaPhong, COUNT(DISTINCT PC.MaXe) AS SoLanLaiToyota
    FROM NHANVIEN N
    JOIN PHONGBAN P ON N.MaPhong = P.MaPhong
    JOIN PHANCONG PC ON N.MaNV = PC.MaNV
    JOIN XE X ON PC.MaXe = X.MaXe
    WHERE X.LoaiXe = 'Toyota'
    GROUP BY N.MaNV, N.HoTen, P.MaPhong
),
MinLaiToyota AS (
    SELECT MaPhong, MIN(SoLanLaiToyota) AS MinSoLan
    FROM PhongBan_Toyota
    GROUP BY MaPhong
)
SELECT PB.MaNV, PB.HoTen, PB.MaPhong, PB.SoLanLaiToyota
FROM PhongBan_Toyota PB
JOIN MinLaiToyota ML ON PB.MaPhong = ML.MaPhong AND PB.SoLanLaiToyota = ML.MinSoLan;

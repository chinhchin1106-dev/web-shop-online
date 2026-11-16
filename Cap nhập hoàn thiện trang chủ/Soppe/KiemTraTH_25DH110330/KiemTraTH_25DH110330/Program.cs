using System;
using System.Text;

namespace KiemTraTH_25DH110330
{
    internal class Program
    {
        static void Main(string[] args)
        {
            Console.OutputEncoding = Encoding.UTF8;

            Console.Write("Chọn câu cần chạy (1-4): ");
            string chon = Console.ReadLine() ?? "";

            switch (chon)
            {
                case "1":
                    TestCau1();
                    break;
                case "2":
                    TestCau2();
                    break;
                case "3":
                    TestCau3();
                    break;
                case "4":
                    TestCau4();
                    break;
                default:
                    Console.WriteLine("Chọn số từ 1 đến 4.");
                    break;
            }

            Console.WriteLine("\nNhấn phím bất kỳ để kết thúc.");
            Console.ReadKey();
        }

        static void TestCau1()
        {
            IntArray m = new IntArray(
                new int[] { 3, 8, 12, 15, 21, 27, 34, 40 });

            Console.WriteLine("CÂU 1 - TÌM NHỊ PHÂN");
            Console.Write("Mảng M: ");
            m.Show();

            Console.WriteLine("Tìm 27: " + m.TimNhiPhan(27));
            Console.WriteLine("Tìm 10: " + m.TimNhiPhan(10));
            Console.WriteLine("Tìm 40: " + m.TimNhiPhan(40));

            IntArray motPhanTu = new IntArray(new int[] { 7 });
            Console.WriteLine(
                "Mảng {7}, tìm 7: " + motPhanTu.TimNhiPhan(7));

            IntArray d = new IntArray(
                new int[] { 2, 4, 4, 4, 7, 9, 9, 12 });

            Console.WriteLine("\nĐẾM SỐ LẦN XUẤT HIỆN");

            foreach (int x in new int[] { 4, 9, 5 })
                Console.WriteLine(
                    x + " xuất hiện " + d.DemXuatHien(x) + " lần");
        }

        static void TestCau2()
        {
            int[] t = { 6, 3, 8, 2, 9, 1 };

            Console.WriteLine("SELECTION SORT");
            new IntArray(t).SelectionSort(true);

            Console.WriteLine("\nINSERTION SORT");
            int dichChuyen = new IntArray(t).InsertionSort(true);
            Console.WriteLine("Số dịch chuyển: " + dichChuyen);

            Console.WriteLine("\nSẮP XẾP CHẴN LẺ");
            IntArray c = new IntArray(
                new int[] { 15, 8, 3, 22, 7, 10, 9, 4 });

            c.SapXepChanLe();
            c.Show();

            Console.WriteLine("\nĐẾM SO SÁNH");
            ThongKe("Ngẫu nhiên",
                new int[] { 6, 3, 8, 2, 9, 1, 10, 5, 7, 4 });

            ThongKe("Đã tăng",
                new int[] { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 });

            ThongKe("Giảm dần",
                new int[] { 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 });
        }

        static void ThongKe(string ten, int[] a)
        {
            // Hai đối tượng có hai bản sao độc lập.
            int bubble = new IntArray(a).BubbleSort();
            int selection = new IntArray(a).SelectionSort();

            Console.WriteLine(
                ten + ": Bubble = " + bubble +
                ", Selection = " + selection);
        }

        static MyList TaoList(int[] a)
        {
            MyList ds = new MyList();

            foreach (int x in a)
                ds.AddLast(x);

            return ds;
        }

        static void TestCau3()
        {
            Console.WriteLine("CÂU 3a - BẢN LỖI");
            MyList sai = TaoList(new int[] { 4, 7, 9, 12 });

            sai.RemoveXSai(12);
            sai.ShowList();
            sai.ShowFirstLast();

            sai.AddLast(20);
            sai.ShowList();
            sai.ShowFirstLast();

            Console.WriteLine("\nCÂU 3a - ĐÃ SỬA");
            MyList dung = TaoList(new int[] { 4, 7, 9, 12 });

            dung.RemoveX(12);
            dung.ShowFirstLast();
            dung.AddLast(20);
            dung.ShowList();
            dung.ShowFirstLast();

            Console.WriteLine("\nCÂU 3b");
            MyList ds = TaoList(new int[] { 5, 2, 5, 5, 8, 2, 5 });

            Console.WriteLine("Số node xóa: " + ds.RemoveAllX(5));
            ds.ShowList();

            ds.AddLast(100);
            ds.ShowList();
            ds.ShowFirstLast();

            Console.WriteLine("\nCÂU 3c");
            ds.Reverse();
            ds.ShowList();
            ds.ShowFirstLast();

            Console.WriteLine("\nTHỬ XÓA TẤT CẢ NODE");
            MyList tatCa = TaoList(new int[] { 5, 5, 5 });
            Console.WriteLine("Số node xóa: " + tatCa.RemoveAllX(5));
            tatCa.ShowFirstLast();
            tatCa.AddLast(100);
            tatCa.ShowList();

            Console.WriteLine("\nTHỬ DANH SÁCH RỖNG");
            MyList rong = new MyList();
            Console.WriteLine("Số node xóa: " + rong.RemoveAllX(5));
            rong.Reverse();
            rong.ShowFirstLast();

            Console.WriteLine("\nTHỬ XÓA NODE DUY NHẤT");
            MyList don = TaoList(new int[] { 5 });
            don.RemoveX(5);
            don.ShowFirstLast();
            don.AddLast(100);
            don.ShowList();
        }

        // Câu 4a: sắp xếp bản sao, sau đó bỏ giá trị trùng.
        static MyList TaoDanhSachTangKhongTrung(IntArray a)
        {
            IntArray b = new IntArray(a.CopyArray());
            b.InsertionSort();

            MyList ds = new MyList();

            for (int i = 0; i < b.Length; i++)
            {
                if (i == 0 || b[i] != b[i - 1])
                    ds.AddLast(b[i]);
            }

            return ds;
        }

        static void TestCau4()
        {
            KiemTraCau4(new int[] { 9, 4, 7, 4, 1, 9, 6 });
            KiemTraCau4(new int[] { 7, 7, 7 });
            KiemTraCau4(new int[] { 1, 3, 5, 8 });
        }

        static void KiemTraCau4(int[] duLieu)
        {
            IntArray a = new IntArray(duLieu);

            Console.Write("\nMảng nguồn trước: ");
            a.Show();

            MyList ds = TaoDanhSachTangKhongTrung(a);

            Console.Write("Danh sách kết quả: ");
            ds.ShowList();

            Console.Write("Mảng nguồn sau: ");
            a.Show();
        }
    }
}
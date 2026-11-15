using System;

namespace KiemTraTH_25DH110330
{
    internal class IntArray
    {
        private int[] arr;

        public int Length
        {
            get { return arr.Length; }
        }

        public int this[int i]
        {
            get { return arr[i]; }
        }

        public IntArray(int[] a)
        {
            arr = new int[a.Length];

            for (int i = 0; i < a.Length; i++)
                arr[i] = a[i];
        }

        public int[] CopyArray()
        {
            int[] copy = new int[arr.Length];

            for (int i = 0; i < arr.Length; i++)
                copy[i] = arr[i];

            return copy;
        }

        public void Show()
        {
            Console.WriteLine(string.Join(" ", arr));
        }
        public int TimNhiPhan(int x)
        {
            int low = 0;
            int high = arr.Length - 1;

            while (low <= high)
            {
                int mid = low + (high - low) / 2;

                if (arr[mid] == x)
                    return mid;

                if (arr[mid] < x)
                    low = mid + 1;
                else
                    high = mid - 1;
            }

            return -1;
        }

        private int TimBien(int x, bool timDau)
        {
            int low = 0;
            int high = arr.Length - 1;
            int ketQua = -1;

            while (low <= high)
            {
                int mid = low + (high - low) / 2;

                if (arr[mid] == x)
                {
                    ketQua = mid;

                    if (timDau)
                        high = mid - 1;
                    else
                        low = mid + 1;
                }
                else if (arr[mid] < x)
                    low = mid + 1;
                else
                    high = mid - 1;
            }

            return ketQua;
        }

        public int DemXuatHien(int x)
        {
            int dau = TimBien(x, true);

            if (dau == -1)
                return 0;

            int cuoi = TimBien(x, false);
            return cuoi - dau + 1;
        }

        private void HoanVi(int i, int j)
        {
            int temp = arr[i];
            arr[i] = arr[j];
            arr[j] = temp;
        }

        // Trả về số phép so sánh giữa các phần tử.
        public int SelectionSort(bool inTungLuot = false)
        {
            int soSanh = 0;
            int hoanVi = 0;

            for (int i = 0; i < arr.Length - 1; i++)
            {
                int min = i;

                for (int j = i + 1; j < arr.Length; j++)
                {
                    soSanh++;

                    if (arr[j] < arr[min])
                        min = j;
                }

                if (min != i)
                {
                    HoanVi(i, min);
                    hoanVi++;
                }

                if (inTungLuot)
                {
                    Console.Write("Lượt " + (i + 1) + ": ");
                    Show();
                }
            }

            if (inTungLuot)
                Console.WriteLine("Số hoán vị: " + hoanVi);

            return soSanh;
        }

        // Trả về số lần thực hiện arr[j + 1] = arr[j].
        public int InsertionSort(bool inTungLuot = false)
        {
            int dichChuyen = 0;

            for (int i = 1; i < arr.Length; i++)
            {
                int key = arr[i];
                int j = i - 1;

                while (j >= 0 && arr[j] > key)
                {
                    arr[j + 1] = arr[j];
                    dichChuyen++;
                    j--;
                }

                arr[j + 1] = key;

                if (inTungLuot)
                {
                    Console.Write("Lượt " + i + ": ");
                    Show();
                }
            }

            return dichChuyen;
        }

        public int BubbleSort()
        {
            int soSanh = 0;

            for (int i = 0; i < arr.Length - 1; i++)
            {
                bool daHoanVi = false;

                for (int j = 0; j < arr.Length - 1 - i; j++)
                {
                    soSanh++;

                    if (arr[j] > arr[j + 1])
                    {
                        HoanVi(j, j + 1);
                        daHoanVi = true;
                    }
                }

                if (!daHoanVi)
                    break;
            }

            return soSanh;
        }

        
        private bool DungTruoc(int a, int b)
        {
            bool aChan = a % 2 == 0;
            bool bChan = b % 2 == 0;

            if (aChan != bChan)
                return aChan;

            if (aChan)
                return a < b;

            return a > b;
        }

        
        public void SapXepChanLe()
        {
            for (int i = 0; i < arr.Length - 1; i++)
            {
                int viTri = i;

                for (int j = i + 1; j < arr.Length; j++)
                {
                    if (DungTruoc(arr[j], arr[viTri]))
                        viTri = j;
                }

                if (viTri != i)
                    HoanVi(i, viTri);
            }
        }
    }
}
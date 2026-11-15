using System;
using System.Collections.Generic;
using System.Diagnostics.Contracts;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace KiemTraTH_25DH110330
{
    internal class MyList
    {
        private IntNode first;
        private IntNode last;

        public bool IsEmpty()
        {
            return first == null;
        }

        public void AddLast(int data)
        {
            IntNode Node = new IntNode(data);
            if (IsEmpty())
            {
                first = Node;
                last = Node;
            }
            else
            {
                last.Next = Node;
                last = Node;
            }
        }

        public void ShowList()
        {
            IntNode p = first;
            while (p != null)
            {
                Console.Write(p.Data);

                if (p.Next != null)
                    Console.Write(" -> ");
                p = p.Next;
            }
            Console.WriteLine();
        }

        public void ShowFirstLast()
        {
            Console.WriteLine(
               "first = " + GiaTri(first) +
                ", last = " + GiaTri(last));

        }

        private string GiaTri(IntNode p)
        {
            return p == null ? "null" : p.Data.ToString();
        }

        public bool RemoveXSai(int x)
        {
            if (IsEmpty())
                return false;

            if (first.Data == x)
            {
                first = first.Next;
                return true;
            }

            IntNode p = first;

            while (p.Next != null && p.Next.Data != x)
                p = p.Next;

            if (p.Next == null)
                return false;

            p.Next = p.Next.Next;
            return true;
        }
        public bool RemoveX(int x)
        {
            if (IsEmpty())
                return false;

            if (first.Data == x)
            {
                first = first.Next;

                if (first == null)
                    last = null;

                return true;
            }

            IntNode p = first;

            while (p.Next != null && p.Next.Data != x)
                p = p.Next;

            if (p.Next == null)
                return false;

            if (p.Next == last)
                last = p;

            p.Next = p.Next.Next;
            return true;
        }
        public int RemoveAllX(int x)
        {
            int dem = 0;

            while (first != null && first.Data == x)
            {
                first = first.Next;
                dem++;
            }
            if (first == null)
            {
                last = null;
                return dem;
            }

            IntNode p = first;

            while (p.Next != null)
            {
                if (p.Next.Data == x)
                {
                    p.Next = p.Next.Next;
                    dem++;
                }
                else
                {
                    p = p.Next;
                }
            }

            last = p;
            return dem;
        }
        public void Reverse()
        {
            IntNode prev = null;
            IntNode cur = first;
            IntNode next = null;

            last = first;
            int vong = 0;

            while (cur != null)
            {
                next = cur.Next;
                cur.Next = prev;
                prev = cur;
                cur = next;

                vong++;

                Console.WriteLine(
                    "Vòng " + vong +
                    ": prev = " + GiaTri(prev) +
                    ", cur = " + GiaTri(cur) +
                    ", next = " + GiaTri(next));
            }

            first = prev;
        }

    }
}



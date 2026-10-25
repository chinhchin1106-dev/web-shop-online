
document.addEventListener('DOMContentLoaded', function () {
    'use strict';

    const tableBody = document.getElementById('cartPageRows');
    if (!tableBody) return;

    const CART_KEY = 'soppe_cart';
    const selectAll = document.getElementById('cartPageSelectAll');
    const emptyState = document.getElementById('cartPageEmpty');
    const bottom = document.getElementById('cartPageBottom');
    const summaryCount = document.getElementById('cartPageSummaryCount');
    const selectedCount = document.getElementById('cartPageSelectedCount');
    const subtotal = document.getElementById('cartPageSubtotal');
    const grandTotal = document.getElementById('cartPageGrandTotal');
    const checkout = document.getElementById('cartPageCheckout');
    const removeSelected = document.getElementById('cartPageRemoveSelected');
    const formatter = new Intl.NumberFormat('vi-VN');
    const money = (n) => formatter.format(n || 0) + 'đ';

    function notify(message) {
        let toast = document.getElementById('soppeToast');
        if (!toast) {
            toast = document.createElement('div');
            toast.id = 'soppeToast';
            toast.className = 'sp-toast';
            toast.setAttribute('role', 'status');
            document.body.appendChild(toast);
        }
        toast.textContent = message;
        toast.hidden = false;
        clearTimeout(notify.timer);
        notify.timer = setTimeout(function () { toast.hidden = true; }, 2700);
    }

    function loadCart() {
        try {
            const raw = JSON.parse(localStorage.getItem(CART_KEY) || '[]');
            if (!Array.isArray(raw)) return [];
            return raw.map(function (item) {
                return {
                    id: String(item.id || '').trim(),
                    name: String(item.name || '').trim(),
                    price: Number(item.price),
                    quantity: Math.floor(Number(item.quantity)),
                    image: String(item.image || '')
                };
            }).filter(function (item) {
                return item.id && item.name && Number.isFinite(item.price) && item.price >= 0 &&
                    Number.isFinite(item.quantity) && item.quantity > 0;
            });
        } catch (error) {
            console.warn('Sộp Pe: không đọc được giỏ hàng', error);
            return [];
        }
    }

    let cart = loadCart();
    let selectedIds = new Set(cart.map(function (item) { return item.id; }));

    function saveCart() {
        try {
            localStorage.setItem(CART_KEY, JSON.stringify(cart));
        } catch (error) {
            console.warn('Không lưu được giỏ hàng:', error);
            notify('Không thể lưu giỏ hàng trên trình duyệt này.');
        }
        render();
        
        const headerCount = document.getElementById('headerCartCount');
        if (headerCount) {
            const quantity = cart.reduce(function (sum, item) { return sum + item.quantity; }, 0);
            headerCount.textContent = String(quantity);
            headerCount.hidden = quantity === 0;
        }
    }

    function makeButton(action, id, symbol, ariaLabel) {
        const button = document.createElement('button');
        button.type = 'button';
        button.dataset.cartPageAction = action;
        button.dataset.cartPageId = id;
        button.textContent = symbol;
        button.setAttribute('aria-label', ariaLabel);
        return button;
    }

    function makeCell(text, className) {
        const cell = document.createElement('td');
        if (className) cell.className = className;
        cell.textContent = text;
        return cell;
    }

    function render() {
        tableBody.replaceChildren();
        const hasProducts = cart.length > 0;
        emptyState.hidden = hasProducts;
        bottom.hidden = !hasProducts;
        if (selectAll) {
            const selectedProducts = cart.filter(function (item) { return selectedIds.has(item.id); });
            selectAll.checked = hasProducts && selectedProducts.length === cart.length;
            selectAll.indeterminate = selectedProducts.length > 0 && selectedProducts.length < cart.length;
            selectAll.disabled = !hasProducts;
        }

        cart.forEach(function (item) {
            const row = document.createElement('tr');
            const checkCell = document.createElement('td');
            const check = document.createElement('input');
            check.type = 'checkbox';
            check.checked = selectedIds.has(item.id);
            check.dataset.cartPageSelect = item.id;
            check.setAttribute('aria-label', 'Chọn ' + item.name);
            checkCell.appendChild(check);

            const productCell = document.createElement('td');
            const productBox = document.createElement('div');
            productBox.className = 'sp-cart-v2-product';
            const imageHolder = document.createElement('div');
            imageHolder.className = 'sp-cart-v2-image';
            const emoji = document.createElement('span');
            emoji.textContent = '🛍️';
            emoji.setAttribute('aria-hidden', 'true');
            imageHolder.appendChild(emoji);
            if (item.image) {
                const img = document.createElement('img');
                img.alt = '';
                img.src = item.image;
                img.loading = 'lazy';
                img.addEventListener('error', function () { img.remove(); });
                imageHolder.appendChild(img);
            }
            const info = document.createElement('div');
            const name = document.createElement('strong');
            name.textContent = item.name;
            const code = document.createElement('small');
            code.textContent = 'Mã: ' + item.id;
            info.append(name, code);
            productBox.append(imageHolder, info);
            productCell.appendChild(productBox);

            const quantityCell = document.createElement('td');
            const quantityBox = document.createElement('div');
            quantityBox.className = 'sp-cart-v2-qty';
            const minus = makeButton('decrease', item.id, '−', 'Giảm số lượng ' + item.name);
            const value = document.createElement('span');
            value.textContent = String(item.quantity);
            const plus = makeButton('increase', item.id, '+', 'Tăng số lượng ' + item.name);
            quantityBox.append(minus, value, plus);
            quantityCell.appendChild(quantityBox);

            const actionCell = document.createElement('td');
            const remove = makeButton('remove', item.id, 'Xóa', 'Xóa ' + item.name);
            remove.className = 'sp-cart-v2-remove';
            actionCell.appendChild(remove);

            row.append(
                checkCell,
                productCell,
                makeCell(money(item.price), 'sp-cart-v2-price'),
                quantityCell,
                makeCell(money(item.price * item.quantity), 'sp-cart-v2-line-total'),
                actionCell
            );
            tableBody.appendChild(row);
        });

        const checkedItems = cart.filter(function (item) { return selectedIds.has(item.id); });
        const count = checkedItems.reduce(function (sum, item) { return sum + item.quantity; }, 0);
        const sum = checkedItems.reduce(function (acc, item) { return acc + item.price * item.quantity; }, 0);
        summaryCount.textContent = String(count);
        selectedCount.textContent = String(checkedItems.length);
        subtotal.textContent = money(sum);
        grandTotal.textContent = money(sum);
    }

    tableBody.addEventListener('change', function (event) {
        const check = event.target.closest('[data-cart-page-select]');
        if (!check) return;
        if (check.checked) selectedIds.add(check.dataset.cartPageSelect);
        else selectedIds.delete(check.dataset.cartPageSelect);
        render();
    });

    if (selectAll) selectAll.addEventListener('change', function () {
        selectedIds = new Set(selectAll.checked ? cart.map(function (item) { return item.id; }) : []);
        render();
    });

    tableBody.addEventListener('click', function (event) {
        const button = event.target.closest('[data-cart-page-action]');
        if (!button) return;
        const item = cart.find(function (p) { return p.id === button.dataset.cartPageId; });
        if (!item) return;
        if (button.dataset.cartPageAction === 'increase') item.quantity += 1;
        else if (button.dataset.cartPageAction === 'decrease') item.quantity -= 1;
        else if (button.dataset.cartPageAction === 'remove') item.quantity = 0;
        else return;
        if (item.quantity <= 0) selectedIds.delete(item.id);
        cart = cart.filter(function (p) { return p.quantity > 0; });
        saveCart();
    });

    if (removeSelected) removeSelected.addEventListener('click', function () {
        if (selectedIds.size === 0) { notify('Bạn chưa chọn sản phẩm để xóa.'); return; }
        if (!window.confirm('Xóa các sản phẩm đã chọn khỏi giỏ hàng?')) return;
        cart = cart.filter(function (item) { return !selectedIds.has(item.id); });
        selectedIds.clear();
        saveCart();
        notify('Đã xóa những sản phẩm đã chọn.');
    });

    if (checkout) checkout.addEventListener('click', function () {
        const count = cart.filter(function (item) { return selectedIds.has(item.id); }).length;
        if (count === 0) { notify(cart.length ? 'Hãy chọn sản phẩm để đặt hàng.' : 'Giỏ hàng đang trống.'); return; }
        notify('Đặt hàng đang ở chế độ demo. Cần kết nối Controller và SQL Server để xử lý đơn.');
    });

    window.addEventListener('storage', function (event) {
        if (event.key !== CART_KEY) return;
        cart = loadCart();
        selectedIds = new Set(cart.map(function (item) { return item.id; }));
        render();
    });

    render();
});

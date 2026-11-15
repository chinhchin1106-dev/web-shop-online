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

    if (!selectAll || !emptyState || !bottom ||
        !summaryCount || !selectedCount || !subtotal ||
        !grandTotal || !checkout || !removeSelected) {
        console.error('Giohang.cshtml đang thiếu phần tử của giỏ hàng.');
        return;
    }

    const formatter = new Intl.NumberFormat('vi-VN');

    let cart = [];
    let selectedIds = new Set();
    let readFailed = false;

    function money(value) {
        return formatter.format(value) + 'đ';
    }

    function notify(message) {
        let box = document.getElementById('cartPageMessage');

        if (!box) {
            box = document.createElement('p');
            box.id = 'cartPageMessage';
            box.setAttribute('role', 'status');
            checkout.parentNode.insertBefore(box, checkout);
        }

        box.textContent = message;
    }

    function loadCart() {
        try {
            const data = JSON.parse(
                localStorage.getItem(CART_KEY) || '[]'
            );

            if (!Array.isArray(data)) {
                throw new Error('Dữ liệu giỏ hàng phải là danh sách.');
            }

            const ids = new Set();

            const result = data.map(function (item) {
                if (!item || typeof item !== 'object') {
                    throw new Error('Dòng sản phẩm không hợp lệ.');
                }

                const id = String(item.id == null ? '' : item.id).trim();
                const name = String(item.name || '').trim();
                const price = Number(item.price);
                const quantity = Number(item.quantity);

                if (!id || !name || ids.has(id) ||
                    !Number.isFinite(price) || price < 0 ||
                    !Number.isSafeInteger(quantity) || quantity < 1 ||
                    !Number.isFinite(price * quantity)) {
                    throw new Error('Thông tin sản phẩm không hợp lệ.');
                }

                ids.add(id);

                return {
                    id: id,
                    name: name,
                    price: price,
                    quantity: quantity,
                    image: String(item.image || '')
                };
            });

            readFailed = false;
            return result;
        } catch (error) {
            readFailed = true;
            console.error('Không đọc được giỏ hàng:', error);

            notify(
                'Không đọc được giỏ hàng. Dữ liệu đã lưu chưa bị xóa. ' +
                'Hãy kiểm tra lại chức năng thêm sản phẩm.'
            );

            return [];
        }
    }

    function updateHeader() {
        const badge = document.getElementById('headerCartCount');
        if (!badge) return;

        const count = cart.reduce(function (sum, item) {
            return sum + item.quantity;
        }, 0);

        badge.textContent = String(count);
        badge.hidden = count === 0;
    }

    function saveCart(nextCart) {
        try {
            localStorage.setItem(CART_KEY, JSON.stringify(nextCart));
        } catch (error) {
            console.error('Không lưu được giỏ hàng:', error);
            notify('Không thể lưu thay đổi. Vui lòng thử lại.');
            return false;
        }

        cart = nextCart;

        selectedIds = new Set(
            cart.filter(function (item) {
                return selectedIds.has(item.id);
            }).map(function (item) {
                return item.id;
            })
        );

        render();
        return true;
    }

    function makeCell(text, className) {
        const cell = document.createElement('td');
        cell.textContent = text;

        if (className) {
            cell.className = className;
        }

        return cell;
    }

    function makeButton(action, item, text, label) {
        const button = document.createElement('button');

        button.type = 'button';
        button.textContent = text;
        button.dataset.cartAction = action;
        button.dataset.cartId = item.id;
        button.setAttribute('aria-label', label + ' ' + item.name);

        return button;
    }

    function render() {
        tableBody.textContent = '';

        const hasProducts = cart.length > 0;

        emptyState.hidden = hasProducts || readFailed;
        bottom.hidden = !hasProducts;

        cart.forEach(function (item) {
            const row = document.createElement('tr');

            // Cột chọn sản phẩm.
            const checkCell = document.createElement('td');
            const check = document.createElement('input');

            check.type = 'checkbox';
            check.checked = selectedIds.has(item.id);
            check.dataset.cartSelect = item.id;
            check.setAttribute('aria-label', 'Chọn ' + item.name);
            checkCell.appendChild(check);

            // Cột thông tin sản phẩm.
            const productCell = document.createElement('td');
            const productBox = document.createElement('div');
            productBox.className = 'sp-cart-v2-product';

            const imageBox = document.createElement('div');
            imageBox.className = 'sp-cart-v2-image';

            const fallback = document.createElement('span');
            fallback.textContent = '🛍️';
            fallback.setAttribute('aria-hidden', 'true');
            imageBox.appendChild(fallback);

            if (item.image) {
                try {
                    const imageUrl = new URL(item.image, document.baseURI);

                    if (imageUrl.protocol === 'http:' ||
                        imageUrl.protocol === 'https:') {
                        const img = document.createElement('img');

                        img.src = imageUrl.href;
                        img.alt = '';
                        img.loading = 'lazy';

                        img.addEventListener('error', function () {
                            img.remove();
                        });

                        imageBox.appendChild(img);
                    }
                } catch (error) {
                    // Giữ biểu tượng mặc định khi đường dẫn ảnh không hợp lệ.
                }
            }

            const info = document.createElement('div');
            const name = document.createElement('strong');
            const code = document.createElement('small');

            name.textContent = item.name;
            code.textContent = 'Mã: ' + item.id;

            info.append(name, code);
            productBox.append(imageBox, info);
            productCell.appendChild(productBox);

            // Cột số lượng.
            const quantityCell = document.createElement('td');
            const quantityBox = document.createElement('div');
            quantityBox.className = 'sp-cart-v2-qty';

            const minus = makeButton(
                'decrease', item, '−', 'Giảm số lượng'
            );

            const plus = makeButton(
                'increase', item, '+', 'Tăng số lượng'
            );

            minus.disabled = item.quantity <= 1;
            plus.disabled = item.quantity >= 99;

            const value = document.createElement('span');
            value.textContent = String(item.quantity);

            quantityBox.append(minus, value, plus);
            quantityCell.appendChild(quantityBox);

            // Cột xóa.
            const actionCell = document.createElement('td');
            const remove = makeButton(
                'remove', item, 'Xóa', 'Xóa sản phẩm'
            );

            remove.className = 'sp-cart-v2-remove';
            actionCell.appendChild(remove);

            row.append(
                checkCell,
                productCell,
                makeCell(money(item.price), 'sp-cart-v2-price'),
                quantityCell,
                makeCell(
                    money(item.price * item.quantity),
                    'sp-cart-v2-line-total'
                ),
                actionCell
            );

            tableBody.appendChild(row);
        });

        const chosen = cart.filter(function (item) {
            return selectedIds.has(item.id);
        });

        const count = chosen.reduce(function (sum, item) {
            return sum + item.quantity;
        }, 0);

        const total = chosen.reduce(function (sum, item) {
            return sum + item.price * item.quantity;
        }, 0);

        summaryCount.textContent = String(count);
        selectedCount.textContent = String(chosen.length);

        subtotal.textContent = money(total);
        grandTotal.textContent = money(total);

        selectAll.checked =
            hasProducts && chosen.length === cart.length;

        selectAll.indeterminate =
            chosen.length > 0 && chosen.length < cart.length;

        selectAll.disabled = !hasProducts;
        removeSelected.disabled = chosen.length === 0;
        checkout.disabled = chosen.length === 0 || readFailed;

        updateHeader();

        document.dispatchEvent(new CustomEvent('soppe:cart-changed', {
            detail: {
                subtotal: total,
                selectedCount: chosen.length,
                readFailed: readFailed
            }
        }));
    }

    tableBody.addEventListener('change', function (event) {
        if (!(event.target instanceof HTMLInputElement)) return;

        const check = event.target;
        const id = check.dataset.cartSelect;

        if (!id) return;

        if (check.checked) {
            selectedIds.add(id);
        } else {
            selectedIds.delete(id);
        }

        render();
    });

    selectAll.addEventListener('change', function () {
        selectedIds = new Set(
            selectAll.checked
                ? cart.map(function (item) { return item.id; })
                : []
        );

        render();
    });

    tableBody.addEventListener('click', function (event) {
        if (!(event.target instanceof Element)) return;

        const button = event.target.closest('button[data-cart-action]');
        if (!button) return;

        const id = button.dataset.cartId;
        const action = button.dataset.cartAction;

        const item = cart.find(function (p) {
            return p.id === id;
        });

        if (!item) return;

        if (action === 'remove') {
            saveCart(cart.filter(function (p) {
                return p.id !== id;
            }));
            return;
        }

        if (action !== 'increase' && action !== 'decrease') return;

        const nextQuantity = item.quantity +
            (action === 'increase' ? 1 : -1);

        if (nextQuantity < 1 || nextQuantity > 99) {
            notify('Số lượng mỗi sản phẩm từ 1 đến 99.');
            return;
        }

        const nextCart = cart.map(function (p) {
            if (p.id !== id) return p;

            return {
                id: p.id,
                name: p.name,
                price: p.price,
                quantity: nextQuantity,
                image: p.image
            };
        });

        saveCart(nextCart);
    });

    removeSelected.addEventListener('click', function () {
        if (selectedIds.size === 0) {
            notify('Bạn chưa chọn sản phẩm để xóa.');
            return;
        }

        if (!window.confirm('Xóa các sản phẩm đã chọn?')) return;

        const nextCart = cart.filter(function (item) {
            return !selectedIds.has(item.id);
        });

        if (saveCart(nextCart)) {
            notify('Đã xóa các sản phẩm đã chọn.');
        }
    });

    checkout.addEventListener('click', function () {
        const chosen = cart.filter(function (item) {
            return selectedIds.has(item.id);
        });

        if (chosen.length === 0) {
            notify('Hãy chọn sản phẩm để đặt hàng.');
            return;
        }

        if (chosen.length > 50) {
            notify('Mỗi đơn tối đa 50 dòng sản phẩm.');
            return;
        }

        const lines = [];

        for (const item of chosen) {
            const id = Number(item.id);
            const quantity = item.quantity;

            if (!Number.isSafeInteger(id) || id <= 0 ||
                id > 2147483647 ||
                !Number.isInteger(quantity) ||
                quantity < 1 || quantity > 99) {
                notify('Mã sản phẩm hoặc số lượng không hợp lệ.');
                return;
            }

            // Chỉ gửi mã và số lượng.
            // Giá sẽ được Controller/Service lấy lại từ máy chủ.
            lines.push({
                Id: id,
                Quantity: quantity
            });
        }

        const form = document.getElementById('spCheckoutForm');
        const input = document.getElementById('spCheckoutItems');

        if (!(form instanceof HTMLFormElement) ||
            !(input instanceof HTMLInputElement)) {
            notify('Thiếu form đặt hàng trong Giohang.cshtml.');
            return;
        }

        input.value = JSON.stringify(lines);
        checkout.disabled = true;
        form.submit();
    });

    function refresh() {
        cart = loadCart();

        selectedIds = new Set(cart.map(function (item) {
            return item.id;
        }));

        render();
    }

    window.addEventListener('storage', function (event) {
        if (event.key === CART_KEY || event.key === null) {
            refresh();
        }
    });

    window.addEventListener('pageshow', function (event) {
        if (event.persisted) {
            refresh();
        }
    });

    refresh();
});
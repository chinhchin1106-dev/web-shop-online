document.addEventListener('DOMContentLoaded', function () {
    'use strict';

    const dialog = document.getElementById('cartVoucherDialog');
    if (!(dialog instanceof HTMLDialogElement)) return;

    const openButton = document.getElementById('cartVoucherOpen');
    const closeButton = document.getElementById('cartVoucherClose');
    const cancelButton = document.getElementById('cartVoucherCancel');
    const applyButton = document.getElementById('cartVoucherApply');
    const removeButton = document.getElementById('cartVoucherRemove');
    const checkButton = document.getElementById('cartVoucherCheck');
    const codeInput = document.getElementById('cartVoucherInput');
    const couponInput = document.getElementById('spCheckoutCoupon');

    const list = document.getElementById('cartVoucherList');
    const message = document.getElementById('cartVoucherMessage');
    const status = document.getElementById('cartVoucherStatus');
    const discountBox = document.getElementById('cartPageDiscount');
    const totalBox = document.getElementById('cartPageGrandTotal');

    if (!openButton || !closeButton || !cancelButton ||
        !applyButton || !removeButton || !checkButton ||
        !(codeInput instanceof HTMLInputElement) ||
        !(couponInput instanceof HTMLInputElement) ||
        !list || !message || !status || !discountBox || !totalBox) {
        console.error('Giỏ hàng thiếu thành phần chọn voucher.');
        return;
    }

    // Cấu hình dùng để tạm tính trên giao diện.
    // Máy chủ phải kiểm tra lại bằng cấu hình nghiệp vụ của hệ thống.
    const vouchers = [
        {
            code: 'SOPPE20',
            title: 'Giảm 20% giá trị đơn hàng',
            minimum: 200000,
            percent: 20,
            maximum: 100000,
            amount: 0,
            enabled: true,
            description: 'Tối đa 100.000đ | Đơn tối thiểu 200.000đ'
        },
        {
            code: 'GIAM50K',
            title: 'Giảm trực tiếp 50.000đ',
            minimum: 500000,
            percent: 0,
            maximum: 0,
            amount: 50000,
            enabled: true,
            description: 'Đơn tối thiểu 500.000đ'
        },
        {
            code: 'FREESHIP30',
            title: 'Giảm phí vận chuyển đến 30.000đ',
            minimum: 300000,
            percent: 0,
            maximum: 0,
            amount: 0,
            enabled: false,
            description: 'Chờ kích hoạt thanh toán'
        },
        {
            code: 'GIAM10',
            title: 'Giảm 10% toàn bộ sản phẩm',
            minimum: 100000,
            percent: 10,
            maximum: 50000,
            amount: 0,
            enabled: false,
            description: 'Chương trình bổ sung, chờ kích hoạt'
        }
    ];

    const formatter = new Intl.NumberFormat('vi-VN');
    const storageKey = 'soppe_saved_coupons';

    let subtotal = 0;
    let selectedCount = 0;
    let readFailed = false;
    let activeCode = '';
    let pendingCode = '';

    // Mã được mang sang từ nút Dùng ngay.
    let requestedCode = normalize(
        new URL(window.location.href).searchParams.get('voucher')
    );

    function normalize(value) {
        return String(value || '').trim().toUpperCase();
    }

    function money(value) {
        return formatter.format(value) + 'đ';
    }

    function findVoucher(code) {
        return vouchers.find(function (voucher) {
            return voucher.code === code;
        });
    }

    function reason(voucher) {
        if (!voucher) return 'Mã voucher không tồn tại.';
        if (!voucher.enabled) return 'Voucher chưa được mở sử dụng.';
        if (readFailed) return 'Chưa đọc được dữ liệu giỏ hàng.';
        if (selectedCount === 0) return 'Hãy chọn sản phẩm trong giỏ hàng.';

        if (subtotal < voucher.minimum) {
            return 'Mua thêm ' +
                money(voucher.minimum - subtotal) +
                ' để sử dụng mã.';
        }

        return '';
    }

    function discount(voucher) {
        if (!voucher || reason(voucher)) return 0;

        const value = voucher.percent > 0
            ? Math.min(
                subtotal * voucher.percent / 100,
                voucher.maximum
            )
            : voucher.amount;

        // Tạm tính theo đồng, không giảm quá tiền hàng.
        return Math.min(subtotal, Math.floor(value));
    }

    function readSaved() {
        try {
            const value = JSON.parse(
                localStorage.getItem(storageKey) || '[]'
            );

            if (!Array.isArray(value)) return [];

            return value
                .filter(function (code) {
                    return typeof code === 'string';
                })
                .map(normalize);
        } catch (error) {
            return [];
        }
    }

    function updateSummary() {
        const voucher = findVoucher(activeCode);
        const savedAmount = discount(voucher);

        discountBox.textContent = savedAmount > 0
            ? '−' + money(savedAmount)
            : '0đ';

        totalBox.textContent = money(subtotal - savedAmount);
        couponInput.value = activeCode;

        removeButton.hidden = !activeCode;
        openButton.textContent = activeCode
            ? 'Đổi voucher'
            : 'Chọn hoặc nhập mã';
    }

    function renderList() {
        list.textContent = '';

        const saved = readSaved();

        vouchers.forEach(function (voucher) {
            const problem = reason(voucher);

            const row = document.createElement('label');
            row.className = 'sp-cart-voucher-option';

            if (problem) {
                row.classList.add('is-unavailable');
            }

            const radio = document.createElement('input');
            radio.type = 'radio';
            radio.name = 'cartVoucherChoice';
            radio.value = voucher.code;
            radio.disabled = Boolean(problem);
            radio.checked = !problem && pendingCode === voucher.code;

            const content = document.createElement('div');

            const title = document.createElement('strong');
            title.textContent = voucher.title;

            const description = document.createElement('p');
            description.textContent = voucher.description;

            const code = document.createElement('p');
            code.textContent = 'Mã: ' + voucher.code +
                (saved.includes(voucher.code) ? ' · Đã lưu' : '');

            const state = document.createElement('small');
            state.textContent = problem ||
                ('Có thể dùng · Giảm dự kiến ' + money(discount(voucher)));

            content.append(title, description, code, state);
            row.append(content, radio);
            list.appendChild(row);

            radio.addEventListener('change', function () {
                pendingCode = voucher.code;
                message.textContent = '';
                applyButton.disabled = false;
            });
        });

        applyButton.disabled =
            Boolean(reason(findVoucher(pendingCode)));
    }

    function openDialog() {
        pendingCode = activeCode;
        codeInput.value = activeCode;
        message.textContent = '';
        renderList();

        if (!dialog.open) dialog.showModal();
    }

    function closeDialog() {
        dialog.close();
    }

    function checkCode() {
        const code = normalize(codeInput.value);
        const voucher = findVoucher(code);
        const problem = reason(voucher);

        codeInput.value = code;

        if (problem) {
            message.textContent = problem;
            return;
        }

        pendingCode = code;
        renderList();

        message.textContent =
            'Mã hợp lệ theo tạm tính. Nhấn Áp dụng để chọn.';
    }

    openButton.addEventListener('click', openDialog);
    closeButton.addEventListener('click', closeDialog);
    cancelButton.addEventListener('click', closeDialog);
    checkButton.addEventListener('click', checkCode);

    codeInput.addEventListener('keydown', function (event) {
        if (event.key === 'Enter') {
            event.preventDefault();
            checkCode();
        }
    });

    applyButton.addEventListener('click', function () {
        const voucher = findVoucher(pendingCode);
        const problem = reason(voucher);

        if (problem) {
            message.textContent = problem;
            renderList();
            return;
        }

        activeCode = voucher.code;
        updateSummary();

        status.textContent = 'Đã chọn ' + activeCode +
            '. Giảm dự kiến ' + money(discount(voucher)) +
            '; xác nhận lại tại thanh toán.';

        dialog.close();
    });

    removeButton.addEventListener('click', function () {
        activeCode = '';
        pendingCode = '';
        updateSummary();
        status.textContent = 'Đã bỏ voucher.';
    });

    document.addEventListener('soppe:cart-changed', function (event) {
        const data = event.detail;
        if (!data) return;

        subtotal = Number(data.subtotal);
        selectedCount = Number(data.selectedCount);
        readFailed = Boolean(data.readFailed);

        if (!Number.isFinite(subtotal) || subtotal < 0 ||
            !Number.isSafeInteger(selectedCount) || selectedCount < 0) {
            subtotal = 0;
            selectedCount = 0;
            readFailed = true;
        }

        if (activeCode) {
            const voucher = findVoucher(activeCode);
            const problem = reason(voucher);

            if (problem) {
                const previousCode = activeCode;
                activeCode = '';

                status.textContent =
                    'Đã bỏ mã ' + previousCode + ': ' + problem;
            } else {
                status.textContent = 'Đã chọn ' + activeCode +
                    '. Giảm dự kiến ' + money(discount(voucher)) +
                    '; xác nhận lại tại thanh toán.';
            }
        }

        updateSummary();

        // Chỉ xử lý yêu cầu từ trang ưu đãi một lần.
        if (requestedCode) {
            const code = requestedCode;
            requestedCode = '';

            openDialog();
            codeInput.value = code;
            checkCode();
        } else if (dialog.open) {
            // Giỏ hàng thay đổi: cập nhật lại điều kiện trong hộp chọn.
            if (reason(findVoucher(pendingCode))) {
                pendingCode = '';
            }

            renderList();
            message.textContent =
                'Giỏ hàng đã thay đổi. Hãy kiểm tra lại voucher.';
        }
    });

    window.addEventListener('storage', function (event) {
        if ((event.key === storageKey || event.key === null) &&
            dialog.open) {
            renderList();
        }
    });
});
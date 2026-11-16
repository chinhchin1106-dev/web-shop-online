document.addEventListener('DOMContentLoaded', function () {
    'use strict';

    const root = document.getElementById('spDeals');
    if (!root) return;

    const storageKey = 'soppe_saved_coupons';
    const message = document.getElementById('spDealMessage');

    const cards = Array.from(
        root.querySelectorAll('[data-deal-category]')
    );

    const filters = Array.from(
        root.querySelectorAll('[data-deal-filter]')
    );

    const slides = Array.from(
        root.querySelectorAll('[data-deal-slide]')
    );

    const dots = Array.from(
        root.querySelectorAll('[data-deal-dot]')
    );

    let currentSlide = 0;

    function notify(text) {
        message.textContent = text;
    }

    function filterCards(category) {
        cards.forEach(function (card) {
            const categories = card.dataset.dealCategory.split(' ');

            card.hidden = category !== 'all' &&
                !categories.includes(category);
        });

        filters.forEach(function (button) {
            button.setAttribute(
                'aria-pressed',
                String(button.dataset.dealFilter === category)
            );
        });
    }

    filters.forEach(function (button) {
        button.addEventListener('click', function () {
            filterCards(button.dataset.dealFilter);
        });
    });

    root.querySelector('[data-deal-all]')
        .addEventListener('click', function () {
            filterCards('all');
        });

    function showSlide(index) {
        if (slides.length === 0) return;

        currentSlide = (index + slides.length) % slides.length;

        slides.forEach(function (slide, position) {
            slide.hidden = position !== currentSlide;
        });

        dots.forEach(function (dot, position) {
            dot.setAttribute(
                'aria-pressed',
                String(position === currentSlide)
            );
        });
    }

    root.querySelector('[data-deal-prev]')
        .addEventListener('click', function () {
            showSlide(currentSlide - 1);
        });

    root.querySelector('[data-deal-next]')
        .addEventListener('click', function () {
            showSlide(currentSlide + 1);
        });

    dots.forEach(function (dot) {
        dot.addEventListener('click', function () {
            showSlide(Number(dot.dataset.dealDot));
        });
    });

    // Nếu chưa thêm ảnh, hiển thị khung chờ bên dưới.
    root.querySelectorAll('[data-deal-image]').forEach(function (img) {
        img.addEventListener('error', function () {
            img.hidden = true;
        });

        if (img.complete && img.naturalWidth === 0) {
            img.hidden = true;
        }
    });

    function readSavedCodes() {
        const data = JSON.parse(
            localStorage.getItem(storageKey) || '[]'
        );

        if (!Array.isArray(data)) {
            throw new Error('Danh sách mã đã lưu không hợp lệ.');
        }

        return data.filter(function (code) {
            return typeof code === 'string';
        });
    }

    function displaySavedCodes(codes) {
        root.querySelectorAll('[data-save-code]').forEach(function (button) {
            const saved = codes.includes(button.dataset.saveCode);

            button.textContent = saved ? 'Dùng ngay →' : '↓ Lưu mã';
            button.disabled = false;
        });
    }

    root.querySelectorAll('[data-save-code]').forEach(function (button) {
        button.addEventListener('click', function () {
            try {
                const code = button.dataset.saveCode;
                if (!code) return;

                const saved = readSavedCodes();

                // Mã đã lưu: chuyển đến giỏ hàng cùng mã được chọn.
                if (saved.includes(code)) {
                    const cartUrl = root.dataset.cartUrl;

                    if (!cartUrl) {
                        notify('Chưa cấu hình đường dẫn giỏ hàng.');
                        return;
                    }

                    const url = new URL(cartUrl, window.location.href);
                    url.searchParams.set('voucher', code);
                    window.location.assign(url.href);
                    return;
                }

                // Chưa lưu: lưu mã và đổi nút thành Dùng ngay.
                saved.push(code);
                localStorage.setItem(storageKey, JSON.stringify(saved));

                displaySavedCodes(saved);
                notify('Đã lưu mã ' + code +
                    '. Nhấn Dùng ngay để chọn mã trong giỏ hàng.');
            } catch (error) {
                notify('Không đọc hoặc lưu được mã. Bạn có thể sao chép mã.');
            }
        });
    });

    root.querySelectorAll('[data-copy-code]').forEach(function (button) {
        button.addEventListener('click', async function () {
            const code = button.dataset.copyCode;

            try {
                await navigator.clipboard.writeText(code);
                notify('Đã sao chép mã ' + code + '.');
            } catch (error) {
                notify('Trình duyệt chưa cho sao chép. Hãy chọn mã ' +
                    code + ' và nhấn Ctrl + C.');
            }
        });
    });

    try {
        displaySavedCodes(readSavedCodes());
    } catch (error) {
        notify('Không đọc được danh sách mã đã lưu.');
    }

    showSlide(0);
    filterCards('all');
});
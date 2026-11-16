
document.addEventListener("DOMContentLoaded", function () {
    "use strict";

    const $ = (id) => document.getElementById(id);
    const CART_KEY = "soppe_cart";
    const FAVORITE_KEY = "soppe_favorites";
    const NOTICE_KEY = "soppe_notices";
    const money = (n) => Number(n || 0).toLocaleString("vi-VN") + " đ";

    function readStore(key, fallback) {
        try {
            const text = localStorage.getItem(key);
            return text === null ? fallback : JSON.parse(text);
        } catch (e) {
            console.warn("Sộp Pe: dữ liệu lưu không hợp lệ", key, e);
            return fallback;
        }
    }
    function writeStore(key, value) {
        try { localStorage.setItem(key, JSON.stringify(value)); }
        catch (e) { console.warn("Sộp Pe: không lưu được dữ liệu", key, e); }
    }
    function showToast(message) {
        let toast = $("soppeToast");
        if (!toast) {
            toast = document.createElement("div");
            toast.id = "soppeToast";
            toast.className = "sp-toast";
            toast.setAttribute("role", "status");
            document.body.appendChild(toast);
        }
        toast.textContent = message;
        toast.hidden = false;
        clearTimeout(showToast.timeout);
        showToast.timeout = setTimeout(function () { toast.hidden = true; }, 2800);
    }


    document.querySelectorAll('img[data-user-image]').forEach(function (img) {
        const holder = img.closest('.sp-image-frame, .sp-banner-slide, .sp-offer-strip');
        function loaded() { if (holder) holder.classList.add('has-image'); img.hidden = false; }
        function failed() { if (holder) holder.classList.remove('has-image'); img.hidden = true; }
        img.addEventListener('load', loaded);
        img.addEventListener('error', failed);
        if (img.complete) {
            if (img.naturalWidth > 0) loaded(); else failed();
        }
    });


    const dropdowns = Array.from(document.querySelectorAll('details.site-dropdown'));
    dropdowns.forEach(function (dropdown) {
        dropdown.addEventListener('toggle', function () {
            if (!dropdown.open) return;
            dropdowns.forEach(function (other) {
                if (other !== dropdown) other.open = false;
            });
        });
    });
    document.addEventListener('click', function (event) {
        dropdowns.forEach(function (dropdown) {
            if (!dropdown.contains(event.target)) dropdown.open = false;
        });
    });
    document.addEventListener('keydown', function (event) {
        if (event.key !== 'Escape') return;
        const opened = dropdowns.find(function (d) { return d.open; });
        dropdowns.forEach(function (d) { d.open = false; });
        if (opened) opened.querySelector('summary').focus();
    });

    document.querySelectorAll('form.header-search').forEach(function (form) {
        form.addEventListener('submit', function (event) {
            const input = form.querySelector('input[name="search"]');
            if (!input) return;
            const keyword = input.value.trim();
            if (!keyword) {
                event.preventDefault();
                showToast('Vui lòng nhập tên sản phẩm cần tìm.');
                input.focus();
            } else input.value = keyword;
        });
    });

    function normalizeCart(raw) {
        if (!Array.isArray(raw)) return [];
        return raw.map(function (item) {
            return {
                id: String(item.id || '').trim(),
                name: String(item.name || '').trim(),
                price: Number(item.price),
                quantity: Math.floor(Number(item.quantity)),
                image: String(item.image || '')
            };
        }).filter(function (p) {
            return p.id && p.name && Number.isFinite(p.price) && p.price >= 0 &&
                Number.isFinite(p.quantity) && p.quantity > 0;
        });
    }
    let cart = normalizeCart(readStore(CART_KEY, []));
    function saveCart() { writeStore(CART_KEY, cart); renderCart(); }
    function addToCart(product) {
        const id = String(product.id || '').trim();
        const name = String(product.name || '').trim();
        const price = Number(product.price);
        if (!id || !name || !Number.isFinite(price) || price < 0) {
            showToast('Thiếu mã, tên hoặc giá sản phẩm hợp lệ.');
            return;
        }
        const existing = cart.find(function (p) { return p.id === id; });
        if (existing) existing.quantity += 1;
        else cart.push({ id: id, name: name, price: price, quantity: 1, image: String(product.image || '') });
        saveCart();
        showToast('Đã thêm ' + name + ' vào giỏ hàng!');
    }
    function renderCart() {
        const count = cart.reduce(function (n, p) { return n + p.quantity; }, 0);
        const total = cart.reduce(function (n, p) { return n + p.price * p.quantity; }, 0);
        const countTop = $('headerCartCount');
        const cartCount = $('cartCount');
        const cartTotal = $('cartTotal');
        const cartItems = $('cartItems');
        if (countTop) { countTop.textContent = String(count); countTop.hidden = count === 0; }
        if (cartCount) cartCount.textContent = String(count);
        if (cartTotal) cartTotal.textContent = money(total);
        if (!cartItems) return;
        cartItems.replaceChildren();
        if (!cart.length) {
            const empty = document.createElement('p');
            empty.className = 'sp-cart-empty';
            empty.textContent = '🛒 Giỏ hàng của bạn đang trống. Hãy tiếp tục mua sắm nhé!';
            cartItems.appendChild(empty);
            return;
        }
        cart.forEach(function (p) {
            const row = document.createElement('div');
            row.className = 'cart-item';
            const description = document.createElement('div');
            const title = document.createElement('strong');
            title.textContent = p.name;
            const sub = document.createElement('p');
            sub.textContent = money(p.price) + ' × ' + p.quantity + ' = ' + money(p.price * p.quantity);
            description.append(title, sub);
            const actions = document.createElement('div');
            actions.className = 'cart-item-actions';
            [
                { action: 'decrease', label: '−', aria: 'Giảm số lượng' },
                { action: 'increase', label: '+', aria: 'Tăng số lượng' },
                { action: 'remove', label: 'Xóa', aria: 'Xóa sản phẩm' }
            ].forEach(function (cfg) {
                const button = document.createElement('button');
                button.type = 'button';
                button.textContent = cfg.label;
                button.dataset.cartAction = cfg.action;
                button.dataset.cartId = p.id;
                button.setAttribute('aria-label', cfg.aria + ' ' + p.name);
                actions.appendChild(button);
            });
            row.append(description, actions);
            cartItems.appendChild(row);
        });
    }
    renderCart();
    function normalizeFavorites(raw) {
        if (!Array.isArray(raw)) return [];
        return raw.map(function (p) {
            return {
                id: String(p.id || '').trim(),
                name: String(p.name || '').trim(),
                price: Number(p.price),
                image: String(p.image || '')
            };
        }).filter(function (p) { return p.id && p.name && Number.isFinite(p.price) && p.price >= 0; });
    }
    let favorites = normalizeFavorites(readStore(FAVORITE_KEY, []));
    function saveFavorites() { writeStore(FAVORITE_KEY, favorites); renderFavorites(); }
    function toggleFavorite(product) {
        const id = String(product.id || '').trim();
        const name = String(product.name || '').trim();
        const price = Number(product.price);
        if (!id || !name || !Number.isFinite(price) || price < 0) {
            showToast('Sản phẩm chưa có dữ liệu hợp lệ.');
            return;
        }
        const index = favorites.findIndex(function (p) { return p.id === id; });
        if (index >= 0) {
            favorites.splice(index, 1);
            showToast('Đã bỏ ' + name + ' khỏi yêu thích.');
        } else {
            favorites.push({ id: id, name: name, price: price, image: String(product.image || '') });
            showToast('Đã lưu ' + name + ' vào yêu thích!');
        }
        saveFavorites();
    }
    function renderFavorites() {
        const count = $('headerFavoriteCount');
        if (count) { count.textContent = String(favorites.length); count.hidden = favorites.length === 0; }
        document.querySelectorAll('[data-favorite]').forEach(function (button) {
            const selected = favorites.some(function (p) { return p.id === button.dataset.id; });
            button.setAttribute('aria-pressed', String(selected));
            button.textContent = selected ? '♥' : '♡';
        });
        const panel = $('spFavoriteItems');
        if (!panel) return;
        panel.replaceChildren();
        if (!favorites.length) {
            const empty = document.createElement('p');
            empty.className = 'sp-fav-empty';
            empty.textContent = 'Bạn chưa lưu sản phẩm nào. Hãy bấm ♡ trên sản phẩm bạn thích.';
            panel.appendChild(empty);
            return;
        }
        favorites.forEach(function (p) {
            const card = document.createElement('div'); card.className = 'sp-saved-card';
            const title = document.createElement('strong'); title.textContent = '♥ ' + p.name;
            const price = document.createElement('span'); price.className = 'sp-saved-price'; price.textContent = money(p.price);
            const actions = document.createElement('div'); actions.className = 'sp-saved-actions';
            const add = document.createElement('button'); add.type = 'button'; add.textContent = '🛒 Thêm giỏ';
            add.dataset.addToCart = ''; add.dataset.id = p.id; add.dataset.name = p.name;
            add.dataset.price = String(p.price); add.dataset.image = p.image;
            const remove = document.createElement('button'); remove.type = 'button'; remove.textContent = 'Bỏ thích';
            remove.dataset.removeFavorite = p.id;
            actions.append(add, remove);
            card.append(title, price, actions);
            panel.appendChild(card);
        });
    }
    renderFavorites();

    document.addEventListener('click', function (event) {
        const target = event.target instanceof Element ? event.target : null;
        if (!target) return;

        const addButton = target.closest('[data-add-to-cart]');
        if (addButton) {
            event.preventDefault();
            addToCart({
                id: addButton.dataset.id, name: addButton.dataset.name,
                price: addButton.dataset.price, image: addButton.dataset.image
            });
            return;
        }
        const cartButton = target.closest('[data-cart-action]');
        if (cartButton) {
            event.preventDefault();
            const item = cart.find(function (p) { return p.id === cartButton.dataset.cartId; });
            if (!item) return;
            if (cartButton.dataset.cartAction === 'increase') item.quantity += 1;
            else if (cartButton.dataset.cartAction === 'decrease') item.quantity -= 1;
            else if (cartButton.dataset.cartAction === 'remove') item.quantity = 0;
            else return;
            cart = cart.filter(function (p) { return p.quantity > 0; });
            saveCart();
            return;
        }
        const favButton = target.closest('[data-favorite]');
        if (favButton) {
            event.preventDefault();
            toggleFavorite({
                id: favButton.dataset.id, name: favButton.dataset.name,
                price: favButton.dataset.price, image: favButton.dataset.image
            });
            return;
        }
        const removeFavorite = target.closest('[data-remove-favorite]');
        if (removeFavorite) {
            event.preventDefault();
            favorites = favorites.filter(function (p) { return p.id !== removeFavorite.dataset.removeFavorite; });
            saveFavorites(); showToast('Đã bỏ khỏi yêu thích.');
            return;
        }
        const pending = target.closest('[data-pending-link]');
        if (pending) { showToast('Chưa cấu hình đường dẫn ' + pending.dataset.pendingLink + '.'); }
    });

    const clearCart = $('spClearCart');
    if (clearCart) clearCart.addEventListener('click', function () {
        if (!cart.length) { showToast('Giỏ hàng đang trống.'); return; }
        if (window.confirm('Bạn muốn xóa toàn bộ sản phẩm trong giỏ hàng?')) {
            cart = []; saveCart(); showToast('Đã làm trống giỏ hàng.');
        }
    });
    const checkout = $('spCheckoutDemo');
    if (checkout) checkout.addEventListener('click', function () {
        if (!cart.length) showToast('Hãy thêm sản phẩm trước khi thanh toán.');
        else showToast('Thanh toán demo: cần kết nối Controller và cơ sở dữ liệu.');
    });
    window.addEventListener('storage', function (event) {
        if (event.key === CART_KEY) { cart = normalizeCart(readStore(CART_KEY, [])); renderCart(); }
        if (event.key === FAVORITE_KEY) { favorites = normalizeFavorites(readStore(FAVORITE_KEY, [])); renderFavorites(); }
    });


    const carousel = $('promoCarousel');
    if (carousel) {
        const slides = Array.from(carousel.querySelectorAll('.sp-banner-slide'));
        const dots = Array.from(carousel.querySelectorAll('[data-slide-to]'));
        const prev = carousel.querySelector('[data-slide-prev]');
        const next = carousel.querySelector('[data-slide-next]');
        let activeIndex = 0;
        let timer = null;
        const reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        function showSlide(index) {
            if (!slides.length) return;
            activeIndex = (index + slides.length) % slides.length;
            slides.forEach(function (slide, i) {
                const active = i === activeIndex;
                slide.hidden = !active;
                slide.classList.toggle('is-active', active);
                slide.setAttribute('aria-hidden', String(!active));
            });
            dots.forEach(function (dot, i) {
                const active = i === activeIndex;
                dot.classList.toggle('is-active', active);
                if (active) dot.setAttribute('aria-current', 'true');
                else dot.removeAttribute('aria-current');
            });
        }
        function stopAuto() { if (timer) clearInterval(timer); timer = null; }
        function startAuto() {
            stopAuto();
            if (slides.length < 2 || reduceMotion || document.hidden) return;
            timer = setInterval(function () { showSlide(activeIndex + 1); }, 5000);
        }
        if (prev) prev.addEventListener('click', function () { showSlide(activeIndex - 1); startAuto(); });
        if (next) next.addEventListener('click', function () { showSlide(activeIndex + 1); startAuto(); });
        dots.forEach(function (dot) {
            dot.addEventListener('click', function () { showSlide(Number(dot.dataset.slideTo)); startAuto(); });
        });
        carousel.addEventListener('mouseenter', stopAuto);
        carousel.addEventListener('mouseleave', startAuto);
        carousel.addEventListener('focusin', stopAuto);
        carousel.addEventListener('focusout', function (event) {
            if (!carousel.contains(event.relatedTarget)) startAuto();
        });
        document.addEventListener('visibilitychange', function () { document.hidden ? stopAuto() : startAuto(); });
        showSlide(0);
        startAuto();
    }


    const backtop = $('spBackTop');
    if (backtop) {
        const update = function () { backtop.hidden = window.scrollY < 220; };
        window.addEventListener('scroll', update, { passive: true });
        backtop.addEventListener('click', function () { window.scrollTo({ top: 0, behavior: 'smooth' }); });
        update();
    }

    document.querySelectorAll('form[data-demo-login="true"]').forEach(function (form) {
        form.addEventListener('submit', function (event) {
            event.preventDefault();
            const message = $('loginMessage');
            if (message) message.textContent = 'Chế độ demo: chưa có hệ thống xác thực tài khoản.';
            else showToast('Đăng nhập demo: cần kết nối backend.');
        });
    });

    const notificationPanel = $('notificationPanel');
    if (notificationPanel) {
        let notices = readStore(NOTICE_KEY, [
            { id: 1, text: 'Chào mừng bạn đến với Sộp Pe!', read: false },
            { id: 2, text: 'Khám phá sản phẩm mới!', read: false }
        ]);
        if (!Array.isArray(notices)) notices = [];
        function renderNotices() {
            notificationPanel.replaceChildren();
            notices.forEach(function (notice) {
                const button = document.createElement('button'); button.type = 'button';
                button.className = 'notification-item';
                button.textContent = (notice.read ? '✓ ' : '● ') + String(notice.text || '');
                button.addEventListener('click', function () {
                    notice.read = true; writeStore(NOTICE_KEY, notices); renderNotices();
                });
                notificationPanel.appendChild(button);
            });
        }

        renderNotices();
    }
    // Đánh dấu đã đọc cho các nút trong thong bao.htm
    ['btnDoc1', 'btnDoc2'].forEach(function (id) {
        const button = $(id);

        if (button) {
            button.addEventListener('click', function () {
                button.textContent = '✓ Đã đọc';
                button.disabled = true;
                button.style.background = '#e8f7ee';
                button.style.color = '#16834a';
                button.style.border = '1px solid #b7e4c7';
                button.style.boxShadow = 'none';
            });
        }
    });
    
        
    
    console.log('Sộp Pe: menu, banner, giỏ hàng và yêu thích đã khởi tạo.');
});

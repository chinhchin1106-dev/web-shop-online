

document.addEventListener("DOMContentLoaded", function () {
    const btnMenu = document.getElementById("btnMenu");

    const categoryMenu =
        document.getElementById("categoryDropdown") ||
        document.getElementById("categoryMenu");

    const btnMainMenu = document.getElementById("btnMainMenu");
    const mainMenu = document.getElementById("mainMenu");

    const btnSearch = document.getElementById("btnSearch");
    const searchBox = document.getElementById("searchBox");
    const searchInput = document.getElementById("searchInput");

    const btnChat = document.getElementById("btnChat");
    const chatPanel = document.getElementById("chatPanel");
    const closeChat = document.getElementById("closeChat");

    const chatForm = document.getElementById("chatForm");
    const chatInput = document.getElementById("chatInput");
    const chatMessages = document.getElementById("chatMessages");

    const loginForm = document.getElementById("loginDemoForm");
    const loginMessage = document.getElementById("loginMessage");



    if (btnMenu && categoryMenu) {

        categoryMenu.hidden = true;

        btnMenu.setAttribute(
            "aria-controls",
            categoryMenu.id
        );

        btnMenu.setAttribute("aria-expanded", "false");

        
        function closeCategoryMenu() {
            categoryMenu.hidden = true;
            btnMenu.setAttribute("aria-expanded", "false");
        }

      
        btnMenu.addEventListener("click", function (event) {

            event.preventDefault();
            event.stopPropagation();

            const isOpening = categoryMenu.hidden;

            categoryMenu.hidden = !isOpening;

            btnMenu.setAttribute(
                "aria-expanded",
                String(isOpening)
            );

        });

        // Bấm ngoài danh mục thì đóng
        document.addEventListener("click", function (event) {

            if (
                !btnMenu.contains(event.target) &&
                !categoryMenu.contains(event.target)
            ) {
                closeCategoryMenu();
            }

        });

        // Nhấn ESC để đóng
        document.addEventListener("keydown", function (event) {

            if (event.key === "Escape" &&
                !categoryMenu.hidden) {

                closeCategoryMenu();
                btnMenu.focus();

            }

        });

    } else {
        console.warn(
            "Không tìm thấy btnMenu hoặc categoryDropdown. " +
            "Hãy kiểm tra ID trong _Layout.cshtml."
        );
    }


    if (btnMainMenu && mainMenu) {

        btnMainMenu.setAttribute(
            "aria-expanded",
            String(mainMenu.classList.contains("active"))
        );

        btnMainMenu.addEventListener("click", function () {

            mainMenu.classList.toggle("active");

            btnMainMenu.setAttribute(
                "aria-expanded",
                String(mainMenu.classList.contains("active"))
            );

        });
    }


    if (btnSearch && searchBox) {

        btnSearch.setAttribute(
            "aria-expanded",
            String(!searchBox.hidden)
        );

        btnSearch.addEventListener("click", function () {

            searchBox.hidden = !searchBox.hidden;

            btnSearch.setAttribute(
                "aria-expanded",
                String(!searchBox.hidden)
            );

            if (!searchBox.hidden && searchInput) {
                searchInput.focus();
            }

        });
    }

    const headerSearch =
        document.querySelector(".header-search");

    if (headerSearch) {

        headerSearch.addEventListener("submit", function (event) {

            const input = headerSearch.querySelector(
                'input[name="search"]'
            );

            if (input && input.value.trim() === "") {
                event.preventDefault();
                input.focus();
                return;
            }

            if (input) {
                input.value = input.value.trim();
            }

        });
    }



    if (btnChat && chatPanel) {

        btnChat.setAttribute(
            "aria-expanded",
            String(!chatPanel.hidden)
        );

        btnChat.addEventListener("click", function () {

            chatPanel.hidden = !chatPanel.hidden;

            btnChat.setAttribute(
                "aria-expanded",
                String(!chatPanel.hidden)
            );

            if (!chatPanel.hidden && chatInput) {
                chatInput.focus();
            }

        });
    }

    if (closeChat && chatPanel) {

        closeChat.addEventListener("click", function () {

            chatPanel.hidden = true;

            if (btnChat) {
                btnChat.setAttribute("aria-expanded", "false");
                btnChat.focus();
            }

        });
    }



    if (chatForm && chatInput && chatMessages) {

        chatForm.addEventListener("submit", function (event) {

            event.preventDefault();

            const message = chatInput.value.trim();

            if (message === "") {
                return;
            }

            const userText = document.createElement("p");

            userText.textContent = "Bạn: " + message;

            chatMessages.appendChild(userText);

            const reply = document.createElement("p");

            reply.textContent =
                "Sộp Pe: Cảm ơn bạn đã liên hệ! " +
                "Chúng tôi sẽ hỗ trợ bạn sớm nhất.";

            chatMessages.appendChild(reply);

            chatInput.value = "";

            chatMessages.scrollTop =
                chatMessages.scrollHeight;

            chatInput.focus();

        });
    }



    if (loginForm && loginMessage) {

        loginForm.addEventListener("submit", function (event) {

            event.preventDefault();

            loginMessage.textContent =
                "Chức năng đăng nhập hiện đang ở " +
                "chế độ demo, chưa xác thực tài khoản.";

        });
    }

});

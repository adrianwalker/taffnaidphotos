document.addEventListener("DOMContentLoaded", function () {

    let start = [0, 0];
    let touches = 0;

    function hideNav(navId) {
        let nav = document.getElementById(navId);
        if (nav) {
            nav.style.display = "none";
        }
    }

    function rotate() {
        let image = document.querySelector("#view-image img");
        if (image) {
            let currentRotation = parseInt(image.dataset.rotation, 10) || 0;
            let newRotation = (currentRotation + 90) % 360;
            image.style.transform = `rotate(${newRotation}deg)`;
            image.dataset.rotation = newRotation;

            if (newRotation % 180 === 0) {
                [image.style.maxWidth, image.style.maxHeight] = ["100dvw", "100dvh"];
            } else {
                [image.style.maxWidth, image.style.maxHeight] = ["100dvh", "100dvw"];
            }
        }
    }

    function previous() {
        let prevLink = document.querySelector(".previous");
        if (prevLink) {
            window.location.href = prevLink.href;
        }
    }

    function next() {
        let nextLink = document.querySelector(".next");
        if (nextLink) {
            window.location.href = nextLink.href;
        }
    }

    function parent() {
        let parentLink = document.querySelector(".parent");
        if (parentLink) {
            window.location.href = parentLink.href;
        }
    }

    function startSwipe(event) {
        touches = event.touches.length;
        if (touches > 1) {
            return;
        }

        start = [event.touches[0].clientX, event.touches[0].clientY];
    }

    function endSwipe(event) {
        if (touches > 1) {
            return;
        }

        let end = [event.changedTouches[0].clientX, event.changedTouches[0].clientY];
        let diff = [end[0] - start[0], end[1] - start[1]];

        let horizontal = Math.abs(diff[0]) > 50;
        let vertical = Math.abs(diff[1]) > 50;

        let left = diff[0] > 0;
        let right = diff[0] < 0;
        let up = diff[1] < 0;
        let startNearTop = start[1] < window.innerHeight / 3

        if (horizontal && left) {
            previous();
        } else if (horizontal && right) {
            next();
        } else if (vertical && up && startNearTop) {
            parent();
        }
    }


    if ('ontouchstart' in window) {
        hideNav("list-nav");
        hideNav("view-nav");

        document.addEventListener("touchstart", function (event) {
            startSwipe(event);
        });

        document.addEventListener("touchend", function (event) {
            endSwipe(event);
        });

        document.addEventListener("click", function (event) {
            rotate();
        });
    }
});

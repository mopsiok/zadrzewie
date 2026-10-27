// Photo lightbox for .gallery grids; one .lightbox dialog per page is enough.
(function () {
  var dialog = document.querySelector('.lightbox');
  if (!dialog) return;

  var preview = dialog.querySelector('.lightbox-image');
  var caption = dialog.querySelector('.lightbox-caption');
  var buttons = Array.prototype.slice.call(document.querySelectorAll('.gallery-photo'));
  var currentIndex = 0;

  // hide the page scrollbar behind the modal for as long as it is open
  function lockScroll() {
    document.documentElement.style.overflow = 'hidden';
  }
  function unlockScroll() {
    document.documentElement.style.overflow = '';
  }

  function showImage(index) {
    currentIndex = (index + buttons.length) % buttons.length;
    var image = buttons[currentIndex].querySelector('img');
    preview.src = image.currentSrc || image.src;
    preview.alt = image.alt;
    caption.textContent = image.alt;
  }

  buttons.forEach(function (button, index) {
    button.addEventListener('click', function () {
      showImage(index);
      lockScroll();
      dialog.showModal();
    });
  });

  dialog.addEventListener('close', unlockScroll);

  dialog.querySelector('.prev-photo').addEventListener('click', function () {
    showImage(currentIndex - 1);
  });
  dialog.querySelector('.next-photo').addEventListener('click', function () {
    showImage(currentIndex + 1);
  });

  dialog.addEventListener('keydown', function (event) {
    if (event.key === 'ArrowLeft') {
      event.preventDefault();
      showImage(currentIndex - 1);
    } else if (event.key === 'ArrowRight') {
      event.preventDefault();
      showImage(currentIndex + 1);
    }
  });

  dialog.addEventListener('click', function (event) {
    if (event.target === dialog) dialog.close();
  });
}());

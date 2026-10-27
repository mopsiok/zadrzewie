// TODO: jeśli pojawią się partnerzy lub formalny patron – dodać ich tutaj.
document.addEventListener('DOMContentLoaded', function () {
  var spot = document.getElementById('footer');
  if (!spot) return;

  spot.innerHTML =
    '<footer class="site-footer"><div class="footer-inner">' +
      '<p class="footer-join">Chcesz do&#322;&#261;czy&#263; albo pom&oacute;c? Napisz: ' +
        '<a href="mailto:patrykjarosz01@gmail.com">patrykjarosz01@gmail.com</a></p>' +
      '<p class="footer-note">&copy; 2026 Patryk Jarosz &middot; Ogr&oacute;d Spo&#322;eczny Zadrzewie</p>' +
    '</div></footer>';
});

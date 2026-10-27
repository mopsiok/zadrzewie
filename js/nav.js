(function () {
  var header = document.querySelector('[data-navigation]');
  if (!header) return;

  var page = window.location.pathname.split('/').pop() || 'index.html';
  var items = [
    ['vision.html', 'Wizja', false],
    ['terrain.html', 'Teren', false],
    ['inspiration.html', 'Inspiracje', false],
    ['contact.html', 'Dołącz', true]
  ];

  var navLinks = items.map(function (item) {
    var className = item[2] ? ' class="join"' : (item[0] === page ? ' class="active"' : '');
    return '<li><a href="' + item[0] + '"' + className + '>' + item[1] + '</a></li>';
  }).join('');

  header.innerHTML =
    '<div class="site-header"><div class="header-inner">' +
      '<a class="brand" href="index.html">Zadrzewie' +
        '<span class="brand-tagline">ogr&oacute;d spo&#322;eczny w Krakowie</span>' +
      '</a>' +
      '<nav aria-label="Nawigacja g&#322;&oacute;wna"><ul>' + navLinks + '</ul></nav>' +
    '</div></div>';
}());

(() => {
  const header = document.querySelector('.sb-header');
  if (!header) return;
  const toggle = header.querySelector('.sb-menu-toggle');
  const menus = [...header.querySelectorAll('.sb-menu')];
  header.classList.add('sb-enhanced');
  toggle.hidden = false;
  toggle.addEventListener('click', () => {
    const expanded = header.classList.toggle('sb-expanded');
    toggle.setAttribute('aria-expanded', String(expanded));
    toggle.textContent = expanded ? '닫기' : '메뉴';
  });
  menus.forEach(menu => menu.addEventListener('toggle', () => {
    if (menu.open) menus.filter(other => other !== menu).forEach(other => other.open = false);
  }));
  document.addEventListener('click', event => {
    menus.filter(menu => !menu.contains(event.target)).forEach(menu => menu.open = false);
  });
  header.addEventListener('keydown', event => {
    if (event.key !== 'Escape') return;
    const openMenu = menus.find(menu => menu.open);
    if (openMenu) { openMenu.open = false; openMenu.querySelector('summary').focus(); }
    else if (header.classList.contains('sb-expanded')) { toggle.click(); toggle.focus(); }
  });
  const base = new URL(header.querySelector('.sb-brand').href).pathname;
  const path = location.pathname.startsWith(base) ? location.pathname.slice(base.length) : '';
  const section = path.split('/')[0] || 'home';
  const active = [...header.querySelectorAll('[data-section]')].find(item => item.dataset.section === section);
  if (active?.tagName === 'DETAILS') active.classList.add('sb-current');
  else if (active && new URL(active.href).pathname === location.pathname) active.setAttribute('aria-current', 'page');
  header.querySelectorAll('.sb-dropdown a').forEach(link => {
    if (new URL(link.href).pathname === location.pathname) link.setAttribute('aria-current', 'page');
  });
})();

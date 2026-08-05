// cart.js — gemeinsamer Warenkorb für alle öffentlichen Seiten.
// Stellt window.HonigCart bereit. Speichert in localStorage, damit der Warenkorb
// auch nach dem Schließen des Tabs erhalten bleibt.
(function (global) {
  'use strict';

  var STORAGE_KEY = 'honig_cart';

  // '375' / '375g' -> '375g'
  function ensureG(w) {
    var s = String(w || '').trim();
    return s && !/g$/i.test(s) ? s + 'g' : s;
  }

  // '8,00 €' -> 8
  function parsePrice(p) {
    return parseFloat(String(p || '').replace(/[^0-9,.]/g, '').replace(',', '.')) || 0;
  }

  // 8 -> '8,00 €'
  function formatPrice(num) {
    return (Number(num) || 0).toFixed(2).replace('.', ',') + ' €';
  }

  function keyOf(item) {
    return ensureG(item && item.weight) + '|' + String((item && item.tracht) || '');
  }

  function getItems() {
    var raw;
    try {
      raw = JSON.parse(global.localStorage.getItem(STORAGE_KEY) || '[]');
    } catch (e) {
      raw = [];
    }
    if (!Array.isArray(raw)) return [];

    return raw
      .filter(function (i) { return i && i.weight && i.tracht; })
      .map(function (i) {
        return {
          weight:  ensureG(i.weight),
          tracht:  String(i.tracht),
          qty:     Math.max(1, parseInt(i.qty, 10) || 1),
          price:   String(i.price || ''),
          image:   i.image || ''
        };
      });
  }

  function save(items) {
    try {
      global.localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
    } catch (e) {
      // localStorage voll oder gesperrt (Privatmodus) – Warenkorb bleibt dann nur im Speicher.
    }
    renderBadge();
    return items;
  }

  // Gleiche Variante erneut hinzufügen -> Menge addieren statt Dublette anlegen.
  function addItem(item) {
    var items = getItems();
    var k     = keyOf(item);
    var qty   = Math.max(1, parseInt(item.qty, 10) || 1);
    var found = items.find(function (i) { return keyOf(i) === k; });

    if (found) {
      found.qty  += qty;
      found.price = String(item.price || found.price);
      if (item.image) found.image = item.image;
    } else {
      items.push({
        weight: ensureG(item.weight),
        tracht: String(item.tracht),
        qty:    qty,
        price:  String(item.price || ''),
        image:  item.image || ''
      });
    }
    return save(items);
  }

  function setQty(key, qty) {
    var n = parseInt(qty, 10) || 0;
    if (n <= 0) return removeItem(key);
    var items = getItems();
    var found = items.find(function (i) { return keyOf(i) === key; });
    if (found) found.qty = n;
    return save(items);
  }

  function removeItem(key) {
    return save(getItems().filter(function (i) { return keyOf(i) !== key; }));
  }

  function clear() {
    try {
      global.localStorage.removeItem(STORAGE_KEY);
    } catch (e) { /* siehe save() */ }
    renderBadge();
  }

  // Ersetzt den kompletten Inhalt (genutzt beim Bestandsabgleich in warenkorb.html).
  function replaceAll(items) {
    return save(Array.isArray(items) ? items : []);
  }

  function count() {
    return getItems().reduce(function (sum, i) { return sum + i.qty; }, 0);
  }

  function total() {
    return getItems().reduce(function (sum, i) { return sum + i.qty * parsePrice(i.price); }, 0);
  }

  // Aktualisiert jedes [data-cart-count]-Badge auf der Seite.
  function renderBadge() {
    var n = count();
    var badges = global.document.querySelectorAll('[data-cart-count]');
    for (var i = 0; i < badges.length; i++) {
      badges[i].textContent = String(n);
      badges[i].classList.toggle('hidden', n === 0);
    }
  }

  if (global.document.readyState === 'loading') {
    global.document.addEventListener('DOMContentLoaded', renderBadge);
  } else {
    renderBadge();
  }

  // Anderer Tab hat den Warenkorb geändert -> Badge nachziehen.
  global.addEventListener('storage', function (e) {
    if (e.key === STORAGE_KEY) renderBadge();
  });

  global.HonigCart = {
    getItems: getItems,
    addItem: addItem,
    setQty: setQty,
    removeItem: removeItem,
    replaceAll: replaceAll,
    clear: clear,
    count: count,
    total: total,
    keyOf: keyOf,
    ensureG: ensureG,
    parsePrice: parsePrice,
    formatPrice: formatPrice,
    renderBadge: renderBadge
  };
})(window);

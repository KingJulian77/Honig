(function () {
  var STORAGE_KEY = 'hah_cookie_consent';

  function getConsent() {
    return localStorage.getItem(STORAGE_KEY);
  }

  function setConsent(value) {
    localStorage.setItem(STORAGE_KEY, value);
    document.dispatchEvent(new CustomEvent('cookieConsentSet', { detail: { consent: value } }));
    var banner = document.getElementById('hah-cookie-banner');
    if (banner) banner.remove();
  }

  function injectBanner() {
    var banner = document.createElement('div');
    banner.id = 'hah-cookie-banner';
    banner.setAttribute('role', 'dialog');
    banner.setAttribute('aria-label', 'Cookie-Einstellungen');
    banner.style.cssText = [
      'position:fixed', 'bottom:0', 'left:0', 'right:0', 'z-index:9999',
      'background:#F5F0EB', 'border-top:1px solid #e2d9ce',
      'padding:20px 24px', 'display:flex', 'align-items:center',
      'justify-content:space-between', 'gap:16px', 'flex-wrap:wrap',
      'font-family:"DM Sans",sans-serif', 'font-size:13px', 'color:#1A1A1A',
      'box-shadow:0 -2px 16px rgba(0,0,0,0.07)'
    ].join(';');

    var text = document.createElement('p');
    text.style.cssText = 'margin:0;flex:1;min-width:200px;line-height:1.5;';
    text.innerHTML = 'Diese Website verwendet Cookies – u. a. von PayPal – für die sichere Zahlungsabwicklung. '
      + 'Weitere Infos in unserer <a href="datenschutz.html" style="color:#B8862A;text-decoration:underline;">Datenschutzerklärung</a>.';

    var buttons = document.createElement('div');
    buttons.style.cssText = 'display:flex;gap:10px;flex-shrink:0;';

    var btnNecessary = document.createElement('button');
    btnNecessary.textContent = 'Nur notwendige';
    btnNecessary.style.cssText = [
      'background:transparent', 'border:1px solid #B8862A', 'color:#B8862A',
      'padding:9px 18px', 'border-radius:999px', 'font-size:13px',
      'font-family:"DM Sans",sans-serif', 'cursor:pointer', 'white-space:nowrap',
      'transition:opacity 0.15s'
    ].join(';');
    btnNecessary.addEventListener('mouseover', function () { this.style.opacity = '0.75'; });
    btnNecessary.addEventListener('mouseout', function () { this.style.opacity = '1'; });
    btnNecessary.addEventListener('click', function () { setConsent('necessary'); });

    var btnAll = document.createElement('button');
    btnAll.textContent = 'Alle akzeptieren';
    btnAll.style.cssText = [
      'background:#B8862A', 'border:none', 'color:#fff',
      'padding:9px 18px', 'border-radius:999px', 'font-size:13px',
      'font-family:"DM Sans",sans-serif', 'cursor:pointer', 'white-space:nowrap',
      'transition:opacity 0.15s'
    ].join(';');
    btnAll.addEventListener('mouseover', function () { this.style.opacity = '0.85'; });
    btnAll.addEventListener('mouseout', function () { this.style.opacity = '1'; });
    btnAll.addEventListener('click', function () { setConsent('all'); });

    buttons.appendChild(btnNecessary);
    buttons.appendChild(btnAll);
    banner.appendChild(text);
    banner.appendChild(buttons);
    document.body.appendChild(banner);
  }

  // Public API
  window.cookieBanner = {
    getConsent: getConsent,
    reset: function () {
      localStorage.removeItem(STORAGE_KEY);
      injectBanner();
    }
  };

  if (!getConsent()) {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', injectBanner);
    } else {
      injectBanner();
    }
  }
})();

// Any comment. You must start the file with a single-line comment!

const { utils } = Components;

// https://support.mozilla.org/ja/questions/1342992#answer-1426736
try {
  const { Services } = utils.import("resource://gre/modules/Services.jsm");
  function ConfigJS() {
    Services.obs.addObserver(this, "chrome-document-global-created", false);
  }
  ConfigJS.prototype = {
    observe: function(subject) {
      subject.addEventListener("DOMContentLoaded", this, { once: true });
    },
    handleEvent: function(event) {
      const document = event.originalTarget;
      const window = document.defaultView;
      const location = window.location;
      if (
        /^(chrome:(?!\/\/(global\/content\/commonDialog|browser\/content\/webext-panels)\.x?html)|about:(?!blank))/i
          .test(location.href)
      ) {
        if (window._gBrowser) {
          const KEYS = ["key_close"];
          const ATTR = ["key", "modifiers", "command", "oncommand"];
          for (const key in KEYS) {
            const elm = window.document.getElementById(KEYS[key]);
            if (elm) { for (const attr in ATTR) if (ATTR[attr] in elm.attributes) elm.removeAttribute(ATTR[attr]); }
          }
        }
      }
    },
  };
  if (!Services.appinfo.inSafeMode) new ConfigJS();
} catch (e) {
  utils.reportError(e);
}

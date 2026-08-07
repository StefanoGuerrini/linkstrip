/**
 * LinkStrip Firefox extension — background script.
 *
 * Adds a context-menu item that copies the cleaned version of a link address.
 */

importScripts('cleaner.js');

browser.runtime.onInstalled.addListener(() => {
  loadRules().then(() => {
    browser.contextMenus.create({
      id: 'linkstrip-clean-link',
      title: 'Copy cleaned LinkStrip URL',
      contexts: ['link'],
      documentUrlPatterns: ['<all_urls>']
    });
  });
});

browser.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId !== 'linkstrip-clean-link') return;

  loadRules().then(() => {
    const original = info.linkUrl;
    if (!original) return;

    const cleaned = clean(original) || cleanURL(original) || original;

    navigator.clipboard.writeText(cleaned).then(() => {
      browser.notifications.create({
        type: 'basic',
        iconUrl: browser.runtime.getURL('icons/icon-128.png'),
        title: 'LinkStrip',
        message: 'Cleaned URL copied to clipboard'
      });
    }).catch(error => {
      console.error('LinkStrip: failed to copy cleaned URL:', error);
    });
  });
});

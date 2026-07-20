const BLOCKED = ["youtube.com", "deviantart.com"];

chrome.webNavigation.onBeforeNavigate.addListener((details) => {
  if (details.frameId !== 0) return;

  const url = new URL(details.url);

  const isBlocked = BLOCKED.some(site => url.hostname.includes(site));

  if (!isBlocked) return;

  chrome.storage.local.get(["bypass"], (data) => {
    const bypass = data.bypass || {};
    const now = Date.now();

    if (bypass[url.hostname] && bypass[url.hostname] > now) {
      return; // allow temporarily
    }

    const redirectUrl = chrome.runtime.getURL(
      `prompt.html?target=${encodeURIComponent(details.url)}`
    );

    chrome.tabs.update(details.tabId, { url: redirectUrl });
  });
});

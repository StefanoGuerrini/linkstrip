/**
 * LinkStrip Firefox extension — URL cleaning engine.
 *
 * This is a JavaScript port of the Swift URLCleaner used by the macOS app.
 * Both implementations share the same tracking-params.json rule file.
 */

let trackingParameters = new Set();
let rulesLoaded = false;
let rulesPromise = null;

/**
 * Loads the bundled tracking rules from tracking-params.json.
 * The file is copied into the extension root at build time.
 */
function loadRules() {
  if (rulesLoaded) return Promise.resolve();
  if (rulesPromise) return rulesPromise;

  rulesPromise = fetch(browser.runtime.getURL('tracking-params.json'))
    .then(response => response.json())
    .then(rules => {
      trackingParameters = new Set(rules.parameters);
      rulesLoaded = true;
    })
    .catch(error => {
      console.error('LinkStrip: failed to load tracking rules:', error);
      trackingParameters = new Set();
      rulesLoaded = true;
    });

  return rulesPromise;
}

/**
 * Strips known tracking query parameters from a URL string.
 * Returns the cleaned URL, the original URL if nothing changed, or null
 * when the input is not a valid http/https URL.
 */
function cleanURL(urlString) {
  const trimmed = urlString.trim();
  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
    return null;
  }

  try {
    const url = new URL(trimmed);
    const params = url.searchParams;
    const originalSize = params.size;

    if (originalSize === 0) {
      return trimmed;
    }

    let changed = false;
    for (const name of Array.from(params.keys())) {
      if (trackingParameters.has(name)) {
        params.delete(name);
        changed = true;
      }
    }

    if (!changed) {
      return urlString;
    }

    return url.toString();
  } catch {
    return null;
  }
}

/**
 * Extracts and cleans a destination URL from common redirect/click-tracking
 * services such as link.fndrsp.net.
 */
function cleanRedirect(urlString) {
  const decoded = decodeURIComponentSafe(urlString);

  const firstSchemeIndex = decoded.indexOf('://');
  if (firstSchemeIndex === -1) return null;

  const afterFirstScheme = decoded.slice(firstSchemeIndex + 3);
  const embeddedIndex = afterFirstScheme.indexOf('https://') !== -1
    ? afterFirstScheme.indexOf('https://')
    : afterFirstScheme.indexOf('http://');

  if (embeddedIndex === -1) {
    return cleanRedirectFromQuery(urlString);
  }

  let embedded = afterFirstScheme.slice(embeddedIndex);

  // Some services append routing/tracking path segments after the embedded URL
  // (e.g. .../1/<id>/<signature>). Strip the first such delimiter.
  for (const delimiter of ['/1/', '/2/']) {
    const delimiterIndex = embedded.indexOf(delimiter);
    if (delimiterIndex !== -1) {
      embedded = embedded.slice(0, delimiterIndex);
      break;
    }
  }

  const cleaned = cleanURL(embedded);
  return cleaned !== null ? cleaned : embedded;
}

/**
 * Fallback for redirect services that pass the destination in a query param.
 */
function cleanRedirectFromQuery(urlString) {
  try {
    const url = new URL(urlString);
    const redirectParamNames = new Set(['url', 'u', 'link', 'destination', 'target', 'redirect', 'to']);

    for (const [name, value] of url.searchParams) {
      if (!redirectParamNames.has(name.toLowerCase())) continue;
      const decoded = decodeURIComponentSafe(value);
      if (!decoded.startsWith('http://') && !decoded.startsWith('https://')) continue;
      const cleaned = cleanURL(decoded);
      if (cleaned !== null && cleaned !== decoded) return cleaned;
    }
  } catch {
    // ignore
  }
  return null;
}

/**
 * Decodes a percent-encoded string, returning the original string if decoding
 * fails.
 */
function decodeURIComponentSafe(value) {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

/**
 * Cleans a URL or redirect link. Returns the cleaned URL, or the original URL
 * if no cleaning was needed, or null if the input is not a valid URL.
 */
function clean(urlString) {
  const redirectCleaned = cleanRedirect(urlString);
  if (redirectCleaned) return redirectCleaned;

  const paramCleaned = cleanURL(urlString);
  if (paramCleaned && paramCleaned !== urlString) return paramCleaned;

  return null;
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { loadRules, cleanURL, cleanRedirect, clean };
}

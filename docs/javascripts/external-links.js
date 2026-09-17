// Open every external link in a new tab. Internal site links (same
// hostname) are left alone so in-site navigation still works normally,
// including Material's instant-navigation (no full page reload).
//
// document$ is provided by mkdocs-material and fires once per page view,
// including on instant-navigation transitions, so this re-runs correctly
// without needing a MutationObserver.
document$.subscribe(function () {
  document.querySelectorAll("a[href]").forEach(function (link) {
    var href = link.getAttribute("href");
    if (!href || href.startsWith("#") || href.startsWith("mailto:") || href.startsWith("tel:")) {
      return;
    }

    var url;
    try {
      url = new URL(href, window.location.href);
    } catch (e) {
      return;
    }

    if (url.hostname && url.hostname !== window.location.hostname) {
      link.setAttribute("target", "_blank");
      link.setAttribute("rel", "noopener noreferrer");
    }
  });
});

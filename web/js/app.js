(function () {
  "use strict";

  const CATEGORY_ORDER = ["syntax", "luau-specific", "semantic-traps", "formatting-extremes", "roblox", "detections"];
  const CATEGORY_LABEL = {
    "syntax": "syntax",
    "luau-specific": "luau-specific",
    "semantic-traps": "semantic-traps",
    "formatting-extremes": "formatting-extremes",
    "roblox": "roblox",
    "detections": "detections",
  };
  const DIFFICULTY_ORDER = ["trivial", "easy", "medium", "hard", "pathological"];
  const DIFF_VAR = {
    trivial: "--diff-trivial",
    easy: "--diff-easy",
    medium: "--diff-medium",
    hard: "--diff-hard",
    pathological: "--diff-pathological",
  };

  const state = {
    entries: [],
    filteredEntries: [],
    activeCategories: new Set(),
    activeDifficulties: new Set(),
    query: "",
    sortBy: "file",
    activeIndex: -1, // index into filteredEntries, for the open viewer
    sourceCache: new Map(),
  };

  const el = {
    search: document.getElementById("search"),
    statsBar: document.getElementById("stats-bar"),
    categoryFilters: document.getElementById("category-filters"),
    difficultyFilters: document.getElementById("difficulty-filters"),
    resetFilters: document.getElementById("reset-filters"),
    resultCount: document.getElementById("result-count"),
    sortSelect: document.getElementById("sort-select"),
    entryList: document.getElementById("entry-list"),
    entryTemplate: document.getElementById("entry-template"),
    emptyState: document.getElementById("empty-state"),
    emptyReset: document.getElementById("empty-reset"),
    errorState: document.getElementById("error-state"),
    errorDetail: document.getElementById("error-detail"),

    viewerBackdrop: document.getElementById("viewer-backdrop"),
    viewer: document.querySelector(".viewer"),
    viewerTitle: document.getElementById("viewer-title"),
    viewerPath: document.getElementById("viewer-path"),
    viewerMeta: document.getElementById("viewer-meta"),
    viewerDescription: document.getElementById("viewer-description"),
    viewerClose: document.getElementById("viewer-close"),
    codePane: document.getElementById("code-pane"),
    codeContent: document.getElementById("code-content"),
    viewerLoading: document.getElementById("viewer-loading"),
    viewerError: document.getElementById("viewer-error"),
    copyBtn: document.getElementById("copy-btn"),
    navPrev: document.getElementById("nav-prev"),
    navNext: document.getElementById("nav-next"),
  };

  function escapeHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }

  function escapeRegExp(s) {
    return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  function highlightMatch(text, query) {
    if (!query) return escapeHtml(text);
    const re = new RegExp("(" + escapeRegExp(query) + ")", "ig");
    return escapeHtml(text).replace(
      new RegExp("(" + escapeRegExp(escapeHtml(query)) + ")", "ig"),
      "<mark>$1</mark>"
    );
  }

  // ------------------------------------------------------------------ init

  async function init() {
    bindStaticEvents();
    try {
      const res = await fetch("/metadata/index.json");
      if (!res.ok) throw new Error("HTTP " + res.status);
      const data = await res.json();
      state.entries = (data.entries || []).map((e, i) => ({ ...e, _id: i }));
    } catch (err) {
      showError(err);
      return;
    }

    buildFilterChips();
    applyFilters();
    renderStats();
  }

  function showError(err) {
    el.errorState.hidden = false;
    el.errorDetail.textContent =
      "Fetching /metadata/index.json failed (" + err.message + "). " +
      "If you're opening this file directly, serve the repo root over HTTP instead — see web/README.md.";
    el.resultCount.textContent = "—";
  }

  // --------------------------------------------------------- filter chips

  function buildFilterChips() {
    const categoryCounts = countBy(state.entries, "category");
    el.categoryFilters.innerHTML = "";
    CATEGORY_ORDER.filter((c) => categoryCounts[c]).forEach((cat) => {
      el.categoryFilters.appendChild(
        makeChip(cat, CATEGORY_LABEL[cat] || cat, categoryCounts[cat], null, state.activeCategories, applyAll)
      );
    });

    const diffCounts = countBy(state.entries, "difficulty");
    el.difficultyFilters.innerHTML = "";
    DIFFICULTY_ORDER.filter((d) => diffCounts[d]).forEach((diff) => {
      el.difficultyFilters.appendChild(
        makeChip(diff, diff, diffCounts[diff], DIFF_VAR[diff], state.activeDifficulties, applyAll)
      );
    });
  }

  function countBy(list, key) {
    const out = {};
    for (const item of list) out[item[key]] = (out[item[key]] || 0) + 1;
    return out;
  }

  function makeChip(value, label, count, colorVar, activeSet, onChange) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "chip";
    btn.dataset.value = value;
    btn.setAttribute("aria-pressed", "false");

    const labelWrap = document.createElement("span");
    labelWrap.className = "chip-label";
    if (colorVar) {
      const dot = document.createElement("span");
      dot.className = "chip-dot";
      dot.style.background = "var(" + colorVar + ")";
      labelWrap.appendChild(dot);
    }
    const labelText = document.createElement("span");
    labelText.textContent = label;
    labelWrap.appendChild(labelText);

    const countEl = document.createElement("span");
    countEl.className = "chip-count";
    countEl.textContent = count;

    btn.appendChild(labelWrap);
    btn.appendChild(countEl);

    btn.addEventListener("click", () => {
      if (activeSet.has(value)) {
        activeSet.delete(value);
        btn.setAttribute("aria-pressed", "false");
      } else {
        activeSet.add(value);
        btn.setAttribute("aria-pressed", "true");
      }
      onChange();
    });

    return btn;
  }

  function applyAll() {
    applyFilters();
  }

  // -------------------------------------------------------------- filters

  function applyFilters() {
    const q = state.query.trim().toLowerCase();

    let list = state.entries.filter((e) => {
      if (state.activeCategories.size && !state.activeCategories.has(e.category)) return false;
      if (state.activeDifficulties.size && !state.activeDifficulties.has(e.difficulty)) return false;
      if (q) {
        const haystack = (
          e.file + " " + (e.tags || []).join(" ") + " " + (e.description || "")
        ).toLowerCase();
        if (!haystack.includes(q)) return false;
      }
      return true;
    });

    list = sortEntries(list, state.sortBy);
    state.filteredEntries = list;
    state.activeIndex = -1;
    renderList();
  }

  function sortEntries(list, by) {
    const diffRank = Object.fromEntries(DIFFICULTY_ORDER.map((d, i) => [d, i]));
    const catRank = Object.fromEntries(CATEGORY_ORDER.map((c, i) => [c, i]));
    const copy = list.slice();
    copy.sort((a, b) => {
      if (by === "difficulty") return diffRank[a.difficulty] - diffRank[b.difficulty] || a.file.localeCompare(b.file);
      if (by === "category") return catRank[a.category] - catRank[b.category] || a.file.localeCompare(b.file);
      return a.file.localeCompare(b.file);
    });
    return copy;
  }

  // ---------------------------------------------------------------- render

  function renderList() {
    el.entryList.innerHTML = "";
    const list = state.filteredEntries;

    el.resultCount.textContent =
      list.length === state.entries.length
        ? list.length + " entries"
        : list.length + " of " + state.entries.length + " entries";

    el.emptyState.hidden = list.length !== 0 || state.entries.length === 0;
    el.entryList.hidden = list.length === 0;

    const frag = document.createDocumentFragment();
    list.forEach((entry, idx) => {
      frag.appendChild(renderRow(entry, idx));
    });
    el.entryList.appendChild(frag);
  }

  function renderRow(entry, idx) {
    const node = el.entryTemplate.content.firstElementChild.cloneNode(true);
    node.dataset.index = idx;

    const mark = node.querySelector(".entry-diff-mark");
    mark.style.background = "var(" + DIFF_VAR[entry.difficulty] + ")";
    mark.title = "difficulty: " + entry.difficulty;

    node.querySelector(".entry-file").innerHTML = highlightMatch(entry.file, state.query);
    node.querySelector(".entry-desc").innerHTML = highlightMatch(entry.description || "", state.query);

    const tagsWrap = node.querySelector(".entry-tags");
    (entry.tags || []).forEach((tag) => {
      const t = document.createElement("span");
      t.className = "entry-tag";
      t.textContent = tag;
      tagsWrap.appendChild(t);
    });

    node.querySelector(".entry-category-badge").textContent = entry.category;

    node.addEventListener("click", () => openViewer(idx));
    node.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        openViewer(idx);
      }
    });

    return node;
  }

  function renderStats() {
    const total = state.entries.length;
    const catCounts = countBy(state.entries, "category");
    const diffCounts = countBy(state.entries, "difficulty");

    const parts = [`<span><span class="stat-value">${total}</span> total</span>`];
    CATEGORY_ORDER.filter((c) => catCounts[c]).forEach((c) => {
      parts.push(`<span>${c}: <span class="stat-value">${catCounts[c]}</span></span>`);
    });
    parts.push(
      "<span>" +
        DIFFICULTY_ORDER.filter((d) => diffCounts[d])
          .map((d) => d + " " + diffCounts[d])
          .join(" · ") +
        "</span>"
    );
    el.statsBar.innerHTML = parts.join("");
  }

  // ---------------------------------------------------------------- viewer

  async function openViewer(idx) {
    state.activeIndex = idx;
    const entry = state.filteredEntries[idx];
    if (!entry) return;

    el.viewerBackdrop.hidden = false;
    document.body.style.overflow = "hidden";

    const fileName = entry.file.split("/").pop();
    el.viewerTitle.textContent = fileName;
    el.viewerPath.textContent = entry.file;
    el.viewerDescription.textContent = entry.description || "";

    el.viewerMeta.innerHTML = "";
    el.viewerMeta.appendChild(metaPill("category", entry.category));
    el.viewerMeta.appendChild(metaPill("difficulty", entry.difficulty, DIFF_VAR[entry.difficulty]));

    el.copyBtn.textContent = "Copy source";
    el.codeContent.innerHTML = "";
    el.viewerError.hidden = true;
    el.viewerLoading.hidden = false;
    el.codePane.hidden = true;

    updateNavButtons();
    highlightActiveRow();

    try {
      const source = await loadSource(entry.file);
      el.viewerLoading.hidden = true;
      el.codePane.hidden = false;
      renderCode(source);
      el.copyBtn.onclick = () => copyToClipboard(source);
    } catch (err) {
      el.viewerLoading.hidden = true;
      el.viewerError.hidden = false;
      el.viewerError.textContent =
        "Couldn't load " + entry.file + " (" + err.message + ").";
    }

    el.viewerClose.focus();
  }

  function metaPill(label, value, colorVar) {
    const pill = document.createElement("span");
    pill.className = "meta-pill";
    if (colorVar) {
      const dot = document.createElement("span");
      dot.className = "chip-dot";
      dot.style.background = "var(" + colorVar + ")";
      pill.appendChild(dot);
    }
    const text = document.createElement("span");
    text.textContent = label + ": " + value;
    pill.appendChild(text);
    return pill;
  }

  async function loadSource(path) {
    if (state.sourceCache.has(path)) return state.sourceCache.get(path);
    const res = await fetch("/" + path);
    if (!res.ok) throw new Error("HTTP " + res.status);
    const text = await res.text();
    state.sourceCache.set(path, text);
    return text;
  }

  function renderCode(source) {
    const lines = source.replace(/\r\n/g, "\n").split("\n");
    const html = lines
      .map((line) => '<span class="code-line">' + window.highlightLuau(line) + "</span>")
      .join("\n");
    el.codeContent.innerHTML = html;
  }

  async function copyToClipboard(source) {
    try {
      await navigator.clipboard.writeText(source);
      el.copyBtn.textContent = "Copied";
    } catch {
      el.copyBtn.textContent = "Copy failed";
    }
    setTimeout(() => (el.copyBtn.textContent = "Copy source"), 1600);
  }

  function closeViewer() {
    el.viewerBackdrop.hidden = true;
    document.body.style.overflow = "";
    highlightActiveRow();
  }

  function updateNavButtons() {
    el.navPrev.disabled = state.activeIndex <= 0;
    el.navNext.disabled = state.activeIndex >= state.filteredEntries.length - 1;
  }

  function highlightActiveRow() {
    document.querySelectorAll(".entry-row").forEach((row) => {
      row.classList.toggle("is-active", Number(row.dataset.index) === state.activeIndex && !el.viewerBackdrop.hidden);
    });
  }

  function stepViewer(delta) {
    const next = state.activeIndex + delta;
    if (next < 0 || next >= state.filteredEntries.length) return;
    openViewer(next);
  }

  // ------------------------------------------------------------- bindings

  function bindStaticEvents() {
    el.search.addEventListener("input", (e) => {
      state.query = e.target.value;
      applyFilters();
    });

    el.sortSelect.addEventListener("change", (e) => {
      state.sortBy = e.target.value;
      applyFilters();
    });

    el.resetFilters.addEventListener("click", clearFilters);
    el.emptyReset.addEventListener("click", clearFilters);

    el.viewerClose.addEventListener("click", closeViewer);
    el.viewerBackdrop.addEventListener("click", (e) => {
      if (e.target === el.viewerBackdrop) closeViewer();
    });

    el.navPrev.addEventListener("click", () => stepViewer(-1));
    el.navNext.addEventListener("click", () => stepViewer(1));

    document.addEventListener("keydown", (e) => {
      const viewerOpen = !el.viewerBackdrop.hidden;
      const inSearch = document.activeElement === el.search;

      if (e.key === "/" && !inSearch && !viewerOpen) {
        e.preventDefault();
        el.search.focus();
        return;
      }

      if (e.key === "Escape" && viewerOpen) {
        closeViewer();
        return;
      }

      if (viewerOpen && (e.key === "ArrowDown" || e.key === "ArrowUp")) {
        e.preventDefault();
        stepViewer(e.key === "ArrowDown" ? 1 : -1);
        return;
      }

      if (!viewerOpen && !inSearch && (e.key === "ArrowDown" || e.key === "ArrowUp")) {
        const rows = Array.from(document.querySelectorAll(".entry-row"));
        if (!rows.length) return;
        const current = rows.findIndex((r) => r === document.activeElement);
        let nextIdx = current === -1 ? 0 : current + (e.key === "ArrowDown" ? 1 : -1);
        nextIdx = Math.max(0, Math.min(rows.length - 1, nextIdx));
        e.preventDefault();
        rows[nextIdx].focus();
        return;
      }

      if (!viewerOpen && !inSearch && (e.key === "Enter") && document.activeElement?.classList.contains("entry-row")) {
        openViewer(Number(document.activeElement.dataset.index));
      }
    });
  }

  function clearFilters() {
    state.activeCategories.clear();
    state.activeDifficulties.clear();
    state.query = "";
    el.search.value = "";
    document.querySelectorAll(".chip").forEach((c) => c.setAttribute("aria-pressed", "false"));
    applyFilters();
  }

  init();
})();

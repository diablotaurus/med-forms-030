"use strict";

/* ====================================================================
   Карта профилактического осмотра 030-ПО/у — динамические диагнозы
   (раздел 15 — простой, раздел 16 — расширенный)
   ==================================================================== */

const MAX_DIAG = 10;

const PLACES3 = [
    "в амбулаторных условиях;",
    "в условиях дневного стационара;",
    "в стационарных условиях.",
];

/* ---------- утилиты ---------- */
function esc(s) {
    return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}
function cb(name, key, label) {
    return `<label class="cb"><input type="checkbox" name="${name}" data-key="${key}"><span>${esc(label)}</span></label>`;
}
function fld(name, key, cls) {
    return `<input type="text" class="fld ${cls || ""}" name="${name}" data-key="${key}">`;
}
function places(section, i, sub, list) {
    return `<div class="opts indent">` +
        list.map((p, k) => cb(`d${section}_${i}_p${sub}_place${k}`, `p${sub}_place${k}`, p)).join("") +
        `</div>`;
}

/* ---------- блок диагноза раздела 15 (простой) ---------- */
function diag15Block(i) {
    return `
<div class="diag-block" data-section="15">
  <div class="diag-block-head">
    <span class="diag-title b"></span>
    <button type="button" class="btn btn-del no-print" data-del="15">– удалить</button>
  </div>
  <div class="row"><span class="b dlabel"></span> Диагноз: ${fld(`d15_${i}_diag`, "diag", "w100")}</div>
  <div class="row indent">код по МКБ: ${fld(`d15_${i}_mkb`, "mkb", "w200")}</div>
  <div class="row indent"><span class="slabel" data-sub="1"></span> Диспансерное наблюдение установлено:
    ${cb(`d15_${i}_disp_da`, "disp_da", "да")} / ${cb(`d15_${i}_disp_net`, "disp_net", "нет.")}</div>
</div>`;
}

/* ---------- блок диагноза раздела 16 (расширенный) ---------- */
function diag16Block(i) {
    return `
<div class="diag-block" data-section="16">
  <div class="diag-block-head">
    <span class="diag-title b"></span>
    <button type="button" class="btn btn-del no-print" data-del="16">– удалить</button>
  </div>
  <div class="row"><span class="b dlabel"></span> Диагноз: ${fld(`d16_${i}_diag`, "diag", "w100")}</div>
  <div class="row indent">код по МКБ: ${fld(`d16_${i}_mkb`, "mkb", "w200")}</div>
  <div class="row indent"><span class="slabel" data-sub="1"></span> Диагноз установлен впервые:
    ${cb(`d16_${i}_p1_da`, "p1_da", "да")} / ${cb(`d16_${i}_p1_net`, "p1_net", "нет.")}</div>
  <div class="row indent"><span class="slabel" data-sub="2"></span> Диспансерное наблюдение:</div>
  <div class="opts indent">
    ${cb(`d16_${i}_p2_ranee`, "p2_ranee", "установлено ранее;")}
    ${cb(`d16_${i}_p2_vpervye`, "p2_vpervye", "установлено впервые;")}
    ${cb(`d16_${i}_p2_net`, "p2_net", "не установлено.")}</div>
  <div class="row indent"><span class="slabel" data-sub="3"></span> Дополнительные консультации и исследования назначены:
    ${cb(`d16_${i}_p3_net`, "p3_net", "нет")} / ${cb(`d16_${i}_p3_da`, "p3_da", "да:")}</div>
  ${places(16, i, 3, PLACES3)}
  <div class="row indent"><span class="slabel" data-sub="4"></span> Дополнительные консультации и исследования выполнены:
    ${cb(`d16_${i}_p4_net`, "p4_net", "нет")} / ${cb(`d16_${i}_p4_da`, "p4_da", "да:")}</div>
  ${places(16, i, 4, PLACES3)}
  <div class="row indent"><span class="slabel" data-sub="5"></span> Лечение назначено:
    ${cb(`d16_${i}_p5_net`, "p5_net", "нет")} / ${cb(`d16_${i}_p5_da`, "p5_da", "да:")}</div>
  ${places(16, i, 5, PLACES3)}
  <div class="row indent"><span class="slabel" data-sub="6"></span> Медицинская реабилитация и (или) санаторно-курортное лечение назначены:
    ${cb(`d16_${i}_p6_net`, "p6_net", "нет")} / ${cb(`d16_${i}_p6_da`, "p6_da", "да:")}</div>
  ${places(16, i, 6, PLACES3)}
</div>`;
}

/* ---------- состояние ---------- */
const state = { 15: [], 16: [] };

function blockTemplate(section, i) {
    return section === 15 ? diag15Block(i) : diag16Block(i);
}

function collect(section) {
    const arr = [];
    document.querySelectorAll(`#diag${section}_container .diag-block`).forEach((block) => {
        const o = {};
        block.querySelectorAll("input, textarea").forEach((el) => {
            const key = el.dataset.key;
            if (!key) return;
            o[key] = el.type === "checkbox" ? el.checked : el.value;
        });
        arr.push(o);
    });
    return arr;
}

function render(section) {
    const cont = document.getElementById(`diag${section}_container`);
    cont.innerHTML = state[section].map((_, i) => blockTemplate(section, i)).join("");
    const blocks = cont.querySelectorAll(".diag-block");
    state[section].forEach((o, i) => {
        const block = blocks[i];
        block.querySelectorAll("input, textarea").forEach((el) => {
            const key = el.dataset.key;
            if (!(key in o)) return;
            if (el.type === "checkbox") el.checked = !!o[key];
            else el.value = o[key] == null ? "" : o[key];
        });
    });
    renumber();
}

function addDiag(section) {
    state[section] = collect(section);
    if (state[section].length >= MAX_DIAG) {
        alert("Можно добавить не более " + MAX_DIAG + " диагнозов.");
        return;
    }
    state[section].push({});
    render(section);
}

function delDiag(section, block) {
    state[section] = collect(section);
    if (state[section].length <= 1) {
        alert("Должен остаться хотя бы один диагноз.");
        return;
    }
    const blocks = Array.from(document.querySelectorAll(`#diag${section}_container .diag-block`));
    const idx = blocks.indexOf(block);
    state[section].splice(idx, 1);
    render(section);
}

function renumber() {
    [15, 16].forEach((section) => {
        const blocks = document.querySelectorAll(`#diag${section}_container .diag-block`);
        blocks.forEach((block, i) => {
            const num = `${section}.${2 + i}`;
            block.querySelector(".diag-title").textContent = `Диагноз № ${i + 1}`;
            block.querySelector(".dlabel").textContent = `${num}.`;
            block.querySelectorAll(".slabel").forEach((sp) => {
                sp.textContent = `${num}.${sp.dataset.sub}.`;
            });
        });
    });
    const n15 = state[15].length;
    const n16 = state[16].length;
    setLabel("group15_label", `15.${2 + n15}.`);
    setLabel("phys15_label", `15.${3 + n15}.`);
    setLabel("inv_label_po", `16.${2 + n16}.`);
    setLabel("group16_label_po", `16.${3 + n16}.`);
    setLabel("phys16_label_po", `16.${4 + n16}.`);
}
function setLabel(id, text) {
    const el = document.getElementById(id);
    if (el) el.textContent = text;
}

function buildStateFromData(data) {
    [15, 16].forEach((section) => {
        const byIndex = {};
        const re = new RegExp(`^d${section}_(\\d+)_(.+)$`);
        Object.keys(data || {}).forEach((k) => {
            const m = k.match(re);
            if (!m) return;
            const idx = parseInt(m[1], 10);
            byIndex[idx] = byIndex[idx] || {};
            byIndex[idx][m[2]] = data[k] === "on" ? true : data[k];
        });
        const indices = Object.keys(byIndex).map(Number).sort((a, b) => a - b);
        state[section] = indices.length ? indices.map((i) => byIndex[i]) : [{}];
    });
}

function populateStatic(data) {
    Object.keys(data || {}).forEach((name) => {
        if (/^d1[56]_\d+_/.test(name)) return; // диагнозы обрабатываются отдельно
        const els = document.getElementsByName(name);
        els.forEach((el) => {
            if (el.type === "checkbox") el.checked = data[name] === "on";
            else el.value = data[name];
        });
    });
}

/* ====================================================================
   Маски и проверка ввода (даты, СНИЛС)
   ==================================================================== */
function maskDate(v) {
    const d = v.replace(/\D/g, "").slice(0, 8);
    let out = d.slice(0, 2);
    if (d.length > 2) out += "." + d.slice(2, 4);
    if (d.length > 4) out += "." + d.slice(4, 8);
    return out;
}
function maskSnils(v) {
    const d = v.replace(/\D/g, "").slice(0, 11);
    let out = d.slice(0, 3);
    if (d.length > 3) out += "-" + d.slice(3, 6);
    if (d.length > 6) out += "-" + d.slice(6, 9);
    if (d.length > 9) out += " " + d.slice(9, 11);
    return out;
}
function isValidDate(s) {
    const m = /^(\d{2})\.(\d{2})\.(\d{4})$/.exec(s);
    if (!m) return false;
    const d = +m[1], mo = +m[2], y = +m[3];
    if (mo < 1 || mo > 12) return false;
    if (y < 1900 || y > 2100) return false;
    return d >= 1 && d <= new Date(y, mo, 0).getDate();
}
function isValidSnils(s) {
    const d = s.replace(/\D/g, "");
    if (d.length !== 11) return false;
    if (parseInt(d.slice(0, 9), 10) <= 1001998) return true;
    let sum = 0;
    for (let i = 0; i < 9; i++) sum += parseInt(d[i], 10) * (9 - i);
    let ctrl = sum % 101;
    if (ctrl === 100) ctrl = 0;
    return ctrl === parseInt(d.slice(9, 11), 10);
}
function fieldLabel(el) {
    const cont = el.closest(".row, .sub, .sec, .diag-block");
    let t = cont ? cont.textContent.replace(/\s+/g, " ").trim() : el.name;
    if (t.length > 70) t = t.slice(0, 70) + "…";
    return t;
}
function validateField(el) {
    const v = el.value.trim();
    if (v === "") return { ok: true };
    if (el.classList.contains("js-date")) {
        return isValidDate(v)
            ? { ok: true }
            : { ok: false, msg: "Некорректная дата «" + v + "» (нужен формат дд.мм.гггг) — " + fieldLabel(el) };
    }
    if (el.classList.contains("js-snils")) {
        return isValidSnils(v)
            ? { ok: true }
            : { ok: false, msg: "Некорректный СНИЛС «" + v + "» (формат ХХХ-ХХХ-ХХХ ХХ, 11 цифр, неверная контрольная сумма)" };
    }
    return { ok: true };
}
function markInvalid(el, msg) { el.classList.add("invalid"); el.title = msg || ""; }
function clearInvalid(el) { el.classList.remove("invalid"); el.removeAttribute("title"); }
function showSummary(list) {
    let box = document.getElementById("validation-summary");
    if (!box) {
        box = document.createElement("div");
        box.id = "validation-summary";
        box.className = "val-summary no-print";
        const sheet = document.querySelector(".sheet");
        sheet.parentNode.insertBefore(box, sheet);
    }
    box.innerHTML = "<b>Проверьте правильность заполнения:</b><ul>" +
        list.map((m) => "<li>" + esc(m) + "</li>").join("") + "</ul>";
    box.style.display = "block";
    box.scrollIntoView({ block: "center", behavior: "smooth" });
}
function hideSummary() {
    const box = document.getElementById("validation-summary");
    if (box) box.style.display = "none";
}
function attachMasks() {
    document.querySelectorAll(".js-date, .js-snils").forEach((el) => {
        const isDate = el.classList.contains("js-date");
        el.setAttribute("inputmode", "numeric");
        el.setAttribute("autocomplete", "off");
        el.maxLength = isDate ? 10 : 14;
        if (!el.placeholder) el.placeholder = isDate ? "дд.мм.гггг" : "ХХХ-ХХХ-ХХХ ХХ";
        el.value = isDate ? maskDate(el.value) : maskSnils(el.value);
        el.addEventListener("input", () => {
            el.value = isDate ? maskDate(el.value) : maskSnils(el.value);
            clearInvalid(el);
        });
        el.addEventListener("blur", () => {
            const r = validateField(el);
            if (r.ok) clearInvalid(el); else markInvalid(el, r.msg);
        });
    });
}
function validateAll() {
    const problems = [];
    document.querySelectorAll(".js-date, .js-snils").forEach((el) => {
        const r = validateField(el);
        if (r.ok) { clearInvalid(el); } else { markInvalid(el, r.msg); problems.push(r.msg); }
    });
    return problems;
}

/* ---------- авто-рост текстовых полей ---------- */
function autoGrow(el) {
    el.style.height = "auto";
    el.style.height = (el.scrollHeight + 2) + "px";
}
function autoGrowAll() {
    document.querySelectorAll("textarea.ta").forEach(autoGrow);
}

/* ---------- инициализация ---------- */
document.addEventListener("DOMContentLoaded", () => {
    const data = window.FORM_DATA || {};
    buildStateFromData(data);
    populateStatic(data);
    render(15);
    render(16);
    attachMasks();
    autoGrowAll();

    const cardForm = document.getElementById("cardForm");
    if (cardForm) {
        cardForm.addEventListener("submit", (e) => {
            const srv = document.getElementById("server-validation-summary");
            if (srv) srv.style.display = "none";
            const problems = validateAll();
            if (problems.length) {
                e.preventDefault();
                showSummary(problems);
                const first = document.querySelector(".fld.invalid");
                if (first) { first.focus(); first.scrollIntoView({ block: "center" }); }
            } else {
                hideSummary();
            }
        });
    }

    document.body.addEventListener("click", (e) => {
        const add = e.target.closest("[data-add]");
        if (add) { addDiag(parseInt(add.dataset.add, 10)); return; }
        const del = e.target.closest("[data-del]");
        if (del) { delDiag(parseInt(del.dataset.del, 10), del.closest(".diag-block")); return; }
    });

    document.body.addEventListener("input", (e) => {
        if (e.target.matches("textarea.ta")) autoGrow(e.target);
    });

    if (window.FORM_MODE === "print") {
        document.querySelectorAll("input, textarea").forEach((el) => {
            if (el.type === "checkbox") el.disabled = true;
            else el.setAttribute("readonly", "readonly");
        });
        window.addEventListener("load", () => setTimeout(() => window.print(), 400));
    }
});

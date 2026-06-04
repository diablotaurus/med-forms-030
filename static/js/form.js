/*
 * med-forms-030 — веб-приложение для учётных форм 030/у-Д/с и 030-ПО/у
 * Copyright (C) 2026 diablotaurus
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version. This program is distributed WITHOUT
 * ANY WARRANTY. See the GNU General Public License for more details:
 * <https://www.gnu.org/licenses/>.
 */
"use strict";

/* ====================================================================
   Карта диспансеризации 030/у-Д/с — динамические блоки диагнозов
   ==================================================================== */

const MAX_DIAG = 10;

const PLACES7 = [
    "в амбулаторных условиях;",
    "в условиях дневного стационара;",
    "в стационарных условиях;",
    "в муниципальных медицинских организациях;",
    "в государственных медицинских организациях субъекта Российской Федерации;",
    "в федеральных медицинских организациях;",
    "в частных медицинских организациях.",
];
const PLACES8 = PLACES7.slice(0, 6).concat([
    "в частных медицинских организациях;",
    "в санаторно-курортных организациях.",
]);

/* ---------- утилиты построения HTML ---------- */
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

/* ---------- шаблон блока диагноза раздела 16 ---------- */
function diag16Block(i) {
    return `
<div class="diag-block" data-section="16">
  <div class="diag-block-head">
    <span class="diag-title b"></span>
    <button type="button" class="btn btn-del no-print" data-del="16">– удалить</button>
  </div>
  <div class="row"><span class="b dlabel"></span> Диагноз: ${fld(`d16_${i}_diag`, "diag", "w100")}</div>
  <div class="row indent">код по МКБ: ${fld(`d16_${i}_mkb`, "mkb", "w200")}</div>
  <div class="row indent"><span class="slabel" data-sub="1"></span> Диспансерное наблюдение:
    ${cb(`d16_${i}_p1_ranee`, "p1_ranee", "установлено ранее")}
    ${cb(`d16_${i}_p1_vpervye`, "p1_vpervye", "установлено впервые")}
    ${cb(`d16_${i}_p1_net`, "p1_net", "не установлено.")}</div>
  <div class="row indent"><span class="slabel" data-sub="2"></span> Лечение было назначено:
    ${cb(`d16_${i}_p2_net`, "p2_net", "нет")} / ${cb(`d16_${i}_p2_da`, "p2_da", "да:")}</div>
  ${places(16, i, 2, PLACES7)}
  <div class="row indent"><span class="slabel" data-sub="3"></span> Лечение было выполнено:</div>
  ${places(16, i, 3, PLACES7)}
  <div class="row indent"><span class="slabel" data-sub="4"></span> Медицинская реабилитация и (или) санаторно-курортное лечение назначены:
    ${cb(`d16_${i}_p4_net`, "p4_net", "нет")} / ${cb(`d16_${i}_p4_da`, "p4_da", "да:")}</div>
  ${places(16, i, 4, PLACES8)}
  <div class="row indent"><span class="slabel" data-sub="5"></span> Медицинская реабилитация и (или) санаторно-курортное лечение выполнены:</div>
  ${places(16, i, 5, PLACES8)}
  <div class="row indent"><span class="slabel" data-sub="6"></span> Высокотехнологичная медицинская помощь рекомендована:
    ${cb(`d16_${i}_p6_net`, "p6_net", "нет")} / ${cb(`d16_${i}_p6_da`, "p6_da", "да:")}
    ${cb(`d16_${i}_p6_okazana`, "p6_okazana", "оказана")}
    ${cb(`d16_${i}_p6_neokazana`, "p6_neokazana", "не оказана.")}</div>
</div>`;
}

/* ---------- шаблон блока диагноза раздела 17 ---------- */
function diag17Block(i) {
    return `
<div class="diag-block" data-section="17">
  <div class="diag-block-head">
    <span class="diag-title b"></span>
    <button type="button" class="btn btn-del no-print" data-del="17">– удалить</button>
  </div>
  <div class="row"><span class="b dlabel"></span> Диагноз: ${fld(`d17_${i}_diag`, "diag", "w100")}</div>
  <div class="row indent">код по МКБ: ${fld(`d17_${i}_mkb`, "mkb", "w200")}</div>
  <div class="row indent"><span class="slabel" data-sub="1"></span> Диагноз установлен впервые:
    ${cb(`d17_${i}_p1_da`, "p1_da", "да")} / ${cb(`d17_${i}_p1_net`, "p1_net", "нет.")}</div>
  <div class="row indent"><span class="slabel" data-sub="2"></span> Диспансерное наблюдение:</div>
  <div class="opts indent">
    ${cb(`d17_${i}_p2_ranee`, "p2_ranee", "установлено ранее;")}
    ${cb(`d17_${i}_p2_vpervye`, "p2_vpervye", "установлено впервые;")}
    ${cb(`d17_${i}_p2_net`, "p2_net", "не установлено.")}</div>
  <div class="row indent"><span class="slabel" data-sub="3"></span> Дополнительные консультации и исследования назначены:
    ${cb(`d17_${i}_p3_da`, "p3_da", "да")} / ${cb(`d17_${i}_p3_net`, "p3_net", "нет, если «да»:")}</div>
  ${places(17, i, 3, PLACES7)}
  <div class="row indent"><span class="slabel" data-sub="4"></span> Дополнительные консультации и исследования выполнены:
    ${cb(`d17_${i}_p4_da`, "p4_da", "да")} / ${cb(`d17_${i}_p4_net`, "p4_net", "нет, если «да»:")}</div>
  ${places(17, i, 4, PLACES7)}
  <div class="row indent"><span class="slabel" data-sub="5"></span> Лечение назначено:
    ${cb(`d17_${i}_p5_da`, "p5_da", "да")} / ${cb(`d17_${i}_p5_net`, "p5_net", "нет, если «да»:")}</div>
  ${places(17, i, 5, PLACES7)}
  <div class="row indent"><span class="slabel" data-sub="6"></span> Медицинская реабилитация и (или) санаторно-курортное лечение назначены:
    ${cb(`d17_${i}_p6_da`, "p6_da", "да")} / ${cb(`d17_${i}_p6_net`, "p6_net", "нет, если «да»:")}</div>
  ${places(17, i, 6, PLACES8)}
  <div class="row indent"><span class="slabel" data-sub="7"></span> Высокотехнологичная медицинская помощь рекомендована:
    ${cb(`d17_${i}_p7_da`, "p7_da", "да")} / ${cb(`d17_${i}_p7_net`, "p7_net", "нет.")}</div>
</div>`;
}

/* ---------- состояние ---------- */
const state = { 16: [], 17: [] };  // массивы объектов {key: value|bool}

function blockTemplate(section, i) {
    return section === 16 ? diag16Block(i) : diag17Block(i);
}

/* собрать значения из DOM блоков в state */
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

/* отрисовать блоки секции из state и заполнить значениями */
function render(section) {
    const cont = document.getElementById(`diag${section}_container`);
    cont.innerHTML = state[section].map((_, i) => blockTemplate(section, i)).join("");
    // заполнить значениями
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
    autoGrowAll();
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

/* пересчёт номеров пунктов */
function renumber() {
    [16, 17].forEach((section) => {
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
    // зависимые номера после диагнозов
    const n16 = state[16].length;
    const n17 = state[17].length;
    setLabel("group16_label", `16.${2 + n16}.`);
    setLabel("inv_label", `17.${2 + n17}.`);
    setLabel("inv61_label", `17.${2 + n17}.1.`);
    setLabel("ipr_label", `17.${3 + n17}.`);
    setLabel("group17_label", `17.${4 + n17}.`);
    setLabel("vac_label", `17.${5 + n17}.`);
    setLabel("phys_label", `17.${6 + n17}.`);
    setLabel("rec1_label", `17.${7 + n17}.`);
    setLabel("rec2_label", `17.${8 + n17}.`);
}
function setLabel(id, text) {
    const el = document.getElementById(id);
    if (el) el.textContent = text;
}

/* ---------- разбор FORM_DATA в state ---------- */
function buildStateFromData(data) {
    [16, 17].forEach((section) => {
        const byIndex = {};
        const re = new RegExp(`^d${section}_(\\d+)_(.+)$`);
        Object.keys(data || {}).forEach((k) => {
            const m = k.match(re);
            if (!m) return;
            const idx = parseInt(m[1], 10);
            const key = m[2];
            byIndex[idx] = byIndex[idx] || {};
            // чекбоксы приходят как 'on'; текст — как строка
            byIndex[idx][key] = data[k] === "on" ? true : data[k];
        });
        const indices = Object.keys(byIndex).map(Number).sort((a, b) => a - b);
        state[section] = indices.length ? indices.map((i) => byIndex[i]) : [{}];
    });
}

/* ---------- заполнение статических полей ---------- */
function populateStatic(data) {
    Object.keys(data || {}).forEach((name) => {
        if (/^d1[67]_\d+_/.test(name)) return; // диагнозы обрабатываются отдельно
        const els = document.getElementsByName(name);
        els.forEach((el) => {
            if (el.type === "checkbox") el.checked = data[name] === "on";
            else el.value = data[name];
        });
    });
}

/* ---------- авто-рост текстовых полей ---------- */
function autoGrow(el) {
    el.style.height = "auto";
    el.style.height = (el.scrollHeight + 2) + "px";
}
function autoGrowAll() {
    document.querySelectorAll("textarea.ta").forEach(autoGrow);
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
    const daysInMonth = new Date(y, mo, 0).getDate();
    return d >= 1 && d <= daysInMonth;
}
function isValidSnils(s) {
    const d = s.replace(/\D/g, "");
    if (d.length !== 11) return false;
    const num = parseInt(d.slice(0, 9), 10);
    if (num <= 1001998) return true; // малые номера выдавались без контрольной суммы
    let sum = 0;
    for (let i = 0; i < 9; i++) sum += parseInt(d[i], 10) * (9 - i);
    let ctrl = sum % 101;
    if (ctrl === 100) ctrl = 0;
    return ctrl === parseInt(d.slice(9, 11), 10);
}

function fieldLabel(el) {
    // ближайший родитель .row/.sub/.sec даёт понятный текст
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
        // привести уже сохранённое значение к маске
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

/* ---------- инициализация ---------- */
document.addEventListener("DOMContentLoaded", () => {
    const data = window.FORM_DATA || {};
    buildStateFromData(data);
    populateStatic(data);
    render(16);
    render(17);
    attachMasks();

    // проверка перед сохранением
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

    // делегирование кнопок добавления/удаления
    document.body.addEventListener("click", (e) => {
        const add = e.target.closest("[data-add]");
        if (add) { addDiag(parseInt(add.dataset.add, 10)); return; }
        const del = e.target.closest("[data-del]");
        if (del) { delDiag(parseInt(del.dataset.del, 10), del.closest(".diag-block")); return; }
    });

    // авто-рост textarea при вводе
    document.body.addEventListener("input", (e) => {
        if (e.target.matches("textarea.ta")) autoGrow(e.target);
    });
    autoGrowAll();

    // режим печати: заблокировать поля и сразу открыть диалог печати
    if (window.FORM_MODE === "print") {
        document.querySelectorAll("input, textarea").forEach((el) => {
            if (el.type === "checkbox") el.disabled = true;
            else el.setAttribute("readonly", "readonly");
        });
        window.addEventListener("load", () => setTimeout(() => window.print(), 400));
    }
});

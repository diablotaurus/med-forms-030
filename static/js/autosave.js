/*
 * med-forms-030 — серверное автосохранение и защита от конфликтов.
 * Copyright (C) 2026 diablotaurus
 * GNU General Public License v3 or later.
 */
"use strict";

document.addEventListener("DOMContentLoaded", () => {
    if (window.FORM_MODE === "print") return;

    const form = document.getElementById("cardForm");
    const status = document.getElementById("autosaveStatus");
    const revisionInput = document.getElementById("formRevision");
    if (!form || !status || !revisionInput) return;

    let formId = window.FORM_ID || null;
    let revision = Number(window.FORM_REVISION || 0);
    let timer = null;
    let dirty = false;
    let saving = false;
    let conflicted = false;
    let submitting = false;
    let submitAfterSave = false;

    function setStatus(text, state = "") {
        status.textContent = text;
        status.className = `autosave-status ${state}`.trim();
    }

    function schedule(delay = 2000) {
        if (submitting || conflicted) return;
        clearTimeout(timer);
        timer = setTimeout(saveDraft, delay);
    }

    function markDirty() {
        if (submitting || conflicted) return;
        dirty = true;
        setStatus("Есть несохранённые изменения", "pending");
        schedule();
    }

    function savedTime(value) {
        const time = String(value || "").split(" ")[1];
        return time ? time.slice(0, 5) : new Date().toLocaleTimeString("ru-RU", {
            hour: "2-digit", minute: "2-digit"
        });
    }

    function activateDraft(result) {
        if (formId) return;
        formId = result.form_id;
        window.FORM_ID = formId;
        form.action = result.save_url;
        history.replaceState(null, "", result.edit_url);

        const title = document.getElementById("toolbarTitle");
        if (title && !title.textContent.includes("карта №")) {
            title.textContent += ` · карта №${formId} · черновик`;
        }
    }

    async function saveDraft() {
        clearTimeout(timer);
        if (!dirty || saving || submitting || conflicted) return;

        dirty = false;
        saving = true;
        setStatus("Сохранение…", "saving");

        const payload = new FormData(form);
        payload.set("_revision", String(revision));
        const url = formId ? `/form/${formId}/autosave` : `/forms/${window.FORM_TYPE}/autosave`;

        try {
            const response = await fetch(url, {
                method: "POST",
                body: payload,
                headers: {"X-Requested-With": "XMLHttpRequest"}
            });

            if (response.redirected || response.url.includes("/login")) {
                throw new Error("Сессия завершена. Войдите снова в соседней вкладке, затем продолжите работу.");
            }

            const result = await response.json();
            if (response.status === 409 || result.conflict) {
                conflicted = true;
                dirty = true;
                setStatus("Конфликт: карта изменена другим пользователем", "error");
                return;
            }
            if (!response.ok || !result.ok) {
                throw new Error(result.message || "Не удалось сохранить изменения.");
            }

            activateDraft(result);
            revision = Number(result.revision);
            revisionInput.value = String(revision);
            setStatus(`Сохранено в ${savedTime(result.saved_at)}`, "saved");
        } catch (error) {
            dirty = true;
            setStatus(error.message || "Ошибка автосохранения", "error");
            schedule(10000);
        } finally {
            saving = false;
            if (submitAfterSave && !conflicted) {
                submitAfterSave = false;
                form.requestSubmit();
            } else if (dirty && !conflicted) {
                schedule(10000);
            }
        }
    }

    form.addEventListener("input", (event) => {
        if (!event.target.matches("input, textarea, select")) return;
        if (event.target.name === "_revision") return;
        markDirty();
    });
    form.addEventListener("change", (event) => {
        if (event.target.name !== "_revision") markDirty();
    });
    document.addEventListener("click", (event) => {
        if (event.target.closest("[data-add], [data-del]")) {
            setTimeout(markDirty, 0);
        }
    });

    form.addEventListener("submit", (event) => {
        clearTimeout(timer);
        if (event.defaultPrevented) return;
        if (conflicted) {
            event.preventDefault();
            setStatus("Перезагрузите карту: обнаружен конфликт изменений", "error");
            return;
        }
        if (saving) {
            event.preventDefault();
            submitAfterSave = true;
            setStatus("Завершаю автосохранение…", "saving");
            return;
        }
        submitting = true;
    });

    window.addEventListener("beforeunload", (event) => {
        if ((!dirty && !saving) || submitting) return;
        event.preventDefault();
        event.returnValue = "";
    });
});

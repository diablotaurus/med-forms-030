import concurrent.futures
from contextlib import closing
import os
import sqlite3
import tempfile
import unittest

import app as application


class AutosaveTestCase(unittest.TestCase):
    def setUp(self):
        descriptor, self.db_path = tempfile.mkstemp(suffix=".db")
        os.close(descriptor)
        os.unlink(self.db_path)
        self.original_db_path = application.DB_PATH
        application.DB_PATH = self.db_path
        application.app.config.update(TESTING=True)
        application.init_db()

    def tearDown(self):
        application.DB_PATH = self.original_db_path
        for suffix in ("", "-wal", "-shm"):
            try:
                os.remove(self.db_path + suffix)
            except FileNotFoundError:
                pass

    def client(self):
        client = application.app.test_client()
        response = client.post("/login", data={"username": "admin", "password": "admin"})
        self.assertEqual(response.status_code, 302)
        return client

    def create_draft(self, client, form_type="030", fio="Черновик"):
        response = client.post(
            f"/forms/{form_type}/autosave",
            data={"_revision": "0", "patient_fio": fio, "birth_date": "01.01.2015"},
        )
        self.assertEqual(response.status_code, 200)
        return response.get_json()

    def test_draft_becomes_finished_card(self):
        client = self.client()
        draft = self.create_draft(client)
        response = client.post(
            f"/form/{draft['form_id']}",
            data={
                "_revision": draft["revision"],
                "patient_fio": "Готовая карта",
                "birth_date": "01.01.2015",
            },
        )
        self.assertEqual(response.status_code, 302)
        with closing(sqlite3.connect(self.db_path)) as db:
            row = db.execute(
                "SELECT is_draft, revision, patient_fio FROM forms WHERE id = ?",
                (draft["form_id"],),
            ).fetchone()
        self.assertEqual(row, (0, 2, "Готовая карта"))

    def test_stale_revision_cannot_overwrite_changes(self):
        first = self.client()
        second = self.client()
        draft = self.create_draft(first)
        revision = draft["revision"]

        saved = first.post(
            f"/form/{draft['form_id']}/autosave",
            data={"_revision": revision, "patient_fio": "Первый пользователь"},
        )
        stale = second.post(
            f"/form/{draft['form_id']}/autosave",
            data={"_revision": revision, "patient_fio": "Второй пользователь"},
        )
        self.assertEqual(saved.status_code, 200)
        self.assertEqual(stale.status_code, 409)
        self.assertTrue(stale.get_json()["conflict"])

    def test_five_sessions_can_create_different_drafts(self):
        def create(index):
            client = self.client()
            response = client.post(
                "/forms/030po/autosave",
                data={"_revision": 0, "patient_fio": f"Пользователь {index}"},
            )
            return response.status_code

        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
            statuses = list(pool.map(create, range(5)))
        self.assertEqual(statuses, [200] * 5)
        with closing(sqlite3.connect(self.db_path)) as db:
            count = db.execute("SELECT COUNT(*) FROM forms").fetchone()[0]
            journal_mode = db.execute("PRAGMA journal_mode").fetchone()[0]
        self.assertEqual(count, 5)
        self.assertEqual(journal_mode, "wal")


if __name__ == "__main__":
    unittest.main()

# -*- coding: utf-8 -*-
"""Создание согласованной резервной копии SQLite через Backup API."""
import os
import sqlite3
import sys


def main():
    if len(sys.argv) != 3:
        raise SystemExit("Использование: sqlite_backup.py ИСТОЧНИК НАЗНАЧЕНИЕ")
    source_path, target_path = map(os.path.abspath, sys.argv[1:])
    if not os.path.isfile(source_path):
        raise SystemExit(f"База не найдена: {source_path}")

    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    try:
        with sqlite3.connect(source_path, timeout=30) as source:
            source.execute("PRAGMA busy_timeout = 30000")
            with sqlite3.connect(target_path) as target:
                source.backup(target)
                result = target.execute("PRAGMA quick_check").fetchone()[0]
                if result != "ok":
                    raise RuntimeError(f"Проверка резервной копии: {result}")
    except Exception:
        if os.path.exists(target_path):
            os.remove(target_path)
        raise


if __name__ == "__main__":
    main()

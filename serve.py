# -*- coding: utf-8 -*-
#
# med-forms-030 — веб-приложение для учётных форм 030/у-Д/с и 030-ПО/у
# Copyright (C) 2026 diablotaurus
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License v3 (or any later version),
# as published by the Free Software Foundation. Distributed WITHOUT ANY
# WARRANTY. See <https://www.gnu.org/licenses/> for details.
"""
Производственный запуск приложения через WSGI-сервер waitress.

Используется на сервере (в т.ч. Windows Server) вместо встроенного
сервера разработки Flask.

Переменные окружения:
    HOST  — адрес прослушивания (по умолчанию 0.0.0.0 — все интерфейсы);
    PORT  — порт (по умолчанию 5000).

Запуск:
    python serve.py
"""
import os

from waitress import serve

from app import app, init_db

if __name__ == "__main__":
    init_db()
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", "5000"))
    threads = int(os.environ.get("THREADS", "8"))
    print(f"med-forms-030: запуск на http://{host}:{port} (threads={threads})")
    serve(app, host=host, port=port, threads=threads)

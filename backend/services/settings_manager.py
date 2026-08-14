"""Centralised settings manager for MediHive Marathi.

The SettingsManager is the single source of truth for application-wide
configuration.  It stores settings in the database ``settings`` table,
caches them in memory, and provides a simple ``get()`` / ``update()``
interface for the rest of the application.

Usage::

    from services.settings_manager import settings_manager

    # Read
    s = settings_manager.get()
    lang = s.language

    # Write
    settings_manager.update({"language": "mr", "theme": "dark"})

    # Listen for future changes
    def on_change(new_settings):
        print(f"Language changed to {new_settings.language}")
    settings_manager.subscribe(on_change)
"""

from __future__ import annotations

import threading
from typing import Callable, Optional

from database import get_db
from models.settings_model import SettingsModel
from services.log_service import get_logger

logger = get_logger(__name__)

# Type alias for setting-change listeners
_Listener = Callable[[SettingsModel], None]


class SettingsManager:
    """Singleton that loads, caches, persists and notifies about settings."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._settings: SettingsModel = SettingsModel.defaults()
        self._loaded = False
        self._listeners: list[_Listener] = []

    # ── Public API ───────────────────────────────────────────────

    def load(self) -> SettingsModel:
        """Load settings from the database and cache them in memory.

        Called automatically at application startup.  Safe to call
        multiple times — re-reads from DB on every call.
        """
        try:
            with get_db() as db:
                rows = db.execute(
                    "SELECT key, value FROM settings"
                ).fetchall()
            rows_list = [dict(r) for r in rows]
        except Exception:
            logger.warning("Could not read settings from DB � using defaults")
            rows_list = []

        if rows_list:
            self._settings = SettingsModel.from_db_rows(rows_list)
            logger.info("Settings loaded from DB: %s", self._settings.to_dict())
        else:
            self._settings = SettingsModel.defaults()
            logger.info("No settings in DB — using defaults")
            self._persist(self._settings)

        self._loaded = True
        return self._settings

    def get(self) -> SettingsModel:
        """Return the current (cached) settings.

        If ``load()`` has never been called, a lazy load is triggered.
        """
        if not self._loaded:
            return self.load()
        return self._settings

    def update(self, partial: dict) -> SettingsModel:
        """Apply a partial update and persist.

        ``partial`` is a dict of key-value pairs (e.g. ``{"language": "mr"}``).
        Only the keys present in ``partial`` are changed; everything else
        keeps its current value.

        Returns the new ``SettingsModel`` after saving.
        """
        current = self.get()
        merged_raw = current.to_dict()

        for k, v in partial.items():
            merged_raw[k] = v

        new_settings = SettingsModel.from_raw(merged_raw)
        self._persist(new_settings)
        self._settings = new_settings

        logger.info("Settings updated: %s", partial)
        self._notify(new_settings)
        return new_settings

    def reset(self) -> SettingsModel:
        """Reset all settings to defaults and persist."""
        defaults = SettingsModel.defaults()
        self._persist(defaults)
        self._settings = defaults
        logger.info("Settings reset to defaults")
        self._notify(defaults)
        return defaults

    # ── Listener support ─────────────────────────────────────────

    def subscribe(self, listener: _Listener) -> Callable[[], None]:
        """Register a callback that fires when settings change.

        Returns an ``unsubscribe`` callable so the listener can be
        removed when no longer needed (e.g. in a Flask ``teardown``).
        """
        self._listeners.append(listener)

        def unsubscribe() -> None:
            if listener in self._listeners:
                self._listeners.remove(listener)

        return unsubscribe

    # ── Internal helpers ─────────────────────────────────────────

    def _persist(self, settings: SettingsModel) -> None:
        """Write all settings rows to the database (upsert)."""
        rows = settings.to_db_rows()
        try:
            with get_db() as db:
                for row in rows:
                    db.execute(
                        """
                        INSERT INTO settings (key, value)
                        VALUES (%s, %s)
                        ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value
                        """,
                        (row["key"], row["value"]),
                    )
                db.commit()
        except Exception:
            db.rollback()
            logger.exception("Failed to persist settings")
            raise

    def _notify(self, settings: SettingsModel) -> None:
        for listener in self._listeners:
            try:
                listener(settings)
            except Exception:
                logger.exception("Settings listener failed")


# Module-level singleton
settings_manager = SettingsManager()

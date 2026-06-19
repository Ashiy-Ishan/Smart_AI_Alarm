"""Session-level patches that must be in place before main.py is imported."""
from unittest.mock import patch

# Prevent firebase_admin.initialize_app from looking for credentials at import time.
patch("firebase_admin.initialize_app").start()

# Prevent ensure_indexes() from opening a real MongoDB connection at startup.
patch("db.collections.ensure_indexes").start()

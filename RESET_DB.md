
# ☢️ The Nuclear Option: Reset Database

The "502 Bad Gateway" is happening because your Database Volume has **Old Settings** (from when we called it `vending_db`), but the new Code expects **New Settings** (`vending`).

This mismatch prevents the database from starting correctly, which prevents the Backend from starting.

Since we cannot access the Console to fix it manually, we must **Reset the Volume**.

## Instructions

1.  **Stop the Stack** in Portainer.
2.  Go to **Volumes** in the left sidebar.
3.  Find the volume named `vending_backpack_postgres_data` (or similar, look for `postgres_data`).
4.  **Select it and Click Remove.** (Confirm deletion).
5.  Go back to **Stacks** -> `vending-backpack`.
6.  **Start the Stack** (Deploy).

**Why this works:**
When Docker sees the volume is missing, it will create a brand new one. It will look at our YAML (`POSTGRES_DB: vending`) and create the correct database automatically.

## Final Check

Wait 30 seconds after deployment, then: `curl -s https://app.aldervon.com/health`

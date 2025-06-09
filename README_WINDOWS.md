# Skyvern - Windows Local Setup (No Docker)

This guide will help you set up and run Skyvern locally on a Windows machine **without Docker**.

---

## Prerequisites

- **Python 3.11–3.13** ([Download](https://www.python.org/downloads/))
- **pip** (comes with Python)
- **Node.js & npm** ([Download](https://nodejs.org/))
- **PostgreSQL** ([Download](https://www.postgresql.org/download/windows/))
- **Git Bash** (recommended) or PowerShell

---

## 1. Install PostgreSQL

1. Download and run the [PostgreSQL Windows installer](https://www.postgresql.org/download/windows/).
2. During setup, set:
   - **Username:** `skyvern`
   - **Password:** `skyvern`
   - **Database:** `skyvern`
   - **Port:** `5432` (default)
3. After install, ensure the PostgreSQL service is running (check with pgAdmin or Windows Services).
4. **Add PostgreSQL's `bin` directory to your `PATH`** so `psql`, `createuser`, and `createdb` are available in your terminal.

---

## 2. Clone the Repository

```sh
git clone <your-repo-url>
cd skyvern
```

---

## 3. Install Python and Node.js Dependencies

1. **Export Poetry dependencies to requirements.txt** (if not already present):
   ```sh
   poetry export -f requirements.txt --output requirements.txt --without-hashes
   ```
   *(Or ask your team for an up-to-date `requirements.txt`)*

2. **Install Python dependencies:**
   ```sh
   pip install -r requirements.txt
   ```

3. **Install frontend dependencies:**
   ```sh
   cd skyvern-frontend
   npm install
   cd ..
   ```

---

## 4. Configure Environment Variables

1. Copy `.env.example` to `.env` if not already present:
   ```sh
   cp .env.example .env
   ```
2. Ensure this line is in your `.env`:
   ```
   DATABASE_STRING=postgresql+psycopg://skyvern:skyvern@localhost:5432/skyvern
   ```

---

## 5. Run the Windows Setup Script

Open **PowerShell** in your project directory and run:

```powershell
./setup_windows.ps1
```

This will:
- Check for required tools
- Ensure PostgreSQL is running
- Create the `skyvern` user and database if needed
- Set the correct `DATABASE_STRING` in `.env`
- Install dependencies
- Run Alembic migrations
- Optionally create the organization and API token

---

## 6. Start the Application

**Backend:**
```sh
python run_skyvern.py
```

**Frontend:**
```sh
cd skyvern-frontend
npm run dev
```

---

## Troubleshooting

- **psql, createuser, or createdb not found?**
  - Add PostgreSQL's `bin` directory to your `PATH`.
- **PostgreSQL not running?**
  - Start it from the Start Menu or Windows Services.
- **pip install errors?**
  - Ensure you are using the correct Python version and have `requirements.txt`.
- **Other issues?**
  - Check your `.env` for typos or missing variables.
  - Ask for help in your team or open an issue.

---

## Notes
- This setup does **not** require Docker.
- For Bash users, you can use `setup_windows.sh` in Git Bash instead of PowerShell.
- For advanced users, WSL is also supported.

---

**You're ready to develop and run Skyvern locally on Windows!** 
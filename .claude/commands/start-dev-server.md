Start the Vite dev server in the background on port 8080.

Steps:
1. Check if anything is already listening on port 8080:
   ```bash
   lsof -iTCP:8080 -sTCP:LISTEN -P
   ```
   If a process is already there, report its PID and that the server is already running — do not kill it.

2. If port 8080 is free, start the dev server in the background:
   ```bash
   npm run dev
   ```
   Use `run_in_background: true` so the process keeps running after the command returns.

3. Wait a moment, then confirm the server is up by checking port 8080 is now listening.

4. Report:
   - Whether the server was already running or was freshly started
   - The PID of the server process
   - The URL: http://localhost:8080

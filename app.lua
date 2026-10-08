local socket = require("socket")

local server = assert(socket.bind("*", 8080))
print("Servidor rodando em http://localhost:8080")

local function handle_command(cmd)
    if cmd == "help" then
        return "Comandos: help, echo <msg>, date, clear"
    elseif cmd:sub(1,5) == "echo " then
        return cmd:sub(6)
    elseif cmd == "date" then
        return os.date("%Y-%m-%d %H:%M:%S")
    elseif cmd == "clear" then
        return "CLEAR"
    else
        return "Comando desconhecido: " .. cmd .. "\nDigite 'help' para ver os comandos."
    end
end

local function serve_html()
    return [[
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Terminal Lua</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: #1a1a1a; display: flex; justify-content: center; align-items: center; height: 100vh; }
  .terminal {
    width: 700px; height: 450px;
    background: #0d0d0d; border: 1px solid #333; border-radius: 8px;
    padding: 20px; font-family: 'Courier New', monospace;
    color: #0f0; overflow-y: auto; font-size: 14px;
  }
  .line { margin-bottom: 4px; }
  .prompt { color: #0f0; }
  .input-line { display: flex; }
  input {
    background: none; border: none; color: #0f0;
    font-family: inherit; font-size: inherit; outline: none; flex: 1;
  }
</style>
</head>
<body>
<div class="terminal" id="terminal">
  <div class="line">Bem-vindo ao Terminal Lua. Digite 'help' para começar.</div>
  <div class="line input-line">
    <span class="prompt">user@lua:~$ </span>
    <input id="cmd" autofocus autocomplete="off">
  </div>
</div>
<script>
const terminal = document.getElementById('terminal');
const input = document.getElementById('cmd');

async function send() {
  const cmd = input.value.trim();
  if (!cmd) return;
  input.value = '';

  const lineEl = input.closest('.line');
  lineEl.classList.remove('input-line');
  lineEl.innerHTML = '<span class="prompt">user@lua:~$ </span>' + cmd;

  if (cmd === 'clear') {
    terminal.innerHTML = '';
  }

  const res = await fetch('/cmd?c=' + encodeURIComponent(cmd));
  const text = await res.text();
  if (text !== 'CLEAR') {
    text.split('\n').forEach(t => {
      const d = document.createElement('div');
      d.className = 'line';
      d.textContent = t;
      terminal.insertBefore(d, lineEl);
    });
  }

  terminal.scrollTop = terminal.scrollHeight;
}

input.addEventListener('keydown', e => {
  if (e.key === 'Enter') send();
});
</script>
</body>
</html>
]]
end

while true do
    local client = server:accept()
    local request = client:receive("*l")
    local path = request:match("GET (%S+)")

    if path == "/" or path == "/index.html" then
        local html = serve_html()
        client:send("HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: " .. #html .. "\r\n\r\n" .. html)
    elseif path and path:sub(1,5) == "/cmd" then
        local cmd = path:match("c=([^&]+)")
        if cmd then
            cmd = socket.urldecode(cmd)
            local response = handle_command(cmd)
            client:send("HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: " .. #response .. "\r\n\r\n" .. response)
        end
    else
        client:send("HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n")
    end
    client:close()
end   
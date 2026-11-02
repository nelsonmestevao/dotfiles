// One shell script per machine per refresh: load, memory, disk, uptime and docker containers,
// as key=value lines (c= lines are tab-separated containers). Linux and macOS.
export const PROBE = `
echo "os=$(uname -s)"
if [ -r /proc/loadavg ]; then echo "load=$(cut -d' ' -f1-3 /proc/loadavg)"; else echo "load=$(sysctl -n vm.loadavg | tr -d '{}')"; fi
echo "cpus=$(nproc 2>/dev/null || sysctl -n hw.ncpu)"
if command -v free >/dev/null 2>&1; then free -b | awk '/^Mem:/{print "mem="$2" "$7}'
elif command -v vm_stat >/dev/null 2>&1; then echo "mem=$(sysctl -n hw.memsize) $(vm_stat | awk '/page size of/{ps=$8} /Pages free/{f=$3} /Pages inactive/{i=$3} /Pages speculative/{s=$3} END{print (f+i+s)*ps}')"; fi
df -Pk / | awk 'NR==2{print "disk="$2" "$3" "$4}'
if [ -r /proc/uptime ]; then echo "uptime=$(cut -d' ' -f1 /proc/uptime)"; else echo "uptime=$(( $(date +%s) - $(sysctl -n kern.boottime | awk -F'[ ,]+' '{print $4}') ))"; fi
if command -v docker >/dev/null 2>&1; then
  if out=$(docker ps -a --format '{{.ID}}\\t{{.Names}}\\t{{.State}}\\t{{.Status}}\\t{{.Image}}\\t{{.Label "com.docker.compose.project"}}' 2>&1); then
    printf '%s\\n' "$out" | sed '/^$/d; s/^/c=/'
  else echo "docker_err=$(printf '%s' "$out" | head -1)"; fi
else echo "docker_err=not installed"; fi
`;

const number = (text) => Number(String(text).trim().replace(",", "."));

function parseContainer(line) {
  const [id, name, state, status, image, project] = line.split("\t");
  return { id, name, state, status, image, project: project || "" };
}

// { load: [1m, 5m, 15m], cpus, mem: { total, available } | null, disk: { total, used, free } (bytes),
//   uptime (s), docker: { error } | { containers } }.
export function parseProbe(out) {
  const result = { load: null, cpus: null, mem: null, disk: null, uptime: null, docker: { containers: [] } };
  for (const line of out.split("\n")) {
    const at = line.indexOf("=");
    if (at < 0) continue;
    const key = line.slice(0, at), value = line.slice(at + 1);
    const parts = value.trim().split(/\s+/).map(number);
    if (key === "load") result.load = parts.slice(0, 3);
    if (key === "cpus") result.cpus = parts[0];
    if (key === "mem" && parts.length === 2) result.mem = { total: parts[0], available: parts[1] };
    if (key === "disk") result.disk = { total: parts[0] * 1024, used: parts[1] * 1024, free: parts[2] * 1024 };
    if (key === "uptime") result.uptime = parts[0];
    if (key === "c") result.docker.containers.push(parseContainer(value));
    if (key === "docker_err") result.docker = { error: /permission denied/i.test(value) ? "no permission" : value.trim() };
  }
  return result;
}

// ok | starting | stopped (exited 0) | unhealthy | restarting | down | the docker state.
export function containerHealth(c) {
  if (c.state === "running") {
    if (/\(unhealthy\)/.test(c.status)) return "unhealthy";
    return /health: starting/.test(c.status) ? "starting" : "ok";
  }
  if (c.state === "restarting") return "restarting";
  if (c.state === "exited" || c.state === "dead") return /^Exited \(0\)/.test(c.status) ? "stopped" : "down";
  return c.state;
}

export const needsAttention = (c) => ["unhealthy", "restarting", "down"].includes(containerHealth(c));

// Percentages for the three meters; null when the machine didn't say.
export function usage(stats) {
  const pct = (part, whole) => (whole > 0 ? Math.min(100, Math.round((part / whole) * 100)) : null);
  return {
    cpu: stats.load && stats.cpus ? pct(stats.load[0], stats.cpus) : null,
    mem: stats.mem ? pct(stats.mem.total - stats.mem.available, stats.mem.total) : null,
    disk: stats.disk ? pct(stats.disk.used, stats.disk.used + stats.disk.free) : null,
  };
}

// Containers that went bad, or came back, between two looks at one machine. The first look says nothing.
export function containerAlerts(before, after) {
  if (!before?.docker?.containers || !after?.docker?.containers) return [];
  const was = new Map(before.docker.containers.map((c) => [c.name, needsAttention(c)]));
  return after.docker.containers.flatMap((c) => {
    if (!was.has(c.name) || was.get(c.name) === needsAttention(c)) return [];
    return [{ name: c.name, health: containerHealth(c), down: needsAttention(c) }];
  });
}

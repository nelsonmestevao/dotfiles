// Made-up machines for screenshots ({ demo: true }): no real hosts or container names.
const GB = 1024 ** 3;
const container = (name, project, state, status, image) => ({ id: name, name, project, state, status, image });

export const DEMO = [
  {
    name: "web-prod",
    stats: {
      load: [0.42, 0.38, 0.35], cpus: 4, uptime: 41 * 86400,
      mem: { total: 16 * GB, available: 9.5 * GB }, disk: { total: 200 * GB, used: 71 * GB, free: 129 * GB },
      docker: { containers: [
        container("shop-web", "shop", "running", "Up 3 days (healthy)", "shop/web:4.2.0"),
        container("shop-worker", "shop", "running", "Up 3 days (unhealthy)", "shop/worker:4.2.0"),
        container("shop-db", "shop", "running", "Up 3 weeks (healthy)", "postgres:16"),
        container("blog", "blog", "running", "Up 12 days", "ghost:5"),
        container("traefik", "edge", "running", "Up 6 weeks", "traefik:v3"),
      ] },
    },
  },
  {
    name: "build-box",
    stats: {
      load: [3.6, 2.9, 2.1], cpus: 4, uptime: 9 * 86400,
      mem: { total: 8 * GB, available: 1.4 * GB }, disk: { total: 80 * GB, used: 69 * GB, free: 11 * GB },
      docker: { containers: [
        container("runner-1", "ci", "running", "Up 9 days", "gh-runner:2.3"),
        container("runner-2", "ci", "exited", "Exited (137) 2 hours ago", "gh-runner:2.3"),
        container("cache", "ci", "running", "Up 9 days (healthy)", "redis:7"),
      ] },
    },
  },
  {
    name: "home-lab",
    stats: {
      load: [0.9, 0.7, 0.6], cpus: 20, uptime: 25 * 86400,
      mem: { total: 32 * GB, available: 21 * GB }, disk: { total: 1000 * GB, used: 92 * GB, free: 908 * GB },
      docker: { error: "no permission" },
    },
  },
];

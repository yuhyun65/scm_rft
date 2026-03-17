import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

const proxyTarget = process.env.VITE_GATEWAY_PROXY_TARGET ?? "http://localhost:18080";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "node"
  },
  server: {
    host: "0.0.0.0",
    port: 5173,
    strictPort: true,
    proxy: {
      "/api": {
        target: proxyTarget,
        changeOrigin: true,
        secure: false
      }
    }
  }
});

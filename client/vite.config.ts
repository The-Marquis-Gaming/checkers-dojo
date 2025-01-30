import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";
import topLevelAwait from "vite-plugin-top-level-await";
import wasm from "vite-plugin-wasm";
import mkcert from "vite-plugin-mkcert";
//if we import this plugin we can use the controller without ngrok

// https://vitejs.dev/config/
export default defineConfig({
    server: {
        host: "127.0.0.1",
        port: 5173
    },
    plugins: [react(), wasm(), topLevelAwait(), mkcert()],
});

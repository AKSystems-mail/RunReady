#!/usr/bin/env python3
"""Simple HTTP server for APK download - sets proper Android download headers."""
import http.server
import os
import socket

APK_PATH = os.path.expanduser(
    "~/dev/RunFinder/runready/build/app/outputs/flutter-apk/app-release.apk"
)

class APKHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.path.dirname(APK_PATH), **kwargs)

    def do_GET(self):
        if self.path == "/" or self.path == "":
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            apk_size = os.path.getsize(APK_PATH)
            self.wfile.write(f"""
<html><body style="background:#1a1a2e;color:white;font-family:sans-serif;padding:2rem">
<h2>RunFinder APK</h2>
<p><a href="/app-release.apk" style="color:#60a5fa;font-size:1.2rem">⬇ Download app-release.apk ({apk_size / 1e6:.1f} MB)</a></p>
<p>Host: {socket.gethostname()} | IP: {socket.gethostbyname(socket.gethostname())}</p>
</body></html>""".encode())
            return
        super().do_GET()

    def guess_type(self, path):
        if path.endswith(".apk"):
            return "application/vnd.android.package-archive"
        return super().guess_type(path)

    def end_headers(self):
        if self.path.endswith(".apk"):
            self.send_header("Content-Disposition", 'attachment; filename="runready-release.apk"')
            self.send_header("Accept-Ranges", "bytes")
            self.send_header("Cache-Control", "no-cache")
        super().end_headers()


if __name__ == "__main__":
    port = 8080
    server = http.server.HTTPServer(("0.0.0.0", port), APKHandler)
    print(f"Serving APK at http://0.0.0.0:{port}/app-release.apk")
    print(f"Local IP: {socket.gethostbyname(socket.gethostname())}")
    print(f"APK: {APK_PATH} ({os.path.getsize(APK_PATH) / 1e6:.1f} MB)")
    print("---")
    server.serve_forever()

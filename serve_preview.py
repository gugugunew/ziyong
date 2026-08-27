import http.server
import socketserver
import os
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8090
ROOT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(__file__), 'build', 'web')

class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

os.chdir(ROOT)
print(f'[serve] {ROOT} -> http://127.0.0.1:{PORT}')
with socketserver.TCPServer(('127.0.0.1', PORT), NoCacheHandler) as httpd:
    httpd.serve_forever()

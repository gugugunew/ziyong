import os
import re
import sys
import time

root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), 'build', 'web')
index = os.path.join(root, 'index.html')

if not os.path.exists(index):
    print(f"[patch_build] index.html not found at {index}")
    sys.exit(1)

with open(index, 'r', encoding='utf-8') as f:
    html = f.read()

    # 1. 强制 flutter_bootstrap.js 禁用 service worker，避免缓存和旧版本不刷新
    js_path = os.path.join(root, 'flutter_bootstrap.js')
    if os.path.exists(js_path):
        with open(js_path, 'r', encoding='utf-8') as f:
            js = f.read()
        if 'window.flutterConfiguration' not in js:
            js = js.replace(
                '"use strict";',
                '"use strict";\nwindow.flutterConfiguration = window.flutterConfiguration || {};\nwindow.flutterConfiguration.serviceWorkerSettings = {enabled: false};',
            )
        with open(js_path, 'w', encoding='utf-8') as f:
            f.write(js)
        print('[patch_build] patched flutter_bootstrap.js')

# 2. 写入构建 ID，用于 wrapper 页面判断刷新
build_id = str(int(time.time() * 1000))
with open(os.path.join(root, '__build_id.txt'), 'w', encoding='utf-8') as f:
    f.write(build_id)

# 3. 确保 index.html 里 viewport 正确、没有 PWA cache
html = re.sub(r'<meta name="apple-mobile-web-app-capable"[^>]*>', '', html)
html = re.sub(r'<meta name="apple-mobile-web-app-status-bar-style"[^>]*>', '', html)
html = html.replace(
    '<head>',
    '<head>\n  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">\n  <meta http-equiv="Pragma" content="no-cache">\n  <meta http-equiv="Expires" content="0">',
)

with open(index, 'w', encoding='utf-8') as f:
    f.write(html)

print(f'[patch_build] done -> {root} (build_id={build_id})')

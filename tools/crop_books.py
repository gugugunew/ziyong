import os
import sys
import cv2
import numpy as np
from pathlib import Path

# 输入：剪贴板图片目录（用户上传的 8 张图）
INPUT_DIR = Path(r"C:\Users\king\.workbuddy\clipboard-images")
# 输出：项目资源目录
OUT_DIR = Path(r"C:\Users\king\Desktop\2\assets\images")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# 文件名映射（按上传顺序）
NAMES = [
    "xiaoxue_english_vocabulary",
    "renjiao_english_reader",
    "yilin_edition",
    "waiyan_edition",
    "jiaoke_edition",
    "beishida_edition",
    "hujiao_edition",
    "luke_edition",
]

def find_book_quad(img):
    """在图中找最大四边形（书封面），返回四边形顶点（原图坐标）。"""
    h, w = img.shape[:2]
    scale = 600.0 / max(w, h)
    small = cv2.resize(img, None, fx=scale, fy=scale)
    gray = cv2.cvtColor(small, cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray, (5, 5), 0)
    edges = cv2.Canny(gray, 50, 150)
    edges = cv2.dilate(edges, np.ones((5, 5), np.uint8), iterations=2)

    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return None

    # 优先找面积最大且接近四边形的轮廓
    best = None
    best_score = -1
    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area < (small.shape[0] * small.shape[1] * 0.05):
            continue
        peri = cv2.arcLength(cnt, True)
        approx = cv2.approxPolyDP(cnt, 0.05 * peri, True)
        # 评分：面积越大越好，顶点越接近 4 越好
        vertex_score = 1.0 if len(approx) == 4 else (0.6 if len(approx) == 5 else 0.3)
        score = area * vertex_score
        if score > best_score:
            best_score = score
            best = approx

    if best is None:
        return None

    # 如果顶点不是 4 个，用最小外接矩形兜底
    if len(best) != 4:
        rect = cv2.minAreaRect(best)
        box = cv2.boxPoints(rect)
        best = box.reshape(4, 1, 2)

    # 缩放回原始尺寸
    quad = (best.reshape(-1, 2) / scale).astype(np.float32)
    return order_points(quad)

def order_points(pts):
    """按左上、右上、右下、左下排序。"""
    rect = np.zeros((4, 2), dtype=np.float32)
    s = pts.sum(axis=1)
    diff = np.diff(pts, axis=1)
    rect[0] = pts[np.argmin(s)]   # 左上
    rect[2] = pts[np.argmax(s)]   # 右下
    rect[1] = pts[np.argmin(diff)] # 右上
    rect[3] = pts[np.argmax(diff)] # 左下
    return rect

def crop_perspective(img, quad, pad=0):
    """根据四边形做透视变换，输出矩形书封面。"""
    (tl, tr, br, bl) = quad
    # 计算输出宽度
    width_a = np.sqrt(((br[0] - bl[0]) ** 2) + ((br[1] - bl[1]) ** 2))
    width_b = np.sqrt(((tr[0] - tl[0]) ** 2) + ((tr[1] - tl[1]) ** 2))
    max_width = max(int(width_a), int(width_b))
    height_a = np.sqrt(((tr[0] - br[0]) ** 2) + ((tr[1] - br[1]) ** 2))
    height_b = np.sqrt(((tl[0] - bl[0]) ** 2) + ((tl[1] - bl[1]) ** 2))
    max_height = max(int(height_a), int(height_b))

    dst = np.array([
        [0, 0],
        [max_width - 1, 0],
        [max_width - 1, max_height - 1],
        [0, max_height - 1]], dtype=np.float32)

    M = cv2.getPerspectiveTransform(quad, dst)
    warped = cv2.warpPerspective(img, M, (max_width, max_height))
    return warped

def trim_background(warped, threshold=240):
    """透视后如果四角还有背景白边，按内容做内切裁剪。"""
    if warped.shape[0] < 50 or warped.shape[1] < 50:
        return warped
    gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
    # 非背景掩码
    mask = gray < threshold
    rows = np.any(mask, axis=1)
    cols = np.any(mask, axis=0)
    rmin, rmax = np.where(rows)[0][[0, -1]]
    cmin, cmax = np.where(cols)[0][[0, -1]]
    return warped[rmin:rmax+1, cmin:cmax+1]

def process_one(src_path, name):
    img = cv2.imread(str(src_path), cv2.IMREAD_COLOR)
    if img is None:
        print(f"[跳过] 无法读取 {src_path}")
        return None
    quad = find_book_quad(img)
    if quad is None:
        print(f"[兜底] {name}: 未检测到书，使用中心 80% 裁剪")
        h, w = img.shape[:2]
        cropped = img[int(h*0.1):int(h*0.9), int(w*0.1):int(w*0.9)]
    else:
        cropped = crop_perspective(img, quad)
        cropped = trim_background(cropped)
    out_path = OUT_DIR / f"{name}.jpg"
    cv2.imwrite(str(out_path), cropped, [int(cv2.IMWRITE_JPEG_QUALITY), 92])
    print(f"[完成] {out_path}  {cropped.shape[1]}x{cropped.shape[0]}")
    return out_path

def main():
    files = sorted([p for p in INPUT_DIR.glob("clipboard-2026-08-24T16-25-48-*.png") if p.is_file()])
    if len(files) < len(NAMES):
        print(f"警告：只找到 {len(files)} 张图，期望 {len(NAMES)} 张")
    for i, src in enumerate(files[:len(NAMES)]):
        process_one(src, NAMES[i])

if __name__ == "__main__":
    main()

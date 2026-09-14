import re

def parse_sfd(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        content = f.read()
    blocks = {}
    for m in re.finditer(r"^StartChar: (.+?)\n(.*?)^EndChar\n", content, re.S | re.M):
        blocks[m.group(1).strip()] = m.group(2)
    return blocks

def parse_splineset(block):
    fore_match = re.search(r"^Fore\n(.*?)^EndSplineSet\n", block, re.S | re.M)
    if not fore_match:
        return []
    body = fore_match.group(1)
    ss_match = re.search(r"^SplineSet\n(.*)", body, re.S | re.M)
    lines = ss_match.group(1).strip("\n").split("\n") if ss_match else []
    contours = []
    current = []
    for line in lines:
        line = line.strip()
        if not line:
            continue
        parts = line.split()
        cmd = parts[-2]
        nums = [float(x) for x in parts[:-2]]
        if cmd == "m":
            if current:
                contours.append(current)
            current = [("move", (nums[0], nums[1]))]
        elif cmd == "l":
            current.append(("line", (nums[0], nums[1])))
        elif cmd == "c":
            current.append(("curve", (nums[0], nums[1]), (nums[2], nums[3]), (nums[4], nums[5])))
        else:
            raise ValueError(f"Unhandled spline command: {cmd!r} in line: {line!r}")
    if current:
        contours.append(current)
    return contours

def get_width(block):
    m = re.search(r"^Width: (\d+)", block, re.M)
    return int(m.group(1)) if m else 0

def get_unicode(block):
    m = re.search(r"^Encoding: (-?\d+) (-?\d+) (-?\d+)", block, re.M)
    return int(m.group(2)) if m else -1

def replay_contours(contours, pen, dx=0.0, dy=0.0, scale=1.0):
    def tp(pt):
        return (pt[0] * scale + dx, pt[1] * scale + dy)
    for contour in contours:
        for seg in contour:
            if seg[0] == "move":
                pen.moveTo(tp(seg[1]))
            elif seg[0] == "line":
                pen.lineTo(tp(seg[1]))
            elif seg[0] == "curve":
                pen.curveTo(tp(seg[1]), tp(seg[2]), tp(seg[3]))
        pen.closePath()

def contours_bounds(contours):
    xs, ys = [], []
    for contour in contours:
        for seg in contour:
            pt = seg[1]
            xs.append(pt[0]); ys.append(pt[1])
            if seg[0] == "curve":
                xs.append(seg[2][0]); ys.append(seg[2][1])
                xs.append(seg[3][0]); ys.append(seg[3][1])
    return (min(xs), min(ys), max(xs), max(ys))

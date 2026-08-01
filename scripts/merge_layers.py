#!/usr/bin/env python3
"""把两张 ANSI 艺术按字符格子叠加：背景层填入前景层的透明格子。

前景层（机甲头）保持原样不重转，只有底色为 48;5;0 的格子（透明区）
才会被背景层（白色 01）填充。

前景边缘外扩 halo 圈格子保持透明（黑），给前景描一道黑边，
避免亮色背景把前景轮廓吃掉。

用法: merge_layers.py 前景.ans 背景.ans [halo] > 输出.ans
"""
import sys

BG_TRANSPARENT = "48;5;0m"      # aic 对透明/黑区输出的底色


def parse(line):
    """把一行拆成 [(转义前缀, 可见字符)]，行尾多余转义丢弃。"""
    cells, pending, i = [], "", 0
    while i < len(line):
        if line[i] == "\x1b":
            end = line.find("m", i)
            if end == -1:
                break
            pending += line[i:end + 1]
            i = end + 1
        else:
            cells.append((pending, line[i]))
            pending = ""
            i += 1
    return cells


def load(path):
    return [parse(l) for l in open(path).read().splitlines() if l.strip()]


def main():
    fg, bg = load(sys.argv[1]), load(sys.argv[2])
    halo = int(sys.argv[3]) if len(sys.argv) > 3 else 1

    opaque = {
        (y, x)
        for y, row in enumerate(fg)
        for x, (pre, _) in enumerate(row)
        if BG_TRANSPARENT not in pre
    }
    # 前景实体格向外扩 halo 圈：这些格子不填背景，保留原始黑底当描边
    protected = {
        (y + dy, x + dx)
        for (y, x) in opaque
        for dy in range(-halo, halo + 1)
        for dx in range(-halo, halo + 1)
    }

    out = []
    for y, fg_row in enumerate(fg):
        bg_row = bg[y] if y < len(bg) else []
        line = []
        for x, (pre, ch) in enumerate(fg_row):
            fill_bg = (
                BG_TRANSPARENT in pre
                and (y, x) not in protected
                and x < len(bg_row)
            )
            if fill_bg:
                pre, ch = bg_row[x]
            line.append(pre + ch)
        out.append("".join(line) + "\x1b[0m")
    print("\n".join(out))


if __name__ == "__main__":
    main()

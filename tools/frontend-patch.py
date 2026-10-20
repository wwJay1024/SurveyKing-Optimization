#!/usr/bin/env python3
"""前端定点补丁。

官方只开源了后端，前端是编译产物，界面改动只能在产物上做字符串替换。
本脚本按内容定位目标文件，不写死 chunk 名与哈希，换官方版本也能重放。

三处改动：
  1. 练习模式答题卡补算每题 finished，修复答题卡「已答/未答」计数恒为空
  2. 移动端答题卡格子补上 correct/wrong 类，并补齐对应配色
  3. 角色管理页增加「题库授权」入口按钮

用法：
  python tools/frontend-patch.py --static server/api/src/main/resources/static
  python tools/frontend-patch.py --jar /path/to/surveyking.jar
"""
import argparse
import hashlib
import os
import re
import sys
import zipfile

STATIC = "BOOT-INF/classes/static/"
HASHED = re.compile(r"^(.+)\.([0-9a-f]{8})\.(async\.js|chunk\.css)$")

# 1. 答题卡计数：懒加载分支在这里提前返回，finished 从没被算过
LAZY = ("if(this.lazy)return n=(null===(t=this.schema.children)||void 0===t?void 0:t.length)||1,"
        "i=Object.keys(this.form.values).length,void(this.progress=i/n);")

# 2. 移动端答题卡格子：只有 marked/finished/current，没有对错
ITEM = re.compile(r"\{marked:(\w+),finished:(\w+),current:(\w+)\}")
ITEM_DONE = re.compile(r"correct:!0===\w+\.isCorrect,wrong:!1===\w+\.isCorrect\}")

# 2b. 移动端答题卡配色：产物里只有 .finished 的蓝色，没有对错两色
CSS_RULE = (".adm-answer-sheet .answer-sheet-item.current{color:#fff;font-weight:600;background:#1677ff;"
            "border-color:#1677ff;box-shadow:0 0 0 3px rgba(22,119,255,.16)}")
CSS_ADD = (".adm-answer-sheet .answer-sheet-item.correct{color:#0f8a4d;background:#e9f8f0;border-color:#9cd9b8}"
           ".adm-answer-sheet .answer-sheet-item.wrong{color:#d92d20;background:#fdeceb;border-color:#f6b3ad}")

# 3. 角色管理页工具栏「新建」按钮的结尾。多个页面都有「新建」按钮，
#    所以用角色页独有的消息 id 先把文件圈定下来。
ROLE_PAGE = "pages.system.role.toolbar.new"
ROLE_ANCHOR = 'defaultMessage:"\\u65b0\\u5efa"})},"button")]}}'


def patch_store(text):
    """答题卡计数：懒加载分支里用 form.values 补齐每题 finished"""
    if LAZY not in text:
        return None
    if text.count(LAZY) != 1:
        raise SystemExit("答题卡计数锚点不唯一，放弃修改")
    # 判空助手在产物里的别名随构建变化，从同文件既有的调用里取
    found = re.search(r"\(0,(\w+)\.xb\)\(t\.value\)", text)
    if not found:
        raise SystemExit("找不到判空助手的调用写法，无法生成答题卡补丁")
    nil = found.group(1)
    new = LAZY.replace(
        "void(this.progress=i/n);",
        "(e.answerSheet||[]).forEach((function(t){t.finished=!(0,%s.xb)(e.form.values[t.id])})),"
        "void(this.progress=i/n);" % nil)
    return text.replace(LAZY, new)


def patch_mobile_item(text):
    """移动端答题卡格子：补上 correct/wrong 两个类"""
    found = ITEM.search(text)
    if not found:
        return None
    if len(ITEM.findall(text)) != 1:
        raise SystemExit("移动端答题卡格子锚点不唯一，放弃修改")
    anchor = found.start()
    # props 变量名同样随构建变化，从同一组件里对 props 的取值反推
    window = text[max(0, anchor - 2000):anchor]
    props = None
    for hit in re.findall(r"(\w+)=(\w+)\.finished", window):
        props = hit[1]
    if not props:
        raise SystemExit("找不到移动端格子的 props 变量，无法生成对错补丁")
    old = found.group(0)
    new = old[:-1] + ",correct:!0===%s.isCorrect,wrong:!1===%s.isCorrect}" % (props, props)
    return text.replace(old, new)


def patch_css(text):
    """移动端答题卡配色：补上答对绿与答错红"""
    if CSS_RULE not in text:
        return None
    if CSS_ADD in text:
        return None
    if text.count(CSS_RULE) != 1:
        raise SystemExit("答题卡配色锚点不唯一，放弃修改")
    return text.replace(CSS_RULE, CSS_RULE + CSS_ADD)


def patch_role(text):
    """角色管理页：工具栏追加「题库授权」入口按钮"""
    if ROLE_PAGE not in text:
        return None
    if ROLE_ANCHOR not in text:
        # 主包里也登记着这条消息 id，但不含按钮写法，不是目标文件
        return None
    if text.count(ROLE_ANCHOR) != 1:
        raise SystemExit("角色管理页入口锚点不唯一，放弃修改")
    anchor = text.index(ROLE_ANCHOR)
    window = text[max(0, anchor - 4000):anchor]
    aliases = re.findall(r"\(0,(\w+)\.jsx\)\((\w+)\.Z,\{icon:", window)
    if not aliases:
        raise SystemExit("找不到角色管理页按钮的渲染写法，无法生成入口补丁")
    jsx, btn = aliases[-1]
    new = ('defaultMessage:"\\u65b0\\u5efa"})},"button"),'
           '(0,' + jsx + '.jsx)(' + btn + '.Z,{onClick:function(){window.location.href="/role-repo"},'
           'children:"\\u9898\\u5e93\\u6388\\u6743"},"roleRepo")]}}')
    return text.replace(ROLE_ANCHOR, new)


# 每一项都必须命中；移动端答题卡是较新版本才有的，缺失不算失败
REQUIRED = ["答题卡计数", "角色管理页入口"]


PATCHES = [
    ("答题卡计数", ".js", patch_store, lambda text: "answerSheet||[]" in text),
    ("移动端答题卡对错", ".js", patch_mobile_item, lambda text: bool(ITEM_DONE.search(text))),
    ("移动端答题卡配色", ".css", patch_css, lambda text: CSS_ADD in text),
    ("角色管理页入口", ".js", patch_role, lambda text: '"/role-repo"' in text),
]


def apply_to_text(name, text, notes, done, hits):
    for label, suffix, func, applied in PATCHES:
        if not name.endswith(suffix):
            continue
        changed = func(text)
        if changed is not None:
            notes.append("%s → %s" % (name, label))
            hits[label] = hits.get(label, 0) + 1
            text = changed
        elif applied(text):
            done.append("%s → %s（已是最新）" % (name, label))
            hits[label] = hits.get(label, 0) + 1
    return text


def patch_directory(directory):
    notes, done, hits = [], [], {}
    for root, _, files in os.walk(directory):
        for name in files:
            if not name.endswith((".js", ".css")):
                continue
            path = os.path.join(root, name)
            with open(path, encoding="utf-8") as fp:
                text = fp.read()
            new = apply_to_text(name, text, notes, done, hits)
            if new != text:
                with open(path, "w", encoding="utf-8") as fp:
                    fp.write(new)
    return notes, done, hits


def patch_jar(jar):
    notes, done, hits = [], [], {}
    zin = zipfile.ZipFile(jar)
    items = zin.infolist()
    meta = {info.filename: info for info in items}
    payloads = {info.filename: zin.read(info.filename) for info in items}

    changed = []
    for info in items:
        name = info.filename
        if not name.startswith(STATIC) or not name.endswith((".js", ".css")):
            continue
        text = payloads[name].decode("utf-8")
        new = apply_to_text(name, text, notes, done, hits)
        if new != text:
            payloads[name] = new.encode("utf-8")
            changed.append(name)

    if not changed:
        zin.close()
        return notes, done, hits

    # 打包场景要让浏览器丢掉旧缓存：改动过的分包换新文件名，主包里的分包哈希同步更新，
    # 入口页的版本参数跟着主包内容走。旧文件名的条目保留，仍在用旧主包的浏览器不会炸。
    renames, extra = [], []
    for name in changed:
        hit = HASHED.match(name)
        if not hit:
            continue
        base, old, suffix = hit.groups()
        new_hash = hashlib.sha1(payloads[name]).hexdigest()[:8]
        if new_hash == old:
            continue
        renames.append((old, new_hash))
        extra.append(("%s.%s.%s" % (base, new_hash, suffix), name))

    if renames:
        umi = [n for n in payloads if re.match(r"^" + re.escape(STATIC) + r"umi\.[0-9a-f]{8}\.js$", n)]
        index = STATIC + "index.html"
        if not umi or index not in payloads:
            raise SystemExit("找不到主包或入口页，无法同步缓存版本")
        text = payloads[umi[0]].decode("utf-8")
        for old, new_hash in renames:
            needle = '"%s"' % old
            if text.count(needle) != 1:
                raise SystemExit("主包里的分包哈希 %s 出现 %d 次，无法安全替换" % (old, text.count(needle)))
            text = text.replace(needle, '"%s"' % new_hash)
        payloads[umi[0]] = text.encode("utf-8")

        html = payloads[index].decode("utf-8")
        ref = "/" + os.path.basename(umi[0])
        if ref not in html:
            raise SystemExit("入口页里找不到主包引用")
        version = hashlib.sha1(text.encode("utf-8")).hexdigest()[:8]
        if re.search(re.escape(ref) + r"\?b=[0-9A-Za-z]+", html):
            html = re.sub(re.escape(ref) + r"\?b=[0-9A-Za-z]+", "%s?b=%s" % (ref, version), html)
        else:
            html = html.replace(ref, "%s?b=%s" % (ref, version), 1)
        payloads[index] = html.encode("utf-8")

    tmp = jar + ".tmp"
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
        for info in items:
            zi = zipfile.ZipInfo(info.filename, info.date_time)
            zi.compress_type = info.compress_type
            zi.external_attr = info.external_attr
            zi.create_system = info.create_system
            zout.writestr(zi, payloads[info.filename])
        for renamed, source in extra:
            src = meta[source]
            zi = zipfile.ZipInfo(renamed, src.date_time)
            zi.compress_type = src.compress_type
            zi.external_attr = src.external_attr
            zi.create_system = src.create_system
            zout.writestr(zi, payloads[source])
    zin.close()
    os.replace(tmp, jar)
    return notes, done, hits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--static", help="静态资源目录，就地修改")
    ap.add_argument("--jar", help="jar 文件，就地修改")
    args = ap.parse_args()
    if bool(args.static) == bool(args.jar):
        raise SystemExit("需要指定 --static 或 --jar 其中之一")

    notes, done, hits = patch_directory(args.static) if args.static else patch_jar(args.jar)
    for note in notes:
        print("已修改 " + note)
    for note in done:
        print("无需修改 " + note)
    missing = [label for label in REQUIRED if label not in hits]
    if missing:
        raise SystemExit("以下补丁点没有命中，产物结构可能已经变化：%s" % "、".join(missing))
    if not notes and not done:
        raise SystemExit("没有命中任何补丁点，产物结构可能已经变化")


if __name__ == "__main__":
    main()

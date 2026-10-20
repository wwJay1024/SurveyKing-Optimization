#!/usr/bin/env python3
"""用官方 jar 作为基线，叠加本仓库的定制，产出可直接部署的 jar。

上游只发布了后端源码，前端是编译产物；而本仓库源码是 v1.13.0，线上跑的是更高版本，
直接 gradle 构建得不到与线上一致的系统。所以部署走「官方 jar + 增量」：

  1. 用官方 jar 里的依赖编译本仓库新增的 Java 源码
  2. 把编译结果和 role-repo.html 打成 role-repo-patch.jar，注入 BOOT-INF/lib
  3. 对 jar 内的前端产物执行 tools/frontend-patch.py

用法：
  python3 tools/build-injected-jar.py --base <官方jar> --out <输出jar>
可覆盖的环境变量/参数：
  --jdk     JDK 目录（含 bin/javac），默认取 JDK_HOME 或 PATH 里的 javac
  --lombok  lombok.jar，默认 .toolchain/lombok.jar
  --work    中间产物目录，默认 build/
"""
import argparse
import glob
import os
import shutil
import subprocess
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAGE = os.path.join(ROOT, "server", "api", "src", "main", "resources", "static", "role-repo.html")
SOURCE_GLOB = os.path.join(ROOT, "server", "*", "src", "main", "java", "**", "RoleRepo*.java")


def clone_info(info):
    zi = zipfile.ZipInfo(info.filename, info.date_time)
    zi.compress_type = info.compress_type
    zi.external_attr = info.external_attr
    zi.create_system = info.create_system
    return zi


def find_jdk(explicit):
    if explicit:
        return explicit
    env = os.environ.get("JDK_HOME")
    if env:
        return env
    javac = shutil.which("javac")
    if not javac:
        raise SystemExit("找不到 javac，请用 --jdk 或 JDK_HOME 指定 JDK 目录")
    return os.path.dirname(os.path.dirname(os.path.realpath(javac)))


def extract_libs(base, target):
    shutil.rmtree(target, ignore_errors=True)
    os.makedirs(target)
    with zipfile.ZipFile(base) as z:
        for info in z.infolist():
            if info.filename.startswith("BOOT-INF/lib/") and info.filename.endswith(".jar"):
                with open(os.path.join(target, os.path.basename(info.filename)), "wb") as fp:
                    fp.write(z.read(info.filename))


def compile_sources(jdk, lombok, libs, work):
    sources = sorted(glob.glob(SOURCE_GLOB, recursive=True))
    if not sources:
        raise SystemExit("没有找到 RoleRepo*.java，请检查源码路径")
    classes = os.path.join(work, "classes")
    shutil.rmtree(classes, ignore_errors=True)
    os.makedirs(classes)
    classpath = os.pathsep.join([os.path.join(libs, "*"), lombok])
    cmd = [os.path.join(jdk, "bin", "javac"), "-encoding", "UTF-8", "-nowarn",
           "-cp", classpath, "-d", classes] + sources
    done = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if done.returncode != 0:
        print(done.stdout)
        print(done.stderr, file=sys.stderr)
        raise SystemExit("编译失败")
    print("   编译 %d 个源文件" % len(sources))
    return classes


def make_patch_jar(classes, work):
    out = os.path.join(work, "role-repo-patch.jar")
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for root, _, files in os.walk(classes):
            for name in files:
                if name.endswith(".class"):
                    full = os.path.join(root, name)
                    z.write(full, os.path.relpath(full, classes).replace("\\", "/"))
        z.write(PAGE, "static/role-repo.html")
    print("   补丁包 %.1f KB" % (os.path.getsize(out) / 1024.0))
    return out


def inject(patch_jar, base, out):
    shutil.copy(base, out)
    with zipfile.ZipFile(out, "a") as z:
        zi = zipfile.ZipInfo("BOOT-INF/lib/role-repo-patch.jar")
        # 嵌套 jar 必须不压缩，否则 Spring Boot 启动器打不开
        zi.compress_type = zipfile.ZIP_STORED
        z.writestr(zi, open(patch_jar, "rb").read())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default=os.path.join(ROOT, ".toolchain", "surveyking-v1.13.2.jar"),
                    help="官方原版 jar（未打过任何补丁）")
    ap.add_argument("--out", default=os.path.join(ROOT, "dist", "surveyking.jar"), help="输出 jar")
    ap.add_argument("--jdk", help="JDK 目录")
    ap.add_argument("--lombok", default=os.path.join(ROOT, ".toolchain", "lombok.jar"))
    ap.add_argument("--work", default=os.path.join(ROOT, "build"))
    args = ap.parse_args()

    base, out, work = (os.path.abspath(p) for p in (args.base, args.out, args.work))
    lombok = os.path.abspath(args.lombok)
    jdk = find_jdk(args.jdk)
    for path, desc in ((base, "官方 jar"), (lombok, "lombok.jar"),
                       (os.path.join(jdk, "bin", "javac"), "javac"), (PAGE, "role-repo.html")):
        if not os.path.exists(path):
            raise SystemExit("找不到%s：%s" % (desc, path))

    os.makedirs(work, exist_ok=True)
    os.makedirs(os.path.dirname(out), exist_ok=True)

    print("== 1/3 编译并注入角色题库授权 ==")
    libs = os.path.join(work, "libs")
    extract_libs(base, libs)
    classes = compile_sources(jdk, lombok, libs, work)
    patch_jar = make_patch_jar(classes, work)
    inject(patch_jar, base, out)

    print("== 2/3 前端产物补丁 ==")
    subprocess.run([sys.executable, os.path.join(ROOT, "tools", "frontend-patch.py"), "--jar", out],
                   check=True)

    print("== 3/3 结果 ==")
    print("   %s（%.1f MB）" % (out, os.path.getsize(out) / 1024.0 / 1024.0))


if __name__ == "__main__":
    main()

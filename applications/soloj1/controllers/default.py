# -*- coding: utf-8 -*-
import json
import os


def _json(data):
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    return json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True)


def _link_paths():
    root = os.environ.get(
        "SOLOJ1_LINK_TEST_ROOT",
        os.path.join(request.folder, "static", "link_test"),
    )
    external_target = os.environ.get(
        "SOLOJ1_EXTERNAL_LINK_TARGET",
        "/app/runtime/soloj1-external-target",
    )
    return {
        "root": root,
        "internal_target": os.path.join(root, "internal_target"),
        "internal_link": os.path.join(root, "internal_link"),
        "external_target": external_target,
        "external_link": os.path.join(root, "external_link"),
    }


def _path_info(path):
    info = {
        "path": path,
        "exists": os.path.exists(path),
        "lexists": os.path.lexists(path),
        "is_link": os.path.islink(path),
    }
    if info["lexists"]:
        info["realpath"] = os.path.realpath(path)
    if info["exists"]:
        info["is_dir"] = os.path.isdir(path)
        info["is_file"] = os.path.isfile(path)
        info["readable"] = os.access(path, os.R_OK)
        info["writable"] = os.access(path, os.W_OK)
    return info


def index():
    """首页"""
    return dict(message="欢迎使用SoloJ1应用程序！")


def about():
    """关于页面"""
    return dict(title="关于我们")


def link_prepare():
    """Create runtime symlinks for Docker/Coolify storage tests."""
    paths = _link_paths()
    results = {}
    os.makedirs(paths["root"], exist_ok=True)
    os.makedirs(paths["internal_target"], exist_ok=True)

    with open(os.path.join(paths["internal_target"], "marker.txt"), "w") as fp:
        fp.write("internal symlink target ok\n")

    if os.path.lexists(paths["internal_link"]):
        os.unlink(paths["internal_link"])
    os.symlink(paths["internal_target"], paths["internal_link"])
    results["internal_link"] = "prepared"

    try:
        os.makedirs(paths["external_target"], exist_ok=True)
        with open(os.path.join(paths["external_target"], "marker.txt"), "w") as fp:
            fp.write("external symlink target ok\n")
        if os.path.lexists(paths["external_link"]):
            os.unlink(paths["external_link"])
        os.symlink(paths["external_target"], paths["external_link"])
        results["external_link"] = "prepared"
    except OSError as exc:
        results["external_link"] = "skipped"
        results["external_error"] = str(exc)

    return _json({"status": "prepared", "paths": paths, "results": results})


def link_status():
    """Inspect runtime symlinks and their targets."""
    paths = _link_paths()
    return _json(
        {
            "status": "ok",
            "paths": paths,
            "items": {name: _path_info(path) for name, path in paths.items()},
        }
    )

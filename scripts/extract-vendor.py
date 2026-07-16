from __future__ import annotations

import pathlib
import sys
import tarfile


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit("用法：extract-vendor.py <归档> <目标目录>")

    archive = pathlib.Path(sys.argv[1]).resolve()
    target = pathlib.Path(sys.argv[2]).resolve()
    target.mkdir(parents=True, exist_ok=False)

    with tarfile.open(archive, "r:gz") as bundle:
        members = bundle.getmembers()
        roots = {pathlib.PurePosixPath(item.name).parts[0] for item in members if item.name}
        if len(roots) != 1:
            raise RuntimeError("依赖归档必须只有一个根目录")
        root = next(iter(roots))

        for item in members:
            parts = pathlib.PurePosixPath(item.name).parts
            if not parts or parts[0] != root or len(parts) == 1:
                continue
            relative = pathlib.Path(*parts[1:])
            destination = (target / relative).resolve()
            if not destination.is_relative_to(target):
                raise RuntimeError(f"依赖归档试图越过目标目录：{item.name}")
            item.name = relative.as_posix()
            bundle.extract(item, target, filter="data")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

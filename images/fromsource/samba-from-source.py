#!/usr/bin/python3

import argparse
import logging
import os
import pathlib
import re
import shutil
import subprocess
import sys

log = logging.getLogger()


def _is_centos():
    try:
        with open("/etc/os-release") as fh:
            for line in fh:
                if line.startswith("ID=") and "centos" in line:
                    return True
    except (OSError, IOError):
        pass
    return False


def _dnf_prefix(cli):
    cmd = ["dnf"]
    if cli.keep_dnf:
        cmd.append("--setopt=keepcache=True")
    return cmd


def _has_source(src_path):
    return src_path.is_dir() and (src_path / ".git").is_dir()


def _write_dir(cli):
    wdir = pathlib.Path("/tmp")
    if cli.workdir:
        wdir = pathlib.Path(cli.workdir)
    if cli.job:
        wdir = wdir / cli.job
    return wdir


def _fmt_rpm_version(vinfo):
    return f"{vinfo['git_date']}.{vinfo['git_hash']}"


def run(cmd_args, check=True, **kwargs):
    """Wrapper for subprocess.run with logging and result check enabled."""
    log.info("Running Command: %s", cmd_args)
    return subprocess.run(cmd_args, check=check, **kwargs)


def get_samba_source(cli):
    """Validate or fetch the git tree for samba."""
    log.info("Setting up build sources")
    src_path = pathlib.Path(cli.samba_source)
    if _has_source(src_path):
        log.info(f"found samba source dir: {src_path}")
        if cli.force_ref:
            run(["git", "checkout", cli.git_ref], cwd=src_path)
        return
    log.info(f"getting samba sources from {cli.git_repo} for {cli.git_ref}")
    run(["git", "clone", cli.git_repo, str(src_path)])
    run(["git", "checkout", cli.git_ref], cwd=src_path)


def get_samba_version_info(cli):
    """Return a dict containing versioning info from git."""
    log.info("Getting build version info")
    results = {}
    src_path = pathlib.Path(cli.samba_source)
    res = run(
        ["git", "log", "-1", "--format=format:%cd", "--date=iso"],
        capture_output=True,
        cwd=src_path,
    )
    date = res.stdout.decode("utf8")
    results["date"] = date.strip()

    ndate = re.sub(" [^ ]*$", "", date.strip().replace("-", ""))
    ndate = re.sub("\\:", "", ndate).replace(" ", ".")
    results["git_date"] = ndate

    res = run(
        ["git", "log", "-1", "--format=%h"], capture_output=True, cwd=src_path
    )
    ghash = res.stdout.decode("utf8").strip()
    results["git_hash"] = ghash

    return results


def genrate_samba_tarball(cli, vinfo):
    log.info("Building source tarball")
    src_path = pathlib.Path(cli.samba_source)
    rpm_version = _fmt_rpm_version(vinfo)
    dest = _write_dir(cli) / f"samba-{rpm_version}.tar.gz"
    dest.parent.mkdir(parents=True, exist_ok=True)
    run(
        [
            "git",
            "archive",
            f"--prefix=samba-{rpm_version}/",
            f"--output={dest}",
            "HEAD",
        ],
        cwd=src_path,
    )


def generate_srpm(cli, vinfo):
    log.info("Building source rpm")
    rpm_version = _fmt_rpm_version(vinfo)
    wdir = _write_dir(cli)
    shutil.copytree(cli.package_source, wdir, dirs_exist_ok=True)

    with open(wdir / "samba.spec", "w") as outfh:
        with open(wdir / "samba-master.spec", "r") as infh:
            for line in infh:
                if "samba_version 4.999" in line:
                    outfh.write(f"%global samba_version {rpm_version}\n")
                else:
                    outfh.write(line)

    run(
        [
            "rpmbuild",
            "--define",
            f"_topdir {wdir}",
            "--define",
            f"_sourcedir {wdir}",
            "--define",
            f"_srcrpmdir {wdir}",
            "--define",
            f"custom_samba_version {rpm_version}",
            "-bs",
            str(wdir / "samba.spec"),
        ]
    )


def find_srpm(cli, vinfo):
    """Return the path to a matching srpm to build."""
    log.info("Selecting source rpm")
    rpm_version = _fmt_rpm_version(vinfo)
    wdir = _write_dir(cli)
    srpm = None
    for (path, dirs, files) in os.walk(wdir):
        for file in files:
            if file.startswith(f"samba-{rpm_version}") and file.endswith(
                ".src.rpm"
            ):
                srpm = pathlib.Path(path) / file
    if srpm is None:
        raise ValueError("srpm not found")
    return srpm


def bootstrap_distro(cli):
    """Install the most basic dependencies."""
    log.info("Installing basic dependencies")
    pkgs = [
        "git",
        "gcc",
        "/usr/bin/rpmbuild",
        "dnf-command(builddep)",
    ]
    run(_dnf_prefix(cli) + ["install", "-y"] + pkgs)


def install_deps(cli, deps_src):
    """Install dependencies derived from the SRPM."""
    log.info("Installing build dependencies")
    is_centos = _is_centos()
    pre_pkgs = ["dnf-command(builddep)"]
    if is_centos:
        pre_pkgs.append("epel-release")
        pre_pkgs.append("centos-release-gluster")
        pre_pkgs.append("centos-release-ceph")
    run(_dnf_prefix(cli) + ["install", "-y"] + pre_pkgs)
    dnf_cmd = _dnf_prefix(cli) + ["builddep", "-y"]
    if cli.with_ceph:
        dnf_cmd.append("--define=with_vfs_cephfs 1")
        dnf_cmd.append("--define=with_vfs_cephfs 1")
    if is_centos:
        dnf_cmd.append("--enablerepo=crb")
        dnf_cmd.append("--enablerepo=resilientstorage")
    dnf_cmd.append(deps_src)
    run(dnf_cmd)

    if not cli.keep_dnf:
        # the dnf caches are "part of" the container. delete them so
        # to keep the image's layer cleaner
        run(["dnf", "clean", "all"])


def build_rpm(cli, vinfo, srpm):
    """Build RPMs from a source RPM."""
    log.info("Building RPMs")
    wdir = _write_dir(cli)
    cmd = [
        "rpmbuild",
        "--define",
        f"_topdir {wdir}",
        "--rebuild",
    ]
    if cli.with_ceph:
        cmd.append("--with=vfs_cephfs")
        cmd.append("--with=ceph_mutex")
    cmd.append(srpm)

    run(cmd)


def set_arguments(parser):
    """Set up the arguments that the script will use."""
    # This function is reused within the "outer" build script
    parser.add_argument(
        "--samba-source",
        default="/srv/build/samba",
        help="Path to the source checkout of samba",
    )
    parser.add_argument(
        "--package-source",
        default="/usr/local/lib/sources",
        help="Path to packaging specific sources",
    )
    parser.add_argument(
        "--workdir",
        "-w",
        default="/srv/build/work",
        help="Path to working dir",
    )
    parser.add_argument(
        "--job",
        "-j",
        help="Name of path in working dir to write results",
    )
    parser.add_argument(
        "--install-deps-from",
        help="Installs dependencies based on a path to a SPEC file or SRPM",
    )
    parser.add_argument(
        "--git-ref", default="master", help="Samba git ref to check out"
    )
    parser.add_argument(
        "--git-repo",
        default="https://git.samba.org/samba.git",
        help="Samba git repo",
    )
    parser.add_argument(
        "--force-ref",
        action="store_true",
        help="Even if a repo already exists try to checkout the supplied git ref",
    )
    parser.add_argument(
        "--bootstrap",
        action="store_true",
        help="Bootstrap environment & install critical dependency packages",
    )
    parser.add_argument(
        "--keep-dnf",
        action="store_true",
        help="Enable pesistent dnf state. Do not clean dnf.",
    )
    parser.add_argument(
        "--skip-build",
        action="store_true",
        help="Do not build packages",
    )
    parser.add_argument(
        "--with-ceph",
        action="store_true",
        help="Enable building Ceph components",
    )


def parse_cli():
    parser = argparse.ArgumentParser(
        description="""
Automate building samba packages within an OCI container environment.
You can build samba packages from a git url and ref. You can build from a local
checkout by passing the directory in as a volume.  This script only builds from
changes that are commited.

Packages will be written to the workdir. If the workdir is not passed in
as a volume to the container the build will not be preserved when the
container exits.
"""
    )
    set_arguments(parser)
    cli = parser.parse_args()
    return cli


def main():
    cli = parse_cli()
    logging.basicConfig(
        level=logging.INFO,
        format="samba-from-source.py: %(asctime)s: %(levelname)s: %(message)s",
    )

    if cli.bootstrap:
        bootstrap_distro(cli)

    if cli.install_deps_from:
        install_deps(cli, cli.install_deps_from)

    if cli.skip_build:
        log.info("Skipping build phase")
        sys.exit(0)

    log.info("Building packages...")
    get_samba_source(cli)
    vinfo = get_samba_version_info(cli)
    log.info("determined version information: %s", vinfo)
    genrate_samba_tarball(cli, vinfo)
    generate_srpm(cli, vinfo)
    srpm = find_srpm(cli, vinfo)
    build_rpm(cli, vinfo, srpm)
    sys.exit(0)


if __name__ == "__main__":
    main()

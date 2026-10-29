"""Import additional Fantasia and CHF RR records from supplied PhysioNet ZIPs."""

from __future__ import annotations

import argparse
import csv
import tempfile
import zipfile
from pathlib import Path

import numpy as np
import wfdb

FANTASIA_RECORDS = [f"f1y{i:02d}" for i in range(6, 11)] + [f"f1o{i:02d}" for i in range(6, 11)]
CHF_RECORDS = [f"chf{i:02d}" for i in range(6, 11)]


def extract_record(zippath: Path, member_root: str, record: str, temp_root: Path) -> Path:
    record_dir = temp_root / member_root
    record_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zippath) as archive:
        for suffix in (".ecg", ".hea"):
            member = f"{member_root}/{record}{suffix}"
            (record_dir / f"{record}{suffix}").write_bytes(archive.read(member))
    return record_dir / record


def annotation_to_rr(record_path: Path, fs: float = 250.0) -> np.ndarray:
    annotation = wfdb.rdann(str(record_path), "ecg")
    samples = np.asarray(annotation.sample, dtype=float)
    rr_ms = np.diff(samples) / fs * 1000.0
    rr_ms = rr_ms[np.isfinite(rr_ms) & (rr_ms > 0)]
    if rr_ms.size < 1000:
        raise RuntimeError(f"{record_path.name}: only {rr_ms.size} RR intervals found")
    return rr_ms


def write_rr(path: Path, rr_ms: np.ndarray, fantasia: bool) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    np.savetxt(path, rr_ms / 1000.0 if fantasia else rr_ms, fmt="%.6f")
    return int(rr_ms.size)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--project", type=Path, required=True)
    args = parser.parse_args()
    fantasia_zip = args.source / "fantasia-database-1.0.0.zip"
    chf_zip = args.source / "bidmc-congestive-heart-failure-database-1.0.0.zip"
    if not fantasia_zip.is_file() or not chf_zip.is_file():
        raise FileNotFoundError("Both expected ZIP files must be present in --source")

    manifest = []
    with tempfile.TemporaryDirectory(dir=args.project / "matlab") as temp_name:
        temp_root = Path(temp_name)
        for record in FANTASIA_RECORDS:
            source = extract_record(fantasia_zip, "fantasia-database-1.0.0", record, temp_root)
            rr = annotation_to_rr(source)
            if record.startswith("f1y"):
                subject, group = "Y" + str(int(record[3:])), "Young"
            else:
                subject, group = "O" + str(int(record[3:])), "Elderly"
            count = write_rr(args.project / "data" / "fantasia" / f"{subject}.txt", rr, True)
            manifest.append([subject, group, record, count, "Fantasia", "seconds"])
        for record in CHF_RECORDS:
            source = extract_record(chf_zip, "files", record, temp_root)
            rr = annotation_to_rr(source)
            count = write_rr(args.project / "data" / "chf" / f"{record}_rr.txt", rr, False)
            manifest.append([record, "CHF", record, count, "BIDMC CHF", "milliseconds"])

    manifest_path = args.project / "data" / "expanded_dataset_manifest.csv"
    with manifest_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["Subject", "Group", "SourceRecord", "RRIntervals", "Database", "StoredUnits"])
        writer.writerows(manifest)
    print(f"Imported {len(manifest)} records to {args.project / 'data'}")
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    main()

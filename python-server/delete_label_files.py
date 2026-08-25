import csv
import glob
import os
import sys

# 지우고 싶은 라벨을 여기에 나열
LABELS_TO_REMOVE = ["ㅅ", "ㅠ"]


def file_labels(path: str):
    with open(path, "r", encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        rows = list(reader)

    if not rows or len(rows) < 2:
        return set()

    header = rows[0]
    if "label" not in header:
        return set()

    label_idx = header.index("label")
    return set(row[label_idx] for row in rows[1:] if len(row) > label_idx)


def find_and_delete(target_dir: str, dry_run: bool = True):
    csv_files = sorted(glob.glob(os.path.join(target_dir, "*.csv")))
    if not csv_files:
        print(f"{target_dir} 에 csv 파일이 없습니다.")
        return

    to_delete = []
    for path in csv_files:
        try:
            labels_in_file = file_labels(path)
        except Exception as e:
            print(f"읽기 실패, 건너뜀: {path} ({e})")
            continue

        if labels_in_file & set(LABELS_TO_REMOVE):
            to_delete.append((path, labels_in_file))

    if not to_delete:
        print(f"{target_dir}: ㅅ·ㅠ 관련 파일 없음")
        return

    print(f"{target_dir}: 삭제 대상 {len(to_delete)}개")
    for path, labels in to_delete:
        print(f"  - {os.path.basename(path)}  (labels={labels})")

    if dry_run:
        print("  ※ dry-run 모드라 실제로는 안 지웠습니다. 실제 삭제하려면 --apply 옵션을 붙이세요.")
    else:
        for path, _ in to_delete:
            os.remove(path)
        print(f"  {len(to_delete)}개 파일 삭제 완료.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("사용법: python delete_label_files.py <csv들이 있는 폴더> [--apply]")
        print("예시:   python delete_label_files.py data\\temp")
        print("        python delete_label_files.py data\\temp --apply")
        sys.exit(1)

    target_dir = sys.argv[1]
    apply = "--apply" in sys.argv[2:]
    find_and_delete(target_dir, dry_run=not apply)

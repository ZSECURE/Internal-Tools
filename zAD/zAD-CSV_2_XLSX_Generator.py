#!/usr/bin/env python3
"""
Combine all CSVs from a folder into a single Excel workbook.

- Each CSV becomes its own sheet (sheet name based on file name).
- The first sheet ("Summary") contains:
    * UserStatisticsSummary.csv (user stats table)
    * PrivilegedGroupStatisticsSummary.csv (privileged group stats table)

Requirements:
    pip install pandas openpyxl

Usage:
    python combine_csv_to_xlsx.py -i C:\AD_Report -o C:\AD_Report\AD_Report.xlsx
"""

import argparse
from pathlib import Path
import re

import pandas as pd


def sanitize_sheet_name(name: str, existing: set) -> str:
    """
    Make a name safe for an Excel sheet:
    - Max length 31
    - Remove forbidden characters: : \ / ? * [ ]
    - Ensure uniqueness by appending a counter if needed
    """
    # Remove extension if present
    name = Path(name).stem

    # Remove invalid characters
    name = re.sub(r'[:\\/?*\[\]]', "_", name)

    # Trim to 31 chars
    name = name[:31] or "Sheet"

    base = name
    counter = 1
    while name in existing:
        suffix = f"_{counter}"
        # Ensure we still respect the 31-character limit with the suffix
        name = (base[: 31 - len(suffix)]) + suffix
        counter += 1

    existing.add(name)
    return name


def build_excel(input_dir: Path, output_file: Path) -> None:
    csv_files = sorted(input_dir.glob("*.csv"))
    if not csv_files:
        raise FileNotFoundError(f"No CSV files found in {input_dir}")

    # Identify summary CSVs if they exist
    user_summary_path = input_dir / "UserStatisticsSummary.csv"
    group_summary_path = input_dir / "PrivilegedGroupStatisticsSummary.csv"

    sheet_names_used = set()

    with pd.ExcelWriter(output_file, engine="openpyxl") as writer:
        # ---------------------------------------------
        # 1. Create the Summary sheet as the first page
        # ---------------------------------------------
        summary_sheet_name = sanitize_sheet_name("Summary", sheet_names_used)

        # We'll build up the summary sheet by writing tables
        start_row = 0
        if user_summary_path.exists():
            df_user = pd.read_csv(user_summary_path)
            df_user.to_excel(
                writer,
                sheet_name=summary_sheet_name,
                startrow=start_row,
                index=False,
            )
            start_row += len(df_user) + 2  # blank line after table

        if group_summary_path.exists():
            df_group = pd.read_csv(group_summary_path)
            df_group.to_excel(
                writer,
                sheet_name=summary_sheet_name,
                startrow=start_row,
                index=False,
            )
            start_row += len(df_group) + 2

        # If neither summary exists, still create an empty sheet with a note
        if not user_summary_path.exists() and not group_summary_path.exists():
            df_empty = pd.DataFrame(
                {"Info": ["No summary CSVs found in folder."]}
            )
            df_empty.to_excel(
                writer,
                sheet_name=summary_sheet_name,
                index=False,
            )

        # ------------------------------------------------
        # 2. Create one sheet per CSV, labelled by filename
        # ------------------------------------------------
        for csv_path in csv_files:
            # Skip summary CSVs here; they are already on the Summary sheet
            if csv_path.name in {
                "UserStatisticsSummary.csv",
                "PrivilegedGroupStatisticsSummary.csv",
            }:
                continue

            df = pd.read_csv(csv_path)

            sheet_name = sanitize_sheet_name(csv_path.stem, sheet_names_used)

            # Write CSV contents to its own sheet, filename is the sheet label
            df.to_excel(writer, sheet_name=sheet_name, index=False)

    print(f"Workbook created: {output_file}")


def main():
    parser = argparse.ArgumentParser(
        description="Combine AD report CSVs into a single Excel workbook."
    )
    parser.add_argument(
        "-i",
        "--input-dir",
        type=str,
        default="C:\\AD_Report",
        help="Directory containing the CSV files (default: C:\\AD_Report)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        default="C:\\AD_Report\\AD_Report.xlsx",
        help="Path to the output .xlsx file (default: C:\\AD_Report\\AD_Report.xlsx)",
    )

    args = parser.parse_args()

    input_dir = Path(args.input_dir)
    output_file = Path(args.output)

    if not input_dir.exists():
        raise FileNotFoundError(f"Input directory does not exist: {input_dir}")

    build_excel(input_dir, output_file)


if __name__ == "__main__":
    main()

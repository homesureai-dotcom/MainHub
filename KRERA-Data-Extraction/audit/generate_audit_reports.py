"""Driver to generate all JSON audit reports required for Phase 3C Data Integrity Audit."""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from audit.common import ROOT, jdump
from audit.doc_reconciliation import main as doc_main
from audit.pii_audit import main as pii_main
from audit.comparison_audit import main as comp_main
from audit.identity_audit import main as ident_main
from audit.integrity_audit import main as integ_main
from audit.integrity_supplement import main as suppl_main
from audit.human_qa_audit import run_human_qa_audit


def main():
    reports_dir = ROOT / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)

    print("1/6 Generating reports/phase3c_document_reconciliation.json...")
    doc_res = doc_main()
    jdump(reports_dir / "phase3c_document_reconciliation.json", doc_res)
    print(" -> Done.")

    print("2/6 Generating reports/phase3c_human_qa_final.json...")
    run_human_qa_audit()
    print(" -> Done.")

    print("3/6 Generating reports/phase3c_pii_adversarial_audit.json...")
    pii_res = pii_main()
    jdump(reports_dir / "phase3c_pii_adversarial_audit.json", pii_res)
    print(" -> Done.")

    print("4/6 Generating reports/phase3c_comparison_coverage_audit.json...")
    comp_res = comp_main()
    jdump(reports_dir / "phase3c_comparison_coverage_audit.json", comp_res)
    print(" -> Done.")

    print("5/6 Generating reports/phase3c_identity_checkpoint_audit.json...")
    ident_res = ident_main()
    jdump(reports_dir / "phase3c_identity_checkpoint_audit.json", ident_res)
    print(" -> Done.")

    print("6/6 Generating reports/phase3c_raw_normalized_integrity_audit.json...")
    integ_res = integ_main()
    suppl_res = suppl_main()
    integ_res["supplementary_parity_and_anomaly_findings"] = suppl_res
    jdump(reports_dir / "phase3c_raw_normalized_integrity_audit.json", integ_res)
    print(" -> Done.")

    print("All 6 JSON audit reports successfully generated!")


if __name__ == "__main__":
    main()

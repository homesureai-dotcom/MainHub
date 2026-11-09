"""Audit section 3: independent adversarial PII audit (read-only on Phase 3C data)."""
from __future__ import annotations

import json
import re
import tempfile
from collections import Counter, defaultdict
from pathlib import Path

from audit.common import *  # noqa
from scripts.discovery_engine import (
    AADHAAR_CONTINUOUS_VALUE_REGEX, AADHAAR_GROUPED_VALUE_REGEX, EMAIL_VALUE_REGEX, GSTIN_VALUE_REGEX,
    INDIAN_MOBILE_VALUE_REGEX, PAN_VALUE_REGEX, KRERADiscoveryEngine, classify_pii_exclusion,
)
from scripts.detail_dom_parser import parse_project_detail_modal_html
from scripts.phase3c_batch_extractor import scan_phase3c_outputs_for_pii

TOKEN_FULL = re.compile(r"^[A-Za-z0-9+/=%_-]+$")
URL_TOKEN = re.compile(r"DOC_ID=[A-Za-z0-9%+/=_-]+")
KNOWN_ID_PATTERNS = (
    re.compile(r"PRM/KA/RERA/[A-Za-z0-9/_-]+"), re.compile(r"PR/KN/[A-Za-z0-9/_-]+"),
    re.compile(r"KRERA_[A-Za-z0-9_]+"),
)
CONTACT_LABEL = re.compile(r"mobile|phone|contact|tel\b|telephone|cell|fax", re.I)


def mask(s: str) -> str:
    s = str(s)
    return f"{s[:2]}***{s[-1:]}(len={len(s)})" if len(s) > 4 else "***"


# --------------------------------------------------------------------------------------
# B. classify_pii_exclusion adversarial matrix
# --------------------------------------------------------------------------------------
def classifier_matrix():
    ind = ("Authorized Signatory Detail", "Promoter Details")   # individual section
    corp = ("Promoter Details", "Promoter Details")             # corporate section
    proj = ("Project Details", "Project Details")
    docs = ("Uploaded Documents", "Uploaded Documents")
    C = []

    def add(cid, vector, label, value, sec, expect_excluded, note="", is_doc=False, filename=None):
        C.append(dict(id=cid, vector=vector, label=label, value=value, section=sec[0], tab=sec[1],
                      expect_excluded=expect_excluded, note=note, is_doc=is_doc, filename=filename))

    add("pan-ordinary", "PAN in ordinary field", "Tax Note", "ref ZZZZZ9999Z attached", corp, True)
    add("pan-lower", "PAN lower-case", "Remarks", "pan qwert4321p here", corp, True)
    add("pan-underscore", "PAN underscore boundary", "Remarks", "x_QWERT4321P_y", corp, True)
    add("pan-paren-punct", "PAN punctuation", "Remarks", "(QWERT4321P),", corp, True)
    add("pan-in-gstin-label-bare", "PAN inside GSTIN-labelled field", "GSTIN Number", "QWERT4321P", corp, True)
    add("pan-in-gstin-label-prefixed", "PAN inside GSTIN-labelled field", "GSTIN", "GST-QWERT4321P", corp, True)
    add("gstin-valid", "Valid corporate GSTIN retained", "GSTIN Number", "29AAACS8899K1Z5", corp, False)
    add("gstin-valid-lower", "Valid corporate GSTIN lower-case", "GSTIN", "29aaacs8899k1z5", corp, False)
    add("gstin-plus-pan", "GSTIN with a separate PAN appended", "GSTIN", "29AAACS8899K1Z5 / QWERT4321P", corp, True)
    add("aadhaar-cont", "Aadhaar continuous", "Remarks", "234567890123", corp, True)
    add("aadhaar-grp-space", "Aadhaar grouped (space)", "Remarks", "2345 6789 0123", corp, True)
    add("aadhaar-grp-hyphen", "Aadhaar grouped (hyphen)", "Remarks", "2345-6789-0123", corp, True)
    add("aadhaar-grp-dot", "Aadhaar grouped (dot)", "Remarks", "2345.6789.0123", corp, True)
    add("aadhaar-grp-underscore", "Aadhaar grouped (underscore)", "Remarks", "2345_6789_0123", corp, True)
    add("aadhaar-label", "Aadhaar by label", "Aadhaar No", "anything", corp, True)
    add("aadhaar-cont-metric-label", "12-digit cost retained", "Estimated Cost of Construction (INR)", "345678901234", proj, False)
    add("aadhaar-cont-substring-exemption", "Aadhaar-like value under label containing 'din'/'area' substring",
        "Building Reference", "234567890123", corp, True,
        note="Label exemption uses substring match ('din' in 'Building'); documents a potential bypass vector")
    for i, v in enumerate(["+91-98450-11223", "098450 11223", "(+91) 99001-44556", "9845011223", "98450.11223",
                           "0091.98801.22334", "+91 98450 11223", "91 98450 11223", "984-501-1223", "9845-011-223"]):
        add(f"phone-individual-{i}", "Indian phone (individual section)", "Contact", v, ind, True)
    add("phone-corporate-landline", "Corporate landline retained", "Office Phone", "080-41234567", corp, False)
    add("phone-corporate-mobile", "Corporate mobile in corporate section", "Promoter Mobile", "9845011223", corp, False,
        note="Policy-dependent: corporate contacts retained by design; cannot distinguish personal numbers entered in corporate fields")
    add("email-personal-individual", "Personal email (individual section)", "Email", "vikram.personal@gmail.com", ind, True)
    add("email-corporate", "Corporate email retained", "Corporate Email", "compliance@skylineinfra.co.in", corp, False)
    add("email-personal-in-corporate-field", "Personal-looking email in corporate field", "Email", "someone@gmail.com", corp, False,
        note="Policy limit: free-mail address in a corporate-section field is retained (cannot be distinguished)")
    add("addr-individual-present", "Residential address", "Present Address", "Flat 402, 5th Cross, Indiranagar, Bengaluru 560038", ind, True)
    add("addr-individual-headerless", "Headerless residential address", "Column_3", "#18, 2nd Main, Jayanagar, Bengaluru 560041", ind, True)
    add("addr-official-retained", "Official address retained", "Official Address", "Level 9, Trade Tower, Palace Road, Bengaluru 560001", corp, False)
    add("addr-project-site-retained", "Project/site address retained", "Project Site Address", "Sy No 88/2, Whitefield Main Road, Bengaluru 560066", proj, False)
    add("photo-individual", "Personal photograph", "Photograph", "x", ind, True, is_doc=True, filename="Director_Vikram_Photo_Scan.jpg")
    add("photo-project", "Project photograph retained", "Project Photo", "x", docs, False, is_doc=True, filename="Site_Tower_A_East_Elevation_Photo.jpg")
    add("photo-borewell-enquired", "Site photo in Enquired Documents (label 'Borewell Photo')", "Borewell Photo", "x",
        ("Enquired Documents", "Enquired Documents"), False, is_doc=True, filename="borewell.jpg",
        note="Site-evidence photo; policy says preserve site photos")
    add("photo-site-label-enquired", "Site photo (label 'Photo of site')", "PHOTO of site", "x",
        ("Enquired Documents", "Enquired Documents"), False, is_doc=True, filename="site.jpg")
    for i, fn in enumerate(["PAN_card_scan.pdf", "Doc_890123456789_Aadhaar.pdf", "Consent_kiran.owner@gmail.com_letter.pdf",
                            "Verification_+91-98455-77889_record.pdf", "Scan_Driving_Licence_Copy.pdf", "Voter_ID_Front_Back.pdf",
                            "Form3CB_2025_STUVW3456X_Signed.pdf", "passport-copy.pdf", "AADHAAR.pdf"]):
        add(f"fn-sensitive-{i}", "Sensitive value/ID doc in filename", "Document", "x", docs, True, is_doc=True, filename=fn)
    for i, fn in enumerate(["Certificate_of_Incorporation.pdf", "BBMP_Sanctioned_Layout_Plan_2026.pdf", "NOC_Fire_2023.pdf",
                            "Proforma_Agreement_for_Sale.pdf", "Registration_Certificate.pdf", "Order_20230115_123456.pdf"]):
        add(f"fn-legit-{i}", "Legitimate development document filename retained", "Document", "x", docs, False, is_doc=True, filename=fn)
    add("label-registration-certificate", "Label 'Registration Certificate' document retained", "Registration Certificate", "x", corp, False,
        is_doc=True, filename="RERA_Reg_Cert.pdf")
    add("label-designation-text", "Designation text retained", "Designation", "Managing Director", ind, False)
    add("label-longitude", "Longitude retained", "Longitude", "77.594566", proj, False)
    add("label-longitude-12digit", "12-digit lon/lat style string", "Longitude", "775945661234", proj, False,
        note="Aadhaar continuous regex has no coordinate awareness; 12-digit coordinate strings would be excluded")
    return C


def run_classifier_matrix():
    out = []
    for c in classifier_matrix():
        r = classify_pii_exclusion(c["label"], c["value"], c["section"], c["tab"], is_document=c["is_doc"], filename=c["filename"])
        excluded = r is not None
        out.append({**c, "actually_excluded": excluded, "category": r[0] if r else None,
                    "reason": r[1] if r else None, "passed": excluded == c["expect_excluded"]})
    return out


# --------------------------------------------------------------------------------------
# C. scan_phase3c_outputs_for_pii adversarial tests (the production scanner)
# --------------------------------------------------------------------------------------
def run_production_scanner_tests():
    cases = [
        ("S01 PAN in ordinary field", '{"raw_value": "see ABCDE1234F for tax"}', True),
        ("S02 Base64 PAN-like substring inside DOC_ID URL (benign)", '{"source_url": "/download_jc?DOC_ID=AjpCK%2FlMr5s%2BMwNUP9599A%3D%3D"}', False),
        ("S03 PAN after space following a DOC_ID URL", '{"note": "/download_jc?DOC_ID=abc123 ABCDE1234F"}', True),
        ("S04 PAN glued after DOC_ID token with comma", '{"note": "/download_jc?DOC_ID=abc123,ABCDE1234F"}', True),
        ("S05 PAN glued after DOC_ID token with semicolon", '{"note": "/download_jc?DOC_ID=abc123;ABCDE1234F"}', True),
        ("S06 PAN in displayed_filename of a document with DOC_ID URL", '{"displayed_filename": "PAN_ABCDE1234F.pdf", "source_url": "/download_jc?DOC_ID=Zm9vYmFy"}', True),
        ("S07 PAN inside document_identifier value", '{"document_identifier": "ABCDE1234F"}', True),
        ("S08 valid corporate GSTIN", '{"raw_value": "29AAACS8899K1Z5"}', False),
        ("S09 grouped Aadhaar (space)", '{"raw_value": "2345 6789 0123"}', True),
        ("S10 continuous Aadhaar", '{"raw_value": "234567890123"}', True),
        ("S11 personal email", '{"raw_value": "someone.private@gmail.com"}', True),
        ("S12 Indian mobile +91", '{"raw_value": "+91-98450-11223"}', True),
        ("S13 SYNTHETIC_PAN placeholder token", '{"raw_value": "SYNTHETIC_PAN_REDACTED"}', True),
        ("S14 Base64 identifier benign in document_identifier", '{"document_identifier": "AjpCK/lMr5s+MwNUP9599A=="}', False),
    ]
    results = []
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        for i, (name, content, expect_leak) in enumerate(cases):
            (td / f"{i}_raw.json").write_text(content, encoding="utf-8")
            (td / f"{i}_norm.json").write_text("{}", encoding="utf-8")
            res = scan_phase3c_outputs_for_pii([{"batch_index": i, "raw_output_file": f"{i}_raw.json",
                                                "normalized_output_file": f"{i}_norm.json"}], td)
            detected = res["leaks_detected_count"] > 0
            results.append({"case": name, "payload_masked": re.sub(r"[A-Z]{5}\d{4}[A-Z]", "<PAN>", content),
                            "expect_detected": expect_leak, "production_scanner_detected": detected,
                            "leak_types": [l["leak_type"] for l in res["leaks_detected"]],
                            "passed": detected == expect_leak})
    return results


# --------------------------------------------------------------------------------------
# Independent strict JSON-aware scanner
# --------------------------------------------------------------------------------------
def walk_strings(obj, key=None, label=None, path=""):
    if isinstance(obj, dict):
        lbl = obj.get("field_label") or obj.get("label") or obj.get("document_category") or label
        for k, v in obj.items():
            yield from walk_strings(v, k, lbl, f"{path}/{k}")
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from walk_strings(v, key, label, f"{path}[{i}]")
    elif isinstance(obj, str):
        yield path, key, label, obj


def is_benign_identifier_value(key, s):
    if key in ("source_url",):
        return bool(re.fullmatch(r"/(?:download_jc\?DOC_ID=|certificate\?CER_NO=|covidcertificate\?[A-Za-z_]+=)[A-Za-z0-9%+/=_.\-]*", s))
    if key == "document_identifier":
        return bool(TOKEN_FULL.match(s)) or any(p.fullmatch(s) for p in KNOWN_ID_PATTERNS)
    return False


def strict_scan_text_value(key, label, s):
    """Returns list of (class, matched) hits for one string value."""
    if is_benign_identifier_value(key, s):
        return []
    hits = []
    t = GSTIN_VALUE_REGEX.sub(" ", s)
    t = URL_TOKEN.sub(" ", t)
    for p in KNOWN_ID_PATTERNS:
        t = p.sub(" ", t)
    if key in ("extraction_timestamp", "created_at", "updated_at", "discovery_timestamp", "timestamp_utc"):
        return []
    for m in PAN_VALUE_REGEX.finditer(t):
        hits.append(("pan_token", m.group(0)))
    for m in AADHAAR_GROUPED_VALUE_REGEX.finditer(t):
        hits.append(("aadhaar_grouped", m.group(0)))
    for m in AADHAAR_CONTINUOUS_VALUE_REGEX.finditer(t):
        hits.append(("aadhaar_continuous_12digit", m.group(0)))
    for m in EMAIL_VALUE_REGEX.finditer(t):
        hits.append(("email", m.group(0)))
    for m in INDIAN_MOBILE_VALUE_REGEX.finditer(t):
        txt = m.group(0)
        if CONTACT_LABEL.search(label or "") or re.search(r"\+91|0091", txt):
            hits.append(("phone_contact_labelled", txt))
        else:
            hits.append(("phone_like_digits_in_non_contact_field", txt))
    for tok in ("SYNTHETIC_PAN", "SYNTHETIC_INDIVIDUAL", "SYNTHETIC_PERSONAL", "[REDACTED_PII"):
        if tok in s:
            hits.append(("unscrubbed_placeholder_token", tok))
    return hits


def strict_scan_json(obj):
    out = []
    for path, key, label, s in walk_strings(obj):
        for cls, m in strict_scan_text_value(key, label, s):
            out.append({"class": cls, "path": path, "key": key, "label": label, "match_masked": mask(m)})
    return out


# --------------------------------------------------------------------------------------
# D. Full-pipeline synthetic adversarial run
# --------------------------------------------------------------------------------------
PIPELINE_HTML = """
<div id="result">
  <div class="row"><p>Project Name : AUDIT TOWER</p><p>Acknowledgement Number : PR/KN/260101/000777</p>
  <p>Registration Number : PRM/KA/RERA/1251/446/PR/260101/000777</p></div>
  <ul class="nav nav-tabs">
    <li><a href="#home">Promoter Details</a></li><li><a href="#menu1">Project Details</a></li>
    <li><a href="#menu2">Uploaded Documents</a></li><li><a href="#menu5">Enquired Documents</a></li>
    <li><a href="#menu6">Quarterly Updates</a></li>
  </ul>
  <div class="tab-content">
    <div id="home" class="tab-pane active"><h1>Promoter Details</h1>
      <div class="row">
        <div class="col-md-3"><p>Company Name :</p></div><div class="col-md-3"><p>AUDIT INFRA PRIVATE LIMITED</p></div>
        <div class="col-md-3"><p>GSTIN :</p></div><div class="col-md-3"><p>29AAACS8899K1Z5</p></div>
      </div>
      <div class="row">
        <div class="col-md-3"><p>GSTIN (alt) :</p></div><div class="col-md-3"><p>GST-QWERT4321P</p></div>
        <div class="col-md-3"><p>Corporate Email :</p></div><div class="col-md-3"><p>info@auditinfra.co.in</p></div>
      </div>
      <div class="row">
        <div class="col-md-3"><p>Tax Note :</p></div><div class="col-md-3"><p>See DOC_ID=abc123,ZZZZZ9999Z ref</p></div>
        <div class="col-md-3"><p>Certificate :</p></div><div class="col-md-3"><a href="/download_jc?DOC_ID=AjpCK%2FlMr5s%2BMwNUP9599A%3D%3D">Reg_Cert.pdf</a></div>
      </div>
      <h1>Director Details</h1>
      <table><tbody>
        <tr><td>Name :</td><td>Ravi Kumar</td><td>Present Address :</td><td>Flat 12, 3rd Cross, Malleshwaram, Bengaluru 560003</td></tr>
        <tr><td>Mobile :</td><td>+91 98450 11223</td><td>Email :</td><td>ravi.k@gmail.com</td></tr>
        <tr><td>Photograph :</td><td><a href="/download_jc?DOC_ID=7001">Director_Ravi_Photo.jpg</a></td><td>PAN :</td><td>QWERT4321P</td></tr>
      </tbody></table>
    </div>
    <div id="menu1" class="tab-pane"><h1>Project Details</h1>
      <div class="row">
        <div class="col-md-3"><p>Project Site Address :</p></div><div class="col-md-3"><p>Sy No 88/2, Whitefield, Bengaluru 560066</p></div>
        <div class="col-md-3"><p>Total Area (Sq Mtr) :</p></div><div class="col-md-3"><p>12345.67</p></div>
      </div>
    </div>
    <div id="menu2" class="tab-pane"><h1>Uploaded Documents</h1>
      <table><thead><tr><th>Document Name</th><th>Document</th></tr></thead><tbody>
        <tr><td>Sanctioned Plan</td><td><a href="/download_jc?DOC_ID=8001">BBMP_Plan.pdf</a></td></tr>
        <tr><td>KYC</td><td><a href="/download_jc?DOC_ID=8002">Aadhaar_234567890123.pdf</a></td></tr>
        <tr><td>Project Photo</td><td><img src="/download_jc?DOC_ID=8003" alt="Site photo"/></td></tr>
      </tbody></table>
    </div>
    <div id="menu5" class="tab-pane"><h1>Enquired Documents</h1>
      <div class="row">
        <div class="col-md-3"><p>Borewell Photo :</p></div><div class="col-md-3"><a href="/download_jc?DOC_ID=9001">borewell_site.jpg</a></div>
      </div>
    </div>
    <div id="menu6" class="tab-pane"><h1>Quarterly Updates</h1>
      <h2>Project Photographs</h2>
      <table><tbody><tr><td>Photograph-1*</td><td><img src="/download_jc?DOC_ID=9101" alt=""/></td></tr></tbody></table>
    </div>
  </div>
</div>
"""


def run_pipeline_test():
    engine = KRERADiscoveryEngine(enforce_pii_policy=True, require_identity_verification=True)
    raw = parse_project_detail_modal_html(raw_html=PIPELINE_HTML, scrub_raw_pii=True)
    proj = engine.create_project({"PROJECT NAME": "AUDIT TOWER", "ACKNOWLEDGEMENT NO": "PR/KN/260101/000777",
                                  "REGISTRATION NO": "PRM/KA/RERA/1251/446/PR/260101/000777"})
    proj = engine.process_project_details(proj, raw)
    raw_txt = json.dumps(raw, default=str)
    norm_txt = proj.model_dump_json()
    combined = raw_txt + "\n" + norm_txt
    forbidden = {"QWERT4321P": "PAN (incl. inside GST-labelled field, Director table, and glued after DOC_ID)",
                 "ZZZZZ9999Z": "PAN glued after DOC_ID token with comma in ordinary field",
                 "234567890123": "Aadhaar 12-digit in filename", "98450 11223": "personal mobile", "ravi.k@gmail.com": "personal email",
                 "Malleshwaram": "residential address", "Director_Ravi_Photo.jpg": "personal photograph filename"}
    retained = {"AUDIT INFRA PRIVATE LIMITED": "corporate promoter name", "29AAACS8899K1Z5": "valid GSTIN", "info@auditinfra.co.in": "corporate email",
                "Sy No 88/2, Whitefield, Bengaluru 560066": "project site address", "12345.67": "project area value",
                "BBMP_Plan.pdf": "legit document filename", "Reg_Cert.pdf": "corporate registration certificate doc",
                "borewell_site.jpg": "site photo link (Enquired Documents)", "8003": "Project Photo table <img> link DOC_ID 8003",
                "9101": "Project Photographs table <img> link DOC_ID 9101", "9001": "borewell photo link DOC_ID"}
    f_res = [{"token_masked": mask(k), "what": v, "leaked": k in combined, "passed": k not in combined} for k, v in forbidden.items()]
    r_res = [{"expected_retained": k if len(k) < 40 else k[:30] + "...", "what": v, "retained": k in combined, "passed": k in combined}
             for k, v in retained.items()]
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        (td / "p_raw.json").write_text(json.dumps({"raw_dom_payload": raw}, default=str), encoding="utf-8")
        (td / "p_norm.json").write_text(norm_txt, encoding="utf-8")
        prod = scan_phase3c_outputs_for_pii([{"batch_index": 1, "raw_output_file": "p_raw.json", "normalized_output_file": "p_norm.json"}], td)
        strict = strict_scan_json(json.loads(norm_txt)) + strict_scan_json({"raw_dom_payload": raw})
    return {"forbidden_tokens": f_res, "must_retain": r_res, "production_scanner_leaks": prod["leaks_detected_count"],
            "independent_strict_scanner_hits": len(strict), "exclusion_reasons": [e.reason if hasattr(e, "reason") else str(e) for e in proj.pii_exclusions][:40]}


# --------------------------------------------------------------------------------------
# E. Corpus scan of all 250 raw + 250 normalized files
# --------------------------------------------------------------------------------------
def corpus_scan():
    projects = manifest_projects()
    cls_counter = Counter()
    by_label = defaultdict(Counter)
    samples = defaultdict(list)
    token_suppressed = Counter()
    files = 0
    gst_label_values = Counter()
    for p in projects:
        for f in project_files(p):
            files += 1
            obj = jload(f)
            # How many PAN-like substrings live inside benign DOC_ID tokens (what the production scanner suppresses)?
            for path, key, label, s in walk_strings(obj):
                if is_benign_identifier_value(key, s) or URL_TOKEN.search(s):
                    token_suppressed["pan_like_substring_inside_doc_token"] += len(PAN_VALUE_REGEX.findall(s))
                if key in ("raw_value", "normalized_value", "value") and re.search(r"gst", label or "", re.I):
                    st = "valid_gstin" if GSTIN_VALUE_REGEX.fullmatch(str(s).strip()) else ("empty" if not str(s).strip() else "other_nonempty")
                    gst_label_values[st] += 1
                    if st == "other_nonempty" and len(samples["gst_label_other"]) < 10:
                        samples["gst_label_other"].append({"file": f.name, "label": label, "value_masked": mask(s)})
            for h in strict_scan_json(obj):
                cls_counter[h["class"]] += 1
                by_label[h["class"]][h["label"] or "<none>"] += 1
                if len(samples[h["class"]]) < 15:
                    samples[h["class"]].append({"file": f.name, "path": h["path"], "label": h["label"], "match_masked": h["match_masked"]})
    return {"files_scanned": files, "strict_scanner_hit_counts": dict(cls_counter),
            "hits_by_class_and_label_top15": {k: dict(v.most_common(15)) for k, v in by_label.items()},
            "samples_masked": dict(samples),
            "pan_like_substrings_suppressed_inside_doc_tokens": dict(token_suppressed),
            "gst_labelled_field_value_classes": dict(gst_label_values)}


def exclusion_statistics():
    """Aggregates the persisted pii_exclusions to quantify over-exclusion candidates."""
    cat = Counter()
    site_img = Counter()
    enq_photo = Counter()
    id_doc_excl_labels = Counter()
    pan_value_excl_fields = Counter()
    aadhaar_value_excl_fields = Counter()
    total = 0
    img_total = 0
    for p in manifest_projects():
        _, nf = project_files(p)
        n = jload(nf)
        for e in n.get("pii_exclusions", []):
            total += 1
            cat[e.get("pii_category")] += 1
            r = e.get("reason", "")
            sec = e.get("section_label", "")
            if e.get("redaction_action") == "excluded_image":
                img_total += 1
                site_img[(e.get("tab_label"), sec)] += 1
            if "personal photograph field/link in 'Enquired Documents'" in r:
                enq_photo[e.get("field_or_column_label")] += 1
            if "identity document or filename containing PAN/Aadhaar/ID pattern" in r:
                id_doc_excl_labels[e.get("field_or_column_label")] += 1
            if "Indian PAN pattern in field" in r:
                pan_value_excl_fields[e.get("field_or_column_label")] += 1
            if "Aadhaar number pattern in field" in r:
                aadhaar_value_excl_fields[e.get("field_or_column_label")] += 1
    return {"total_exclusions": total, "by_category": dict(cat), "excluded_image_total": img_total,
            "excluded_images_by_tab_section": [{"tab": k[0], "section": k[1], "count": v} for k, v in site_img.most_common()],
            "enquired_documents_photo_exclusions_by_label": dict(enq_photo.most_common()),
            "enquired_documents_photo_exclusions_total": sum(enq_photo.values()),
            "filename_pattern_exclusions_by_doc_label": dict(id_doc_excl_labels.most_common(40)),
            "value_matched_PAN_exclusions_by_field_label": dict(pan_value_excl_fields.most_common()),
            "value_matched_Aadhaar_exclusions_by_field_label": dict(aadhaar_value_excl_fields.most_common())}


def main():
    cm = run_classifier_matrix()
    sc = run_production_scanner_tests()
    pipe = run_pipeline_test()
    corp = corpus_scan()
    exs = exclusion_statistics()
    return {
        "generated_at_utc": now_iso(),
        "scope": "Synthetic adversarial fixtures + read-only strict scan of the 250 raw and 250 normalized Phase 3C files. Values are masked in this report.",
        "classifier_matrix": {"cases": len(cm), "passed": sum(c["passed"] for c in cm), "failed": [c for c in cm if not c["passed"]], "all_cases": cm},
        "production_scanner_adversarial": {"cases": len(sc), "passed": sum(c["passed"] for c in sc), "results": sc},
        "full_pipeline_synthetic_run": pipe,
        "corpus_strict_scan": corp,
        "persisted_exclusion_statistics": exs,
    }


if __name__ == "__main__":
    o = main()
    cm = o["classifier_matrix"]
    print("classifier", cm["passed"], "/", cm["cases"])
    for c in cm["failed"]:
        print("  FAIL", c["id"], c["vector"], "expected_excl=", c["expect_excluded"], "->", c["actually_excluded"])
    sc = o["production_scanner_adversarial"]
    print("scanner", sc["passed"], "/", sc["cases"])
    for r in sc["results"]:
        if not r["passed"]:
            print("  FAIL", r["case"], r["production_scanner_detected"])
    p = o["full_pipeline_synthetic_run"]
    print("pipeline leaked:", [x["what"] for x in p["forbidden_tokens"] if not x["passed"]])
    print("pipeline not retained:", [x["what"] for x in p["must_retain"] if not x["passed"]])
    print("prod scanner leaks:", p["production_scanner_leaks"], "strict hits:", p["independent_strict_scanner_hits"])
    print(json.dumps(o["corpus_strict_scan"]["strict_scanner_hit_counts"]))
    print(json.dumps(o["corpus_strict_scan"]["pan_like_substrings_suppressed_inside_doc_tokens"]), json.dumps(o["corpus_strict_scan"]["gst_labelled_field_value_classes"]))
    print(json.dumps(o["persisted_exclusion_statistics"]["excluded_images_by_tab_section"][:8]))

"""
HomeSure Phase 4 — Name Normalization, Geographical Classification & Firestore Integrity Tests
"""

import json
import sys
from pathlib import Path

import pytest

EXTRACTION_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_ROOT = EXTRACTION_ROOT / "scripts"
FIRESTORE_IMPORT_ROOT = SCRIPTS_ROOT / "firestore_import"
for p in (str(SCRIPTS_ROOT), str(FIRESTORE_IMPORT_ROOT)):
    if p not in sys.path:
        sys.path.insert(0, p)

from geography import (
    BENGALURU_URBAN_CANONICAL_TALUKS,
    audit_geography_exceptions,
    build_geography_block,
    normalize_district,
    normalize_taluk,
)
from name_normalization import (
    build_normalized_search_tokens,
    build_project_normalization,
    normalize_builder_name,
    normalize_corporate_entity_name,
    normalize_text,
    resolve_builder_identity,
)
from import_projects import (
    make_deterministic_project_id,
    should_write_project,
    transform_catalogue_row,
)
from build_and_upload_builders import chunk_builders_by_size


class TestBuilderDisambiguationAndNormalization:
    def test_sobha_limited_vs_sobha_rani_separation(self):
        # Genuine corporate Sobha registrations
        r1 = resolve_builder_identity("Sobha Neopolis Phase 1 - W 14, 15, 16, 17, 18 &19", "SOBHA LIMITED")
        r2 = resolve_builder_identity("Sobha Indraprastha", "Sobha Limited")
        assert r1["builder_id"] == "builder_sobha_limited"
        assert r2["builder_id"] == "builder_sobha_limited"
        assert r1["name_normalization_confidence"] == "exact_entity"

        # Individual promoter SOBHA RANI must NEVER map to Sobha Limited
        r_rani = resolve_builder_identity("ADITHYA HOMES ELITE", "SOBHA RANI")
        assert r_rani["builder_id"] != "builder_sobha_limited"
        assert r_rani["builder_id"] == "builder_sobha_rani"
        assert r_rani["is_featured_brand"] is False

    def test_pride_and_radiance_false_positive_prevention(self):
        # Unrelated developers with generic word "Pride" or "Radiance" in project title
        assert resolve_builder_identity("GS LNS PRIDE", "lnsinfra")["builder_id"] != "builder_pride_group"
        assert resolve_builder_identity("MVR PRIDE", "C P MAHESHWAR REDDY")["builder_id"] != "builder_pride_group"
        assert (
            resolve_builder_identity("Disha Pursuit of Radiance", "DISHAHABITAT HOMES LLP")["builder_id"]
            != "builder_radiance_realty"
        )

        # Genuine Pride & Radiance entities still group properly
        assert resolve_builder_identity("Pride Enchanta Phase I", "Pride & Expert Properties Private Limited")["builder_id"] == "builder_pride_group"
        assert resolve_builder_identity("PRIDE SUNRISE", "PRIDE HOUSING")["builder_id"] == "builder_pride_group"
        assert resolve_builder_identity("Radiance IRIS", "Radiance Realty Developers India Limited")["builder_id"] == "builder_radiance_realty"

    def test_assetz_spv_and_alias_normalization(self):
        # 63 Degree East under APG Intelli Homes Private Limited
        pnorm = build_project_normalization(
            project_name="63 Degree East - Tower A",
            promoter_name="APG Intelli Homes Private Limited",
            registration_number="PRM/KA/RERA/1251/446/PR/240122/004656",
            canonical_project_id="REG_PRM_KA_RERA_1251_446_PR_240122_004656",
        )
        assert pnorm["builderId"] == "builder_assetz_group"
        assert pnorm["nameNormalizationConfidence"] == "verified_spv"
        assert pnorm["officialProjectName"] == "63 Degree East - Tower A"
        assert pnorm["officialBuilderName"] == "APG Intelli Homes Private Limited"
        assert "ASSETZ 63 DEGREE EAST" in pnorm["projectAliases"]
        assert "ASSETZ 63 DEGREES EAST" in pnorm["projectAliases"]
        assert "ASSETZ 63 DEGREE EAST TOWER A" in pnorm["projectAliases"]

        # ASSETZ REN & REI under APG PREMIUM RESIDENTIAL PRIVATE LIMITED
        ren_norm = build_project_normalization(
            project_name="ASSETZ REN &amp; REI",
            promoter_name="APG PREMIUM RESIDENTIAL PRIVATE LIMITED",
            registration_number="PRM/KA/RERA/1251/446/PR/130225/007501",
            canonical_project_id="REG_PRM_KA_RERA_1251_446_PR_130225_007501",
        )
        assert ren_norm["builderId"] == "builder_assetz_group"
        assert ren_norm["officialProjectName"] == "ASSETZ REN & REI"
        assert ren_norm["normalizedProjectName"] == "ASSETZ REN AND REI"
        assert "ASSETZ REN AND REI" in ren_norm["projectAliases"]
        assert "REN AND REI" in ren_norm["projectAliases"]
        assert "REN & REI" in ren_norm["projectAliases"]

    def test_separate_registrations_keep_distinct_canonical_ids(self):
        id1 = make_deterministic_project_id("REG::PRM/KA/RERA/1251/446/PR/200923/006269", "PRM/KA/RERA/1251/446/PR/200923/006269")
        id2 = make_deterministic_project_id("REG::PRM/KA/RERA/1251/446/PR/200923/006270", "PRM/KA/RERA/1251/446/PR/200923/006270")
        assert id1 != id2

    def test_normalize_builder_name_strips_legal_suffixes(self):
        assert normalize_builder_name("M/s. SOBHA LIMITED") == "SOBHA"
        assert normalize_builder_name("Assetz Whitefield Homes Private Limited") == "ASSETZ WHITEFIELD"
        assert normalize_text("Ren &amp; Rei - Phase 1") == "REN AND REI PHASE 1"
        assert normalize_text("Park's Ridge") == "PARKS RIDGE"
        assert normalize_text("ren and amp") == "REN AND"

    def test_sattva_and_non_featured_legal_entity_guards(self):
        # Incidental "Sattva" in third-party projects must NOT collapse into Sattva Group
        assert resolve_builder_identity("Sri Sri Sattva", "SRI SUMERU REALTY PRIVATE LIMITED")["builder_id"] != "builder_sattva_group"
        assert resolve_builder_identity("THARUNS B V SATTVA", "BV BUILDERS")["builder_id"] != "builder_sattva_group"
        # Genuine Sattva prefix / promoter still maps properly
        assert resolve_builder_identity("Sattva Park Cubix", "SALARPURIA PROPERTIES PRIVATE LIMITED")["builder_id"] == "builder_sattva_group"

        # Non-featured legal entities with distinct nouns ("Builders" vs "Ventures" vs "Infrastructures") must stay distinct
        b_united_b = resolve_builder_identity("Proj A", "M/s. UNITED BUILDERS")
        b_united_i = resolve_builder_identity("Proj B", "M/s. UNITED INFRASTRUCTURES")
        assert b_united_b["builder_id"] != b_united_i["builder_id"]
        assert b_united_b["builder_id"] == "builder_united_builders"
        assert b_united_i["builder_id"] == "builder_united_infrastructures"

        b_sow = resolve_builder_identity("Sowparnika Ashiyana", "SOWPARNIKA PROJECTS AND INFRASTRUCTURE PVT. LTD.")
        assert not b_sow["builder_id"].endswith("_and")
        assert normalize_corporate_entity_name("SOWPARNIKA PROJECTS AND INFRASTRUCTURE PVT. LTD.") == "SOWPARNIKA PROJECTS AND INFRASTRUCTURE"


class TestGeographyClassification:
    def test_five_canonical_taluks_preserved(self):
        assert normalize_taluk("Anekal") == "Anekal"
        assert normalize_taluk("Yelahanka") == "Yelahanka"
        assert normalize_taluk("Bangalore East") == "Bengaluru East"
        assert normalize_taluk("Bengaluru North") == "Bengaluru North"
        assert normalize_taluk("Bengaluru South") == "Bengaluru South"
        assert len(BENGALURU_URBAN_CANONICAL_TALUKS) == 5

    def test_rural_not_coerced_to_urban(self):
        geo = build_geography_block("Bengaluru  Rural", "Devanahalli", "Devanahalli, Bengaluru")
        assert geo["district"] == "Bengaluru  Rural"
        assert geo["normalizedDistrict"] == "Bengaluru Rural"
        assert geo["normalizedTaluk"] == "Devanahalli"

        audit = audit_geography_exceptions([
            {
                "registration_number": "R1",
                "project_name": "Rural Project",
                "district": "Bengaluru  Rural",
                "taluk": "Devanahalli",
                "project_address": "Devanahalli, Bengaluru",
            },
            {
                "registration_number": "R2",
                "project_name": "Missing Geo",
                "district": "",
                "taluk": "",
            },
        ])
        assert audit["address_ambiguity_count"] == 1
        assert audit["missing_district_count"] == 1
        assert audit["missing_taluk_count"] == 1


class TestFirestoreIdempotencyAndChunking:
    def test_idempotent_hash_and_deep_extracted_protection(self):
        deep_existing = {
            "provenance": {"data_tier": "deep_extracted", "content_hash": "abc123"},
            "counts": {"total_fields": 150},
        }
        cat_incoming = {
            "provenance": {"data_tier": "catalogue_summary", "content_hash": "xyz999"},
            "counts": {"total_fields": 0},
        }
        # Must NEVER overwrite deep_extracted with catalogue_summary even if force_update=True
        do_write, reason = should_write_project(cat_incoming, deep_existing, force_update=True)
        assert do_write is False
        assert reason == "skipped_richer_existing"

        # Same hash skips without force_update
        deep_same = {
            "provenance": {"data_tier": "deep_extracted", "content_hash": "abc123"},
            "counts": {"total_fields": 150},
        }
        assert should_write_project(deep_same, deep_existing, force_update=False) == (False, "skipped_unchanged")
        assert should_write_project(deep_same, deep_existing, force_update=True) == (True, "update_existing")

    def test_transform_catalogue_row_preserves_missingness(self):
        doc = transform_catalogue_row({
            "page_number": 313,
            "row_order": 8,
            "record_unique_key": "REG:PRM/KA/RERA/1251/446/PR/200923/006269",
            "registration_number": "PRM/KA/RERA/1251/446/PR/200923/006269",
            "acknowledgement_number": "ACK/KA/RERA/1251/446/PR/250823/007391",
            "promoter_name": "SOBHA LIMITED",
            "project_name": "Sobha Neopolis Phase 1 - W 14, 15, 16, 17, 18 &19",
            "status": "APPROVED",
            "district": "Bengaluru Urban",
            "taluk": "Bengaluru East",
            "project_type": "Residential/Group Housing",
            "approved_on": "20/09/2023",
            "proposed_completion_date": "31/12/2028",
        })
        assert doc["provenance"]["data_tier"] == "catalogue_summary"
        assert doc["builder_id"] == "builder_sobha_limited"
        assert doc["counts"]["total_fields"] == 0
        assert doc["unit_hierarchy_status"]["towers_state"] == "not_available"
        assert "neopolis" in doc["search_metadata"]["search_tokens"]

    def test_chunk_builders_by_size_respects_budget(self):
        builders = [
            {
                "builder_id": f"builder_{i}",
                "builder_name": f"Builder {i}",
                "projects": [{"project_id": f"p_{i}_{j}", "project_name": "X" * 200} for j in range(10)],
            }
            for i in range(450)
        ]
        chunks = chunk_builders_by_size(builders, max_chunk_bytes=650_000, max_builders_per_chunk=200)
        assert len(chunks) >= 3
        for ch in chunks:
            assert len(ch) <= 200
            size = len(json.dumps({"builders": ch}).encode("utf-8"))
            assert size <= 650_000

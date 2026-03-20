#!/usr/bin/env python3
"""Automated skill recommender for the iscagent repo augmentation pipeline.

Reads a knowledge graph, extracts signals, matches against:
  1. custom-registry.yaml (iscagent built-in + curated skills)
  2. awesome-agent-skills catalog (549+ community skills, fetched live)

Installs only matched skills into the target repo's .claude/skills/.

Usage:
    python3 recommend-skills.py <target-repo>
    python3 recommend-skills.py <target-repo> --dry-run
    python3 recommend-skills.py <target-repo> --json
    python3 recommend-skills.py <target-repo> --auto   # skip confirmation
"""

import json
import os
import re
import shutil
import sys
import urllib.request
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None

SCRIPT_DIR = Path(__file__).resolve().parent
ISCAGENT_ROOT = SCRIPT_DIR.parent
SKILLS_SRC = ISCAGENT_ROOT / "skills"
CUSTOM_REGISTRY = SKILLS_SRC / "skill-recommender" / "custom-registry.yaml"
CATALOG_URL = "https://raw.githubusercontent.com/VoltAgent/awesome-agent-skills/main/README.md"


# ─── YAML fallback parser (no pyyaml dependency) ────────────────

def parse_yaml_simple(text):
    """Minimal YAML-like parser for custom-registry.yaml (list of dicts)."""
    skills = []
    current = {}
    for line in text.split("\n"):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("- name:"):
            if current:
                skills.append(current)
            current = {"name": stripped.split(":", 1)[1].strip()}
        elif ":" in stripped and current:
            key, val = stripped.split(":", 1)
            key = key.strip().lstrip("- ")
            val = val.strip()
            if val.startswith("[") and val.endswith("]"):
                val = [v.strip().strip("'\"") for v in val[1:-1].split(",") if v.strip()]
            elif val in ("true", "True"):
                val = True
            elif val in ("false", "False"):
                val = False
            elif val.isdigit():
                val = int(val)
            current[key] = val
    if current:
        skills.append(current)
    return skills


def load_custom_registry():
    """Load custom-registry.yaml."""
    if not CUSTOM_REGISTRY.exists():
        return []
    text = CUSTOM_REGISTRY.read_text()
    if yaml:
        data = yaml.safe_load(text)
        return data.get("skills", []) if isinstance(data, dict) else []
    # Fallback parser
    return parse_yaml_simple(text)


# ─── Signal extraction ──────────────────────────────────────────

def extract_signals(graph):
    """Extract matching signals from knowledge graph."""
    meta = graph.get("metadata", {})
    signals = {
        "languages": [l.lower() for l in meta.get("languages", [])],
        "frameworks": [f.lower() for f in meta.get("frameworks", [])],
        "integrations": [i.lower() for i in meta.get("integrations", [])],
        "database": meta.get("database", "").lower(),
        "layers": [l["name"].lower() for l in graph.get("layers", [])],
        "tags": set(),
        "file_patterns": set(),
        "keywords": set(),
    }

    # Aggregate tags and scan node content for patterns
    all_summaries = []
    for node in graph.get("nodes", []):
        for tag in node.get("tags", []):
            signals["tags"].add(tag.lower())
        fp = node.get("filePath", "")
        summary = node.get("summary", "").lower()
        all_summaries.append(summary)
        if "Dockerfile" in fp:
            signals["file_patterns"].add("Dockerfile")
        if ".github/" in fp:
            signals["file_patterns"].add(".github/workflows/")
        if "docker-compose" in fp:
            signals["file_patterns"].add("docker-compose.yml")
        # Detect test-related nodes
        if any(t in fp.lower() for t in ["test", "spec", "phpunit"]):
            signals["tags"].add("testing")
        # Detect migration/SQL patterns
        if any(t in fp.lower() for t in ["migration", "database", ".sql"]):
            signals["tags"].add("migration")
            signals["tags"].add("database")

    # Scan summaries for domain signals that might not be in tags
    combined_text = " ".join(all_summaries)
    domain_probes = {
        "testing": ["test", "phpunit", "jest", "spec", "coverage", "test plan"],
        "migration": ["migration", "schema", "sql migration"],
        "deployment": ["deploy", "ci/cd", "pipeline", "staging"],
        "security": ["auth", "acl", "encrypt", "password", "permission", "role-based"],
        "api": ["api", "rest", "endpoint", "json response"],
        "payment": ["stripe", "payment", "billing", "invoice"],
    }
    for signal_name, probes in domain_probes.items():
        if any(p in combined_text for p in probes):
            signals["tags"].add(signal_name)

    # Derive keywords from tags + frameworks + integrations
    signals["keywords"] = signals["tags"] | set(signals["frameworks"]) | set(signals["integrations"])

    # Also add database type as a keyword
    if signals["database"]:
        signals["keywords"].add(signals["database"])

    # Convert sets to lists for JSON serialization
    signals["tags"] = list(signals["tags"])
    signals["file_patterns"] = list(signals["file_patterns"])
    signals["keywords"] = list(signals["keywords"])

    return signals


# ─── Custom registry matching ───────────────────────────────────

def match_custom_registry(signals, registry):
    """Match signals against custom registry entries. Returns scored list."""
    results = []
    for entry in registry:
        score = 0
        reasons = []
        ms = entry.get("match_signals", {})

        lang_match = False
        fw_match = False
        kw_match = False

        # Language match (weight 3)
        for lang in ms.get("languages", []):
            if lang.lower() in signals["languages"]:
                score += 3
                lang_match = True
                reasons.append(f"{lang} detected")

        # Framework match (weight 5)
        for fw in ms.get("frameworks", []):
            if fw.lower() in signals["frameworks"]:
                score += 5
                fw_match = True
                reasons.append(f"{fw} framework detected")

        # If skill requires specific frameworks and NONE matched, demote heavily.
        # This prevents e.g. php-plesk matching on PHP alone when Plesk isn't used.
        required_frameworks = ms.get("frameworks", [])
        if required_frameworks and not fw_match:
            # Only keep score if language + keyword both match (weaker signal)
            score = max(0, score - 3)

        # Keyword match (weight 2)
        for kw in ms.get("keywords", []):
            if kw.lower() in signals["keywords"] or any(kw.lower() in t for t in signals["tags"]):
                score += 2
                kw_match = True
                reasons.append(f"keyword '{kw}' matched")

        # Layer match (weight 2)
        for layer in ms.get("layers", []):
            if any(layer.lower() in l for l in signals["layers"]):
                score += 2
                reasons.append(f"layer '{layer}' detected")

        # File pattern match (weight 4)
        for fp in ms.get("file_patterns", []):
            if fp in signals["file_patterns"]:
                score += 4
                reasons.append(f"file pattern '{fp}' found")

        # Confidence boost
        score += entry.get("confidence_boost", 0)

        # Always recommend
        if entry.get("always_recommend"):
            score = max(score, 3)
            if not reasons:
                reasons.append("always recommended for any project")

        if score >= 3:  # minimum threshold to avoid noise
            results.append({
                "name": entry["name"],
                "description": entry.get("description", ""),
                "source": entry.get("source", "unknown"),
                "score": score,
                "reasons": reasons,
                "install_type": entry.get("source", "unknown"),  # iscagent, github, claude-code
                "invoke": entry.get("invoke"),
                "url": entry.get("url"),
                "path": entry.get("path"),
            })

    return sorted(results, key=lambda x: -x["score"])


# ─── External catalog matching ──────────────────────────────────

def fetch_catalog():
    """Fetch awesome-agent-skills README and parse skill entries."""
    try:
        req = urllib.request.Request(CATALOG_URL, headers={"User-Agent": "iscagent-recommender/1.0"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            content = resp.read().decode("utf-8")
    except Exception as e:
        print(f"  Warning: could not fetch external catalog: {e}", file=sys.stderr)
        return []

    skills = []
    # Parse markdown list items: - **[org/name](url)** - description
    # Also handles: - **org/name** - description (no link)
    patterns = [
        # **[org/name](url)** - description
        re.compile(r'\*\*\[([a-zA-Z0-9_./-]+)\]\(([^)]+)\)\*\*\s*[-–]\s*(.+)'),
        # **org/name** - description (no link)
        re.compile(r'\*\*([a-zA-Z0-9_./-]+)\*\*\s*[-–]\s*(.+)'),
    ]
    for line in content.split("\n"):
        line = line.strip()
        if not line.startswith("- ") and not line.startswith("| "):
            continue
        for pat in patterns:
            m = pat.search(line)
            if m:
                groups = m.groups()
                if len(groups) == 3:
                    name, url, desc = groups
                elif len(groups) == 2:
                    name, desc = groups
                    url = None
                else:
                    continue
                # Only include entries that look like org/skill-name
                if "/" not in name:
                    continue
                skills.append({
                    "name": name.strip(),
                    "description": desc.strip().rstrip("|").strip(),
                    "url": url,
                    "org": name.split("/")[0] if "/" in name else "",
                })
                break
    return skills


def match_catalog(signals, catalog, already_matched):
    """Match signals against external catalog. Returns scored list."""
    already_names = {r["name"] for r in already_matched}
    results = []

    # Build a search index from signals
    search_terms = set()
    search_terms.update(signals["languages"])
    search_terms.update(signals["frameworks"])
    search_terms.update(signals["integrations"])
    search_terms.update(signals["tags"])
    # Add some derived terms
    if "php" in signals["languages"]:
        search_terms.update(["php", "legacy", "security"])
    if any("api" in t for t in signals["tags"]):
        search_terms.add("api")
    if "stripe" in signals["integrations"]:
        search_terms.update(["stripe", "payment"])
    if any("security" in t or "auth" in t for t in signals["tags"]):
        search_terms.update(["security", "audit", "vulnerability"])
    if any("test" in t for t in signals["tags"]):
        search_terms.add("testing")

    for entry in catalog:
        name = entry["name"].lower()
        desc = entry.get("description", "").lower()
        org = entry.get("org", "").lower()

        # Skip if already matched from custom registry
        if entry["name"] in already_names:
            continue

        score = 0
        reasons = []

        # Match by integration name (highest signal — e.g. stripe/stripe-best-practices)
        # Use word boundary matching to avoid "lob" matching "blob"
        for integ in signals["integrations"]:
            integ_re = re.compile(r'\b' + re.escape(integ) + r'\b', re.IGNORECASE)
            if integ_re.search(name):
                score += 6
                reasons.append(f"integration '{integ}' in skill name")
            elif integ_re.search(desc):
                score += 4
                reasons.append(f"integration '{integ}' in description")

        # Match by org name against integrations (e.g. org "stripe" matches integration "stripe")
        for integ in signals["integrations"]:
            if integ == org:
                score += 3
                reasons.append(f"skill org '{org}' matches integration")

        # Match by language (word boundary, only in skill name — descriptions are too noisy)
        # Skip very common languages that match too broadly (javascript, sql)
        for lang in signals["languages"]:
            if lang in ("javascript", "sql", "html", "css"):
                continue  # too common, causes false positives in external catalog
            lang_re = re.compile(r'\b' + re.escape(lang) + r'\b', re.IGNORECASE)
            if lang_re.search(name):
                score += 3
                reasons.append(f"language '{lang}' in skill name")

        # Match by framework (word boundary, skip very short framework names)
        for fw in signals["frameworks"]:
            if len(fw) < 4:
                continue  # skip "io" etc.
            fw_re = re.compile(r'\b' + re.escape(fw) + r'\b', re.IGNORECASE)
            if fw_re.search(name) or fw_re.search(desc):
                score += 3
                reasons.append(f"framework '{fw}' matched")

        # Match by tags/keywords (only strong matches)
        matched_kw = False
        for term in search_terms:
            if len(term) >= 4 and term in desc:
                score += 1
                if not matched_kw:
                    reasons.append(f"keyword '{term}' in description")
                    matched_kw = True

        # Security skills from Trail of Bits get a boost, but only for
        # generalist security skills (not smart contracts, firebase, DWARF, etc.)
        tob_exclude = ["contract", "firebase", "apk", "dwarf", "chrome", "semgrep", "variant"]
        if org == "trailofbits" and any(t in signals["tags"] for t in ["security", "auth", "payment"]):
            if not any(ex in name or ex in desc for ex in tob_exclude):
                score += 2
                reasons.append("security org + production signals")

        # Filter out noise: require minimum score and at least one strong signal
        # (integration match or security org). Pure keyword matches are too noisy.
        has_strong_signal = any(
            "integration" in r or "org" in r
            for r in reasons
        )
        if score >= 5 or (score >= 4 and has_strong_signal):
            results.append({
                "name": entry["name"],
                "description": entry.get("description", ""),
                "source": "external-catalog",
                "score": score,
                "reasons": reasons[:3],  # top 3 reasons
                "install_type": "external-catalog",
                "url": entry.get("url"),
            })

    return sorted(results, key=lambda x: -x["score"])[:8]  # top 8 external matches


# ─── Confidence bucketing ───────────────────────────────────────

def bucket_results(results):
    """Bucket results into high/medium/low confidence."""
    high = [r for r in results if r["score"] >= 5]
    medium = [r for r in results if 3 <= r["score"] < 5]
    low = [r for r in results if r["score"] < 3]
    return high, medium, low


# ─── Installation ───────────────────────────────────────────────

def install_iscagent_skill(name, target_dir):
    """Install an iscagent built-in skill to target."""
    src = SKILLS_SRC / name
    if not src.exists() or not (src / "SKILL.md").exists():
        return False
    dest = target_dir / name
    dest.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src / "SKILL.md", dest / "SKILL.md")
    # Copy supporting files
    for f in src.iterdir():
        if f.name != "SKILL.md" and f.is_file():
            shutil.copy2(f, dest / f.name)
    return True


def install_external_skill(name, url, target_dir):
    """Fetch and install an external skill from GitHub."""
    dest = target_dir / name.replace("/", "-")
    dest.mkdir(parents=True, exist_ok=True)

    # Build list of URLs to try, based on known catalog URL patterns
    urls_to_try = []

    if url:
        # If URL points to a GitHub tree, convert to raw content URLs
        # e.g. https://github.com/stripe/ai/tree/main/skills/stripe-best-practices
        tree_match = re.match(r'https://github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.+)', url)
        if tree_match:
            owner, repo, branch, path = tree_match.groups()
            raw_base = f"https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}"
            urls_to_try.extend([
                f"{raw_base}/SKILL.md",
                f"{raw_base}/skill.md",
                f"{raw_base}/README.md",
                f"{raw_base}.md",  # path itself might be the file
            ])
        elif "SKILL.md" in url or "README.md" in url:
            urls_to_try.append(url)
        else:
            urls_to_try.append(url)

    # Fallback: construct from org/skill-name
    if "/" in name:
        org, skill = name.split("/", 1)
        urls_to_try.extend([
            f"https://raw.githubusercontent.com/{org}/{org}/main/skills/{skill}/SKILL.md",
            f"https://raw.githubusercontent.com/{org}/ai/main/skills/{skill}/SKILL.md",
            f"https://raw.githubusercontent.com/{org}/agent-skills/main/skills/{skill}/SKILL.md",
            f"https://raw.githubusercontent.com/{org}/{skill}/main/SKILL.md",
            f"https://raw.githubusercontent.com/{org}/{skill}/main/README.md",
        ])

    for try_url in urls_to_try:
        try:
            req = urllib.request.Request(try_url, headers={"User-Agent": "iscagent-recommender/1.0"})
            with urllib.request.urlopen(req, timeout=10) as resp:
                content = resp.read().decode("utf-8")
            if len(content) > 50:  # sanity check
                (dest / "SKILL.md").write_text(content)
                return True
        except Exception:
            continue
    return False


# ─── Main ───────────────────────────────────────────────────────

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Automated skill recommender for iscagent")
    parser.add_argument("target", help="Path to target repository")
    parser.add_argument("--dry-run", action="store_true", help="Show recommendations without installing")
    parser.add_argument("--json", action="store_true", dest="as_json", help="Output as JSON")
    parser.add_argument("--auto", action="store_true", help="Install all high+medium confidence without prompting")
    parser.add_argument("--graph", help="Path to knowledge graph (default: <target>/.understand/knowledge-graph.json)")
    args = parser.parse_args()

    target = Path(args.target).resolve()
    graph_path = Path(args.graph) if args.graph else target / ".understand" / "knowledge-graph.json"
    skills_dest = target / ".claude" / "skills"

    # Load knowledge graph
    if not graph_path.exists():
        print(f"Error: knowledge graph not found at {graph_path}", file=sys.stderr)
        print("Run codebase-understanding first to generate .understand/knowledge-graph.json", file=sys.stderr)
        sys.exit(1)

    with open(graph_path) as f:
        graph = json.load(f)

    # Step 1: Extract signals
    signals = extract_signals(graph)
    project_name = graph.get("metadata", {}).get("projectName", target.name)

    if not args.as_json:
        print(f"\nSkill Recommender — {project_name}")
        print("=" * 50)
        print(f"\nExtracted signals:")
        print(f"  Languages:    {', '.join(signals['languages'])}")
        print(f"  Frameworks:   {', '.join(signals['frameworks'])}")
        print(f"  Integrations: {', '.join(signals['integrations'])}")
        print(f"  Database:     {signals['database']}")
        print(f"  Layers:       {', '.join(signals['layers'][:5])}")
        print(f"  Tags:         {', '.join(list(signals['tags'])[:10])}")
        print()

    # Step 2: Match custom registry
    registry = load_custom_registry()
    custom_matches = match_custom_registry(signals, registry)

    # Step 3: Match external catalog
    if not args.as_json:
        print("Fetching external catalog...")
    catalog = fetch_catalog()
    external_matches = match_catalog(signals, catalog, custom_matches)

    # Step 4: Combine and bucket
    all_matches = custom_matches + external_matches
    high, medium, low = bucket_results(all_matches)

    # JSON output
    if args.as_json:
        output = {
            "project": project_name,
            "signals": {k: v for k, v in signals.items() if not isinstance(v, set)},
            "recommendations": {
                "high": high,
                "medium": medium,
                "low": low,
            },
            "total": len(all_matches),
        }
        print(json.dumps(output, indent=2))
        if args.dry_run:
            return
    else:
        # Human output
        def print_bucket(label, items):
            if not items:
                return
            print(f"\n{label}:")
            print(f"  {'Name':<40s} {'Source':<15s} Why")
            print(f"  {'─'*40} {'─'*15} {'─'*40}")
            for r in items:
                reason = "; ".join(r["reasons"][:2])
                src = r.get("install_type", r.get("source", ""))
                marker = ""
                if src == "claude-code":
                    marker = " (slash skill)"
                print(f"  {r['name']:<40s} {src:<15s} {reason}{marker}")

        print_bucket("HIGH CONFIDENCE", high)
        print_bucket("MEDIUM CONFIDENCE", medium)
        if low:
            print_bucket("LOW CONFIDENCE (not installed)", low)
        print()

    # Step 5: Install
    if args.dry_run:
        if not args.as_json:
            print("(Dry run — nothing installed)")
        return

    to_install = high + medium  # install high + medium confidence

    if not args.auto and not args.as_json:
        answer = input(f"Install {len(to_install)} skills to {skills_dest}? [Y/n] ").strip().lower()
        if answer and answer != "y":
            print("Skipped.")
            return

    if not args.as_json:
        print(f"\nInstalling {len(to_install)} skills to {skills_dest}/")

    skills_dest.mkdir(parents=True, exist_ok=True)
    installed = 0
    skipped = 0
    noted = 0

    for rec in to_install:
        source = rec.get("install_type", rec.get("source", ""))

        if source == "claude-code":
            # Slash skills don't need installation — just note them
            if not args.as_json:
                print(f"  NOTE  {rec['name']} — invoke via {rec.get('invoke', '/' + rec['name'])}")
            noted += 1
            continue

        if source == "iscagent":
            ok = install_iscagent_skill(rec["name"], skills_dest)
            if ok:
                if not args.as_json:
                    print(f"  NEW   {rec['name']} (iscagent)")
                installed += 1
            else:
                if not args.as_json:
                    print(f"  SKIP  {rec['name']} (not found in iscagent)")
                skipped += 1

        elif source in ("github", "external-catalog"):
            url = rec.get("url")
            ok = install_external_skill(rec["name"], url, skills_dest)
            if ok:
                if not args.as_json:
                    print(f"  NEW   {rec['name']} (fetched)")
                installed += 1
            else:
                if not args.as_json:
                    print(f"  SKIP  {rec['name']} (fetch failed)")
                skipped += 1

    if not args.as_json:
        print(f"\nDone: {installed} installed, {noted} slash skills noted, {skipped} skipped")


if __name__ == "__main__":
    main()

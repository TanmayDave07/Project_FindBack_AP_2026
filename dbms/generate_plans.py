#!/usr/bin/env python3
"""
Generate dbms/plans/Qxx.txt (EXPLAIN (ANALYZE, BUFFERS) output) for every
query in dbms/04_queries.sql.

Usage (from the repo root):
    python3 dbms/generate_plans.py [database]        # default: findback_db
Needs `psql` on PATH and a database that already has 03_schema.sql loaded
plus some data. WRITE queries run inside BEGIN ... ROLLBACK, so no data changes.
Placeholder ids such as 'user-uuid-here' are replaced with real ids found in
the database, so each plan runs against real rows.
"""
import os, re, subprocess, sys

DB = sys.argv[1] if len(sys.argv) > 1 else "findback_db"
PSQL = os.environ.get("PSQL_CMD", "psql").split()
ROOT = os.path.dirname(os.path.abspath(__file__))
SQL_FILE = os.path.join(ROOT, "04_queries.sql")
OUT = os.path.join(ROOT, "plans")


def psql(sql):
    r = subprocess.run(PSQL + ["-X", "-q", "-A", "-t", "-d", DB, "-c", sql],
                       capture_output=True, text=True)
    if r.returncode:
        raise RuntimeError(r.stderr.strip())
    return r.stdout.strip()


def pick(sql):
    return psql(sql).splitlines()[0]


# ---- real ids from the database -------------------------------------------
users = psql('SELECT "id" FROM "User" ORDER BY "createdAt","id" LIMIT 4').splitlines()
user_a, user_b = users[0], users[1]
category = pick('SELECT "categoryId" FROM "ItemReport" GROUP BY 1 ORDER BY COUNT(*) DESC LIMIT 1')
location = pick('SELECT "locationId" FROM "ItemReport" GROUP BY 1 ORDER BY COUNT(*) DESC LIMIT 1')
# a pair of reports that already has a match, a claim on the found report, a handover
match_id, lost_id, found_id = pick(
    'SELECT "id"||\'|\'||"lostReportId"||\'|\'||"foundReportId" FROM "Match" ORDER BY "id" LIMIT 1').split("|")
claim_id, claimant = pick(
    f'SELECT "id"||\'|\'||"userId" FROM "Claim" WHERE "foundReportId"=\'{found_id}\' LIMIT 1').split("|")
ver_id = pick(f'SELECT "id" FROM "Verification" WHERE "claimId"=\'{claim_id}\' LIMIT 1')
ho_claim = pick('SELECT "claimId" FROM "Handover" LIMIT 1')
free_claim, finder, receiver = pick(
    'SELECT c."id"||\'|\'||i."userId"||\'|\'||c."userId" FROM "Claim" c '
    'JOIN "ItemReport" i ON i."id"=c."foundReportId" '
    'WHERE NOT EXISTS (SELECT 1 FROM "Handover" h WHERE h."claimId"=c."id") '
    'AND i."userId"<>c."userId" LIMIT 1').split("|")
reviewer = user_a

# query-specific overrides, then generic placeholder map
per_query = {
    "Q22": {"claim-uuid-here": free_claim, "finder-user-uuid": finder, "claimant-user-uuid": receiver},
    "Q23": {"claim-uuid-here": ho_claim},
    "Q09": {"report-uuid-here": found_id},
}
generic = {
    "user-uuid-here": user_b, "category-uuid-here": category, "location-uuid-here": location,
    "report-uuid-here": lost_id, "lost-report-uuid": lost_id, "found-report-uuid": found_id,
    "match-uuid-here": match_id, "claimant-user-uuid": claimant, "claim-uuid-here": claim_id,
    "finder-user-uuid": finder, "reviewer-user-uuid": reviewer,
    "verification-uuid-here": ver_id,
}

# ---- parse 04_queries.sql ---------------------------------------------------
text = open(SQL_FILE, encoding="utf-8").read()
blocks = []
for m in re.finditer(r"-- (READ|WRITE)\s*\n-- (Q\d+): ([^\n]*)\n(.*?;)[ \t]*(?=\n|\Z)", text, re.S):
    blocks.append(m.groups())

os.makedirs(OUT, exist_ok=True)
version = psql("SHOW server_version")
counts = psql('SELECT (SELECT COUNT(*) FROM "ItemReport")||\' reports, \'||(SELECT COUNT(*) FROM "User")||\' users, \'||'
              '(SELECT COUNT(*) FROM "Match")||\' matches, \'||(SELECT COUNT(*) FROM "Claim")||\' claims\'')

for kind, qid, desc, sql in blocks:
    sql = sql.strip().rstrip(";")
    subs = dict(generic); subs.update(per_query.get(qid, {}))
    for k, v in subs.items():
        sql = sql.replace(f"'{k}'", f"'{v}'")
    explain = f"BEGIN; EXPLAIN (ANALYZE, BUFFERS) {sql}; ROLLBACK;"
    psql(explain)                       # warm-up run (results discarded)
    plan = psql(explain).replace("BEGIN", "").replace("ROLLBACK", "").strip()
    header = (
        f"-- {qid}: {desc}\n-- Type: {kind}\n"
        f"-- Database: {DB} (PostgreSQL {version}); data: {counts}\n"
        f"-- Command: EXPLAIN (ANALYZE, BUFFERS) -- warm run"
        f"{'; WRITE query run inside BEGIN ... ROLLBACK (no data changed)' if kind == 'WRITE' else ''}\n\n"
        f"EXPLAIN (ANALYZE, BUFFERS)\n{sql};\n\n"
        f"-- ---------------------------- QUERY PLAN ----------------------------\n"
    )
    with open(os.path.join(OUT, f"{qid}.txt"), "w", encoding="utf-8") as f:
        f.write(header + plan + "\n")
    print("wrote", f"{qid}.txt")
print(f"done: {len(blocks)} plan files in {OUT}")

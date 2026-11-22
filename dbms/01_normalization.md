# CP1 · Normalization of the FindBack Campus Lost & Found Database

This document normalizes the **FindBack** campus lost-and-found application database step-by-step:
**UNF → 1NF → 2NF → 3NF → BCNF**, arriving at the 9 normalized tables defined in `prisma/schema.prisma`: `User`, `Category`, `Location`, `NearbyLocation`, `ItemReport`, `Match`, `Claim`, `Verification`, and `Handover`.

Notation: `X → Y` means "`X` functionally determines `Y`". <u>Underlined</u> attributes represent Primary Keys.

---

## 0. Domain Requirements

- **Users**: Campus students and admins (`STUDENT`, `ADMIN`) with credentials and an email-verified flag.
- **Categories & Locations**: Standardized lookup tables for item categories (Phone, Charger, Macbook, Wallet, ID Card, etc.) and campus locations (A Block, B Block, C Block, R1–R4, Learners Arena, Pushpa Devi Mess, Chai Adda, etc.).
- **Nearby Locations**: Pairs of campus locations confirmed to be close to each other. The matching engine uses them to give partial location credit, checking each pair in both directions.
- **Item Reports**: Lost (`LOST`) or Found (`FOUND`) reports posted by users, capturing title, description, color, event date, image URL, specific category/location details, and `privateDetails` (identifying information visible only to the owner and admins).
- **Matches**: Pairings between a `LOST` report and a `FOUND` report, generated automatically by the matching engine, with a similarity `score` (0–100, minimum 50 to be stored) and a status (`PENDING`, `CONFIRMED`, `DISMISSED`, `INVALIDATED`).
- **Claims**: Requests submitted by a user to claim a `FOUND` item report (optionally linked to a `Match`).
- **Verifications**: Ownership challenge questions (`question`, `expectedAnswerHash`, `submittedAnswerHash`) reviewed by a user/admin to validate a claim.
- **Handovers**: Final physical transfer record linking an approved claim, the sender (`handedOverById`), and the recipient (`receivedById`).

---

## 1. Unnormalized Form (UNF)

If the entire campus lost-and-found log were stored in a single flat spreadsheet per item report, a row would contain repeating groups for nearby locations, matches, claims, and verification questions:

| Column | Example Value |
|---|---|
| `report_id`, `type`, `title`, `color`, `eventDate`, `status`, `privateDetails` | `rep-101`, `FOUND`, `Black Dell Charger`, `Black`, `2026-11-10 14:30`, `ACTIVE`, `Scratch on the plug` |
| `reporter_id`, `reporter_name`, `reporter_email`, `reporter_role` | `usr-01`, `Tanmay Dave`, `tanmay@nst.edu`, `STUDENT` |
| `category_id`, `category_name`, `categoryDetails` | `cat-02`, `Charger`, `65W USB-C` |
| `location_id`, `location_name`, `location_desc`, `locationDetails` | `loc-08`, `LA (Learners Arena)`, `Main study hall`, `2nd floor near table 4` |
| **`nearbyLocations`** *(multi-valued repeating group)* | `[loc-02, loc-05, loc-09]` |
| **`matches`** *(multi-valued repeating group)* | `[{match_id: m-1, lostReportId: rep-088, score: 89, status: CONFIRMED}]` |
| **`claims`** *(multi-valued repeating group)* | `[{claim_id: clm-5, claimant_id: usr-02, claimant_name: Yashraj, message: "Lost near LA", status: APPROVED, handover_id: ho-1, handedOverBy: usr-01, receivedBy: usr-02}]` |
| **`verifications`** *(nested repeating group inside claims)* | `[{ver_id: v-9, question: "Sticker on adapter?", status: VERIFIED, verifiedBy: usr-09}]` |

### Anomalies in UNF
1. **Repeating Groups:** A single found item can generate multiple potential `matches`, multiple competing `claims`, and multiple `verifications` per claim; a location can have several nearby locations.
2. **Update Anomaly:** Updating a student's name or email requires modifying every item report, claim, verification, and handover row they appear in.
3. **Insertion Anomaly:** New campus locations (e.g., `Chai Adda`) or item categories (e.g., `Macbook`) cannot be registered until an item is actually lost or found there.
4. **Deletion Anomaly:** Deleting a resolved or duplicate `ItemReport` would erase user profile details, category definitions, and campus location records.

---

## 2. First Normal Form (1NF)

**Rule:** All attributes must contain atomic (indivisible) values, every row must be uniquely identifiable by a primary key, and repeating groups must be separated into distinct relations.

We flatten the repeating groups (`nearbyLocations`, `matches`, `claims`, `verifications`) into separate tables:

- **ItemReport_1NF**(<u>id</u>, userId, reporterName, reporterEmail, reporterPasswordHash, reporterRole, emailVerified, categoryId, categoryName, categoryCreatedAt, locationId, locationName, locationDescription, categoryDetails, locationDetails, type, title, description, privateDetails, color, eventDate, imageUrl, status, createdAt, updatedAt)
- **NearbyLocation_1NF**(<u>locationId</u>, <u>nearbyLocationId</u>)
- **Match_1NF**(<u>id</u>, lostReportId, foundReportId, score, status, createdAt, updatedAt)
- **Claim_1NF**(<u>id</u>, foundReportId, matchId, userId, claimantName, claimantEmail, message, status, createdAt, updatedAt, handoverId, handedOverById, receivedById, handedOverAt, handoverNotes)
- **Verification_1NF**(<u>id</u>, claimId, verifiedById, reviewerName, question, expectedAnswerHash, submittedAnswerHash, status, verifiedAt, createdAt)

All attributes are now atomic, eliminating nested arrays/repeating groups.

---

## 3. Second Normal Form (2NF)

**Rule:** The schema must be in 1NF, and every non-prime attribute must be fully functionally dependent on the entire primary key (no partial dependencies on composite keys).

- Eight of the nine entities use a single-column surrogate UUID primary key (`id`), so a partial dependency is impossible. Natural composite keys on these tables are enforced via `UNIQUE` constraints. In `Match`, the natural candidate key is `(lostReportId, foundReportId)`. Both `score` and `status` depend on the **entire pair** (a match score only exists for a specific lost-and-found pair, not for `lostReportId` or `foundReportId` alone).
- `NearbyLocation` is the only table with a composite primary key, `(locationId, nearbyLocationId)`. It has **no non-key attributes**, so no attribute can depend on part of the key, and the table is trivially in 2NF.

All relations satisfy **2NF**.

---

## 4. Third Normal Form (3NF)

**Rule:** The schema must be in 2NF, and there must be no transitive dependencies (`PK → X → Y` where `X` is a non-key attribute).

Inspecting the 1NF/2NF relations reveals several transitive dependencies:

1. **In `ItemReport_1NF`:**
   - `id → userId → {name, email, passwordHash, role, emailVerified, createdAt, updatedAt}`
   - `id → categoryId → {name, createdAt}`
   - `id → locationId → {name, description}`
2. **In `Claim_1NF`:**
   - `id → userId → {claimantName, claimantEmail}`
   - `id → handoverId → {handedOverById, receivedById, handedOverAt, handoverNotes}` (1:1 handover event linked to an approved claim)
3. **In `Verification_1NF`:**
   - `id → verifiedById → {reviewerName}`

### Decomposition into 3NF
We extract each transitively dependent group into its own relation, leaving only foreign keys in the referencing tables:

1. **User**(<u>id</u>, name, email, passwordHash, role, emailVerified, createdAt, updatedAt)
2. **Category**(<u>id</u>, name, createdAt)
3. **Location**(<u>id</u>, name, description)
4. **NearbyLocation**(<u>locationId</u>, <u>nearbyLocationId</u>), both columns are foreign keys to `Location`
5. **ItemReport**(<u>id</u>, userId, categoryId, locationId, categoryDetails, locationDetails, type, title, description, privateDetails, color, eventDate, imageUrl, status, createdAt, updatedAt)
6. **Match**(<u>id</u>, lostReportId, foundReportId, score, status, createdAt, updatedAt)
7. **Claim**(<u>id</u>, userId, foundReportId, matchId, message, status, createdAt, updatedAt)
8. **Verification**(<u>id</u>, claimId, verifiedById, question, expectedAnswerHash, submittedAnswerHash, status, verifiedAt, createdAt)
9. **Handover**(<u>id</u>, claimId, handedOverById, receivedById, handedOverAt, notes)

No non-key attribute determines another non-key attribute in any of the 9 tables. All 9 tables are in **3NF**.

---

## 5. Boyce–Codd Normal Form (BCNF)

**Rule:** For every non-trivial functional dependency `X → Y`, `X` must be a superkey (either the primary key or an alternate candidate key).

| Table | Candidate Keys | Non-Trivial Functional Dependencies | BCNF? |
|---|---|---|---|
| `User` | `id`, `email` | `id → all`, `email → all` | ✔ |
| `Category` | `id`, `name` | `id → all`, `name → all` | ✔ |
| `Location` | `id`, `name` | `id → all`, `name → all` | ✔ |
| `NearbyLocation` | `(locationId, nearbyLocationId)` | none (all-key relation) | ✔ |
| `ItemReport` | `id` | `id → all` | ✔ |
| `Match` | `id`, `(lostReportId, foundReportId)` | `id → all`, `(lostReportId, foundReportId) → all` | ✔ |
| `Claim` | `id` | `id → all` | ✔ |
| `Verification` | `id` | `id → all` | ✔ |
| `Handover` | `id`, `claimId` | `id → all`, `claimId → all` | ✔ |

Every determinant in every table is a candidate key. Therefore, **all 9 tables are strictly in BCNF**.
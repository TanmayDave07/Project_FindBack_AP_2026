-- ============================================================================
-- FindBack Campus Lost & Found Application Queries (PostgreSQL)
-- Checkpoint 3 (CP3) · AP Repository
-- ============================================================================

-- ============================================================================
-- 1. USER & AUTHENTICATION QUERIES
-- ============================================================================

-- WRITE
-- Q01: Register a new campus user (Student or Admin)
INSERT INTO "User" ("name", "email", "passwordHash", "role")
VALUES ('Yashraj Panghal', 'yashraj@nst.edu', '$2b$10$hashedpasswordexample', 'STUDENT')
RETURNING "id", "name", "email", "role", "emailVerified", "createdAt";

-- READ
-- Q02: Fetch user credentials and profile by email for login
SELECT "id", "name", "email", "passwordHash", "role", "emailVerified"
FROM "User"
WHERE "email" = 'yashraj@nst.edu';

-- WRITE
-- Q03: Mark a user's email as verified
UPDATE "User"
SET "emailVerified" = true,
    "updatedAt" = CURRENT_TIMESTAMP
WHERE "id" = 'user-uuid-here'
RETURNING "id", "email", "emailVerified";

-- ============================================================================
-- 2. CATEGORIES & CAMPUS LOCATIONS (LOOKUP DATA)
-- ============================================================================

-- READ
-- Q04: Fetch all item categories with count of active lost and found reports
SELECT
    c."id",
    c."name",
    COUNT(ir."id") FILTER (WHERE ir."type" = 'LOST' AND ir."status" = 'ACTIVE') AS "activeLostCount",
    COUNT(ir."id") FILTER (WHERE ir."type" = 'FOUND' AND ir."status" = 'ACTIVE') AS "activeFoundCount"
FROM "Category" c
LEFT JOIN "ItemReport" ir ON ir."categoryId" = c."id"
GROUP BY c."id", c."name"
ORDER BY c."name" ASC;

-- READ
-- Q05: Fetch all campus locations ordered alphabetically
SELECT "id", "name", "description"
FROM "Location"
ORDER BY "name" ASC;

-- ============================================================================
-- 3. ITEM REPORTS (POSTING, BROWSING, FILTERING & UPDATING)
-- ============================================================================

-- WRITE
-- Q06: Create a new LOST or FOUND item report
INSERT INTO "ItemReport" (
    "userId", "categoryId", "locationId", "categoryDetails", "locationDetails",
    "type", "title", "description", "color", "eventDate", "imageUrl"
)
VALUES (
    'user-uuid-here',
    'category-uuid-here',
    'location-uuid-here',
    '65W USB-C MacBook Charger',
    '2nd Floor, Table 4 near window',
    'FOUND',
    'White Apple USB-C Charger',
    'Found a 65W white USB-C charger with a braided cable left plugged in.',
    'White',
    '2026-11-18 14:30:00',
    'https://cdn.findback.app/items/charger-01.jpg'
)
RETURNING *;

-- READ
-- Q07: Browse active item reports feed with reporter, category, and location details
SELECT
    ir."id",
    ir."type",
    ir."title",
    ir."description",
    ir."color",
    ir."categoryDetails",
    ir."locationDetails",
    ir."eventDate",
    ir."imageUrl",
    ir."status",
    ir."createdAt",
    u."id" AS "reporterId",
    u."name" AS "reporterName",
    c."name" AS "categoryName",
    l."name" AS "locationName"
FROM "ItemReport" ir
JOIN "User" u ON u."id" = ir."userId"
JOIN "Category" c ON c."id" = ir."categoryId"
JOIN "Location" l ON l."id" = ir."locationId"
WHERE ir."status" = 'ACTIVE'
  AND ir."type" = 'FOUND'
ORDER BY ir."createdAt" DESC
LIMIT 20 OFFSET 0;

-- READ
-- Q08: Search and filter item reports by type, category, location, date range, and keyword
SELECT
    ir."id",
    ir."type",
    ir."title",
    ir."description",
    ir."color",
    ir."eventDate",
    ir."status",
    c."name" AS "categoryName",
    l."name" AS "locationName",
    u."name" AS "reporterName"
FROM "ItemReport" ir
JOIN "Category" c ON c."id" = ir."categoryId"
JOIN "Location" l ON l."id" = ir."locationId"
JOIN "User" u ON u."id" = ir."userId"
WHERE ir."type" = 'LOST'
  AND ir."status" IN ('ACTIVE', 'MATCHED')
  AND ir."categoryId" = 'category-uuid-here'
  AND ir."locationId" = 'location-uuid-here'
  AND ir."eventDate" >= '2026-11-01 00:00:00'
  AND (ir."title" ILIKE '%charger%' OR ir."description" ILIKE '%charger%')
ORDER BY ir."eventDate" DESC;

-- READ
-- Q09: Get full details of a single item report along with claim count
SELECT
    ir.*,
    u."name" AS "reporterName",
    u."email" AS "reporterEmail",
    c."name" AS "categoryName",
    l."name" AS "locationName",
    l."description" AS "locationDescription",
    COUNT(cl."id") AS "totalClaims"
FROM "ItemReport" ir
JOIN "User" u ON u."id" = ir."userId"
JOIN "Category" c ON c."id" = ir."categoryId"
JOIN "Location" l ON l."id" = ir."locationId"
LEFT JOIN "Claim" cl ON cl."foundReportId" = ir."id"
WHERE ir."id" = 'report-uuid-here'
GROUP BY ir."id", u."id", c."id", l."id";

-- READ
-- Q10: Fetch all reports posted by a specific user (My Reports dashboard)
SELECT
    ir."id",
    ir."type",
    ir."title",
    ir."status",
    ir."eventDate",
    ir."createdAt",
    c."name" AS "categoryName",
    l."name" AS "locationName",
    COUNT(DISTINCT m."id") AS "matchCount",
    COUNT(DISTINCT cl."id") AS "claimCount"
FROM "ItemReport" ir
JOIN "Category" c ON c."id" = ir."categoryId"
JOIN "Location" l ON l."id" = ir."locationId"
LEFT JOIN "Match" m ON m."lostReportId" = ir."id" OR m."foundReportId" = ir."id"
LEFT JOIN "Claim" cl ON cl."foundReportId" = ir."id"
WHERE ir."userId" = 'user-uuid-here'
GROUP BY ir."id", c."name", l."name"
ORDER BY ir."createdAt" DESC;

-- WRITE
-- Q11: Update report status (e.g., ACTIVE -> MATCHED -> RESOLVED or CLOSED)
UPDATE "ItemReport"
SET "status" = 'MATCHED',
    "updatedAt" = CURRENT_TIMESTAMP
WHERE "id" = 'report-uuid-here'
RETURNING "id", "title", "status", "updatedAt";

-- ============================================================================
-- 4. AUTOMATED & MANUAL MATCHING QUERIES
-- ============================================================================

-- READ
-- Q12: Find candidate FOUND reports matching a newly submitted LOST report
SELECT
    f."id" AS "foundReportId",
    f."title",
    f."description",
    f."color",
    f."eventDate",
    f."locationDetails",
    c."name" AS "categoryName",
    l."name" AS "locationName",
    u."name" AS "finderName"
FROM "ItemReport" f
JOIN "Category" c ON c."id" = f."categoryId"
JOIN "Location" l ON l."id" = f."locationId"
JOIN "User" u ON u."id" = f."userId"
WHERE f."type" = 'FOUND'
  AND f."status" = 'ACTIVE'
  AND f."categoryId" = 'category-uuid-here'
  AND f."eventDate" >= '2026-11-15 00:00:00'
ORDER BY (f."locationId" = 'location-uuid-here') DESC, f."eventDate" DESC;

-- WRITE
-- Q13: Insert or update a similarity match score between a LOST and FOUND report
INSERT INTO "Match" ("lostReportId", "foundReportId", "score", "status")
VALUES ('lost-report-uuid', 'found-report-uuid', 0.87, 'PENDING')
ON CONFLICT ("lostReportId", "foundReportId")
DO UPDATE SET
    "score" = EXCLUDED."score",
    "updatedAt" = CURRENT_TIMESTAMP
RETURNING *;

-- READ
-- Q14: Get ranked matches for a specific LOST report with full FOUND item details
SELECT
    m."id" AS "matchId",
    m."score",
    m."status" AS "matchStatus",
    m."createdAt" AS "matchedAt",
    fr."id" AS "foundReportId",
    fr."title" AS "foundTitle",
    fr."description" AS "foundDescription",
    fr."color" AS "foundColor",
    fr."eventDate" AS "foundDate",
    fr."imageUrl" AS "foundImageUrl",
    l."name" AS "foundLocation",
    u."name" AS "finderName"
FROM "Match" m
JOIN "ItemReport" fr ON fr."id" = m."foundReportId"
JOIN "Location" l ON l."id" = fr."locationId"
JOIN "User" u ON u."id" = fr."userId"
WHERE m."lostReportId" = 'lost-report-uuid'
  AND m."status" <> 'DISMISSED'
ORDER BY m."score" DESC;

-- WRITE
-- Q15: Confirm or dismiss a proposed match
UPDATE "Match"
SET "status" = 'CONFIRMED',
    "updatedAt" = CURRENT_TIMESTAMP
WHERE "id" = 'match-uuid-here'
RETURNING "id", "lostReportId", "foundReportId", "status";

-- ============================================================================
-- 5. CLAIMS & OWNERSHIP VERIFICATION QUERIES
-- ============================================================================

-- WRITE
-- Q16: Submit an ownership claim on a FOUND item report
INSERT INTO "Claim" ("userId", "foundReportId", "matchId", "message", "status")
VALUES (
    'claimant-user-uuid',
    'found-report-uuid',
    'match-uuid-here',
    'This is my charger; it has a small blue tape mark near the USB-C tip.',
    'PENDING'
)
RETURNING *;

-- READ
-- Q17: List all claims submitted on a specific FOUND item report (for finder/admin review)
SELECT
    cl."id" AS "claimId",
    cl."message",
    cl."status" AS "claimStatus",
    cl."createdAt",
    u."id" AS "claimantId",
    u."name" AS "claimantName",
    u."email" AS "claimantEmail",
    m."score" AS "matchScore",
    v."status" AS "verificationStatus"
FROM "Claim" cl
JOIN "User" u ON u."id" = cl."userId"
LEFT JOIN "Match" m ON m."id" = cl."matchId"
LEFT JOIN "Verification" v ON v."claimId" = cl."id"
WHERE cl."foundReportId" = 'found-report-uuid'
ORDER BY cl."createdAt" ASC;

-- READ
-- Q18: List all claims submitted by a user (My Claims dashboard)
SELECT
    cl."id" AS "claimId",
    cl."message",
    cl."status" AS "claimStatus",
    cl."createdAt",
    ir."id" AS "foundReportId",
    ir."title" AS "itemTitle",
    ir."imageUrl",
    l."name" AS "locationName",
    finder."name" AS "finderName"
FROM "Claim" cl
JOIN "ItemReport" ir ON ir."id" = cl."foundReportId"
JOIN "Location" l ON l."id" = ir."locationId"
JOIN "User" finder ON finder."id" = ir."userId"
WHERE cl."userId" = 'claimant-user-uuid'
ORDER BY cl."createdAt" DESC;

-- WRITE
-- Q19: Create a security/ownership verification question for a claim
INSERT INTO "Verification" ("claimId", "question", "expectedAnswerHash", "status")
VALUES (
    'claim-uuid-here',
    'What sticker or mark is on the bottom of the adapter?',
    '$2b$10$expectedanswerhash',
    'PENDING'
)
RETURNING "id", "claimId", "question", "status", "createdAt";

-- WRITE
-- Q20: Submit claimant's answer hash and update verification result
UPDATE "Verification"
SET "submittedAnswerHash" = '$2b$10$submittedanswerhash',
    "verifiedById" = 'reviewer-user-uuid',
    "status" = 'VERIFIED',
    "verifiedAt" = CURRENT_TIMESTAMP
WHERE "id" = 'verification-uuid-here'
RETURNING "id", "claimId", "status", "verifiedAt";

-- WRITE
-- Q21: Approve or reject a claim after verification
UPDATE "Claim"
SET "status" = 'APPROVED',
    "updatedAt" = CURRENT_TIMESTAMP
WHERE "id" = 'claim-uuid-here'
RETURNING "id", "userId", "foundReportId", "status";

-- ============================================================================
-- 6. PHYSICAL ITEM HANDOVER & RESOLUTION QUERIES
-- ============================================================================

-- WRITE
-- Q22: Record final physical handover of a claimed item
INSERT INTO "Handover" ("claimId", "handedOverById", "receivedById", "notes")
VALUES (
    'claim-uuid-here',
    'finder-user-uuid',
    'claimant-user-uuid',
    'Handed over at Learners Arena reception after ID verification.'
)
RETURNING *;

-- READ
-- Q23: Retrieve full handover audit trail (item, claim, finder, and receiver details)
SELECT
    h."id" AS "handoverId",
    h."handedOverAt",
    h."notes",
    cl."id" AS "claimId",
    ir."id" AS "reportId",
    ir."title" AS "itemTitle",
    c."name" AS "categoryName",
    l."name" AS "locationName",
    sender."name" AS "handedOverByName",
    sender."email" AS "handedOverByEmail",
    receiver."name" AS "receivedByName",
    receiver."email" AS "receivedByEmail"
FROM "Handover" h
JOIN "Claim" cl ON cl."id" = h."claimId"
JOIN "ItemReport" ir ON ir."id" = cl."foundReportId"
JOIN "Category" c ON c."id" = ir."categoryId"
JOIN "Location" l ON l."id" = ir."locationId"
JOIN "User" sender ON sender."id" = h."handedOverById"
JOIN "User" receiver ON receiver."id" = h."receivedById"
WHERE h."claimId" = 'claim-uuid-here';

-- ============================================================================
-- 7. ADMIN ANALYTICS & SUMMARY QUERIES
-- ============================================================================

-- READ
-- Q24: Campus lost-and-found recovery statistics grouped by location
SELECT
    l."name" AS "locationName",
    COUNT(ir."id") FILTER (WHERE ir."type" = 'LOST') AS "totalLost",
    COUNT(ir."id") FILTER (WHERE ir."type" = 'FOUND') AS "totalFound",
    COUNT(ir."id") FILTER (WHERE ir."status" = 'RESOLVED') AS "totalResolved"
FROM "Location" l
LEFT JOIN "ItemReport" ir ON ir."locationId" = l."id"
GROUP BY l."id", l."name"
ORDER BY "totalLost" DESC, "totalFound" DESC;
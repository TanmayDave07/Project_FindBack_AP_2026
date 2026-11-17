-- ============================================================================
-- FindBack Campus Lost & Found Database Schema (PostgreSQL)
-- Checkpoint 2 (CP2) · AP Repository
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. ENUMS
-- ============================================================================

CREATE TYPE "UserRole" AS ENUM ('STUDENT', 'ADMIN');
CREATE TYPE "ItemType" AS ENUM ('LOST', 'FOUND');
CREATE TYPE "ReportStatus" AS ENUM ('ACTIVE', 'MATCHED', 'RESOLVED', 'CLOSED');
CREATE TYPE "MatchStatus" AS ENUM ('PENDING', 'CONFIRMED', 'DISMISSED');
CREATE TYPE "ClaimStatus" AS ENUM ('PENDING', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'COMPLETED');
CREATE TYPE "VerificationStatus" AS ENUM ('PENDING', 'VERIFIED', 'FAILED');

-- ============================================================================
-- 2. TABLES
-- ============================================================================

CREATE TABLE "User" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid()::TEXT,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" "UserRole" NOT NULL DEFAULT 'STUDENT',
    "emailVerified" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "User_email_key" UNIQUE ("email")
);

CREATE TABLE "Category" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid()::TEXT,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Category_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Category_name_key" UNIQUE ("name")
);

CREATE TABLE "Location" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid()::TEXT,
    "name" TEXT NOT NULL,
    "description" TEXT,

    CONSTRAINT "Location_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Location_name_key" UNIQUE ("name")
);

CREATE TABLE "ItemReport" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid()::TEXT,
    "userId" TEXT NOT NULL,
    "categoryId" TEXT NOT NULL,
    "locationId" TEXT NOT NULL,
    "categoryDetails" TEXT,
    "locationDetails" TEXT,
    "type" "ItemType" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "color" TEXT,
    "eventDate" TIMESTAMP(3) NOT NULL,
    "imageUrl" TEXT,
    "status" "ReportStatus" NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ItemReport_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "ItemReport_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "ItemReport_categoryId_fkey"
        FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "ItemReport_locationId_fkey"
        FOREIGN KEY ("locationId") REFERENCES "Location"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE "Match" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid()::TEXT,
    "lostReportId" TEXT NOT NULL,
    "foundReportId" TEXT NOT NULL,
    "score" DOUBLE PRECISION NOT NULL,
    "status" "MatchStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Match_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Match_lostReportId_foundReportId_key" UNIQUE ("lostReportId", "foundReportId"),
    CONSTRAINT "Match_distinct_reports_check" CHECK ("lostReportId" <> "foundReportId"),
    CONSTRAINT "Match_score_range_check" CHECK ("score" >= 0.0 AND "score" <= 1.0),
    CONSTRAINT "Match_lostReportId_fkey"
        FOREIGN KEY ("lostReportId") REFERENCES "ItemReport"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Match_foundReportId_fkey"
        FOREIGN KEY ("foundReportId") REFERENCES "ItemReport"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE "Claim" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid()::TEXT,
    "userId" TEXT NOT NULL,
    "foundReportId" TEXT NOT NULL,
    "matchId" TEXT,
    "message" TEXT NOT NULL,
    "status" "ClaimStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Claim_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Claim_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Claim_foundReportId_fkey"
        FOREIGN KEY ("foundReportId") REFERENCES "ItemReport"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Claim_matchId_fkey"
        FOREIGN KEY ("matchId") REFERENCES "Match"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE "Verification" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid()::TEXT,
    "claimId" TEXT NOT NULL,
    "verifiedById" TEXT,
    "question" TEXT NOT NULL,
    "expectedAnswerHash" TEXT NOT NULL,
    "submittedAnswerHash" TEXT,
    "status" "VerificationStatus" NOT NULL DEFAULT 'PENDING',
    "verifiedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Verification_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Verification_claimId_fkey"
        FOREIGN KEY ("claimId") REFERENCES "Claim"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Verification_verifiedById_fkey"
        FOREIGN KEY ("verifiedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE "Handover" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid()::TEXT,
    "claimId" TEXT NOT NULL,
    "handedOverById" TEXT NOT NULL,
    "receivedById" TEXT NOT NULL,
    "handedOverAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "notes" TEXT,

    CONSTRAINT "Handover_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Handover_claimId_key" UNIQUE ("claimId"),
    CONSTRAINT "Handover_distinct_users_check" CHECK ("handedOverById" <> "receivedById"),
    CONSTRAINT "Handover_claimId_fkey"
        FOREIGN KEY ("claimId") REFERENCES "Claim"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Handover_handedOverById_fkey"
        FOREIGN KEY ("handedOverById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Handover_receivedById_fkey"
        FOREIGN KEY ("receivedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ============================================================================
-- 3. INDEXES
-- ============================================================================

CREATE INDEX "ItemReport_type_status_idx" ON "ItemReport"("type", "status");
CREATE INDEX "ItemReport_categoryId_type_idx" ON "ItemReport"("categoryId", "type");
CREATE INDEX "ItemReport_locationId_type_idx" ON "ItemReport"("locationId", "type");
CREATE INDEX "ItemReport_eventDate_idx" ON "ItemReport"("eventDate");
CREATE INDEX "ItemReport_userId_createdAt_idx" ON "ItemReport"("userId", "createdAt");

CREATE INDEX "Match_lostReportId_score_idx" ON "Match"("lostReportId", "score");
CREATE INDEX "Match_foundReportId_idx" ON "Match"("foundReportId");

CREATE INDEX "Claim_foundReportId_status_idx" ON "Claim"("foundReportId", "status");
CREATE INDEX "Claim_userId_idx" ON "Claim"("userId");

CREATE INDEX "Verification_claimId_idx" ON "Verification"("claimId") ;
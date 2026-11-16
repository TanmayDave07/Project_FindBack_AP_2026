# FindBack — Campus Lost & Found Platform

Campus lost-and-found processes are often informal, relying on WhatsApp groups, notice boards, or word of mouth. As a result, lost items are difficult to track, found items may not reach their owners, and there is no systematic way to determine whether a reported lost item matches a found item.

**FindBack** provides a centralized campus platform where students and staff can report lost or found items with details such as category, description, location, time, and images. The backend automatically identifies and ranks potential matches using factors such as item category, location, time, and description similarity, while enforcing a structured claim, verification, and physical handover workflow.

---

## Team T0068 · Section E
- Yashraj Panghal (`yashrajhuntmi7`)
- Tanmay Dave (`TanmayDave07`)
- Ajay Kumar (`AjayKumar026`)
- Harsh Tomar (`HarshNST`)

---

## DBMS Checkpoints (`dbms/`)
- **`dbms/01_normalization.md`** — Step-by-step schema normalization (`UNF → 1NF → 2NF → 3NF → BCNF`) for FindBack's 8 core entities (`User`, `Category`, `Location`, `ItemReport`, `Match`, `Claim`, `Verification`, `Handover`).
- **`dbms/02_er_diagram.png`** — Entity-Relationship diagram illustrating tables, primary/foreign keys, unique constraints, and cardinalities across the report-to-handover lifecycle.
- **`dbms/03_schema.sql`** — Executable PostgreSQL DDL script with enums, tables, foreign keys, `CHECK` constraints, and indexes.
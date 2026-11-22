FindBack – SQL Query Performance Benchmarking

Checkpoint 3 (CP3) · AP Repository

1. Objective

The objective of this checkpoint is to evaluate PostgreSQL database query performance using:

sql
EXPLAIN (ANALYZE, BUFFERS)


Each query is executed three times to observe execution-time variation and establish a performance baseline.

The following performance metrics are recorded:

Planning Time (ms)
Execution Time (ms)
Average Execution Time (ms)
Buffer usage, where available
2. Benchmark Environment
Parameter	Value
Project	FindBack – Campus Lost & Found Platform
Team	T0068
Section	E
Checkpoint	CP3
Database	findback_db
DBMS	PostgreSQL
PostgreSQL Server	16.16 (Homebrew)
PostgreSQL Client	18.6 (Postgres.app)
Operating System	macOS
Database User	ajaykumar
Benchmark Runs	3 per query
Measurement Tool	EXPLAIN (ANALYZE, BUFFERS)
Measurement Unit	Milliseconds (ms)
3. Query Performance Results

All execution times are measured in milliseconds.

3.1 Q01–Q06: User and Database Operations
Query	Description	Run 1	Run 2	Run 3	Average
Q01	User Registration	0.407	0.130	0.127	0.221
Q02	User Login Lookup	0.028	0.051	0.047	0.042
Q03	Database Operation 03	0.617	0.077	0.074	0.256
Q04	Database Operation 04	0.855	0.133	0.069	0.352
Q05	Database Operation 05	0.041	0.044	0.048	0.044
Q06	Database Operation 06	0.238	0.243	0.441	0.307

Note: The original descriptions for Q03–Q06 were not available in the supplied records.

3.2 Q07–Q12: Report and Matching Operations
Q07 – Browse Active FOUND Reports
Run	Execution Time
1	0.304 ms
2	0.066 ms
3	0.113 ms
Average	0.161 ms
Q08 – Search and Filter Item Reports
Run	Planning Time	Execution Time
1	0.340	0.094
2	0.386	0.116
3	0.302	0.103
Average	0.343	0.104
Q09 – Single Item Report Details
Run	Planning Time	Execution Time
1	0.498	0.175
2	0.317	0.209
3	0.489	0.146
Average	0.435	0.177

Rows returned: 36.

Q10 – My Reports Dashboard
Run	Planning Time	Execution Time
1	1.146	0.202
2	0.436	0.170
3	0.583	0.219
Average	0.722	0.197
Q11 – Update Report Status
Run	Planning Time	Execution Time
1	0.135	0.216
2	0.121	0.115
3	Not recorded	0.199
Additional run	Not recorded	0.196

Average execution time using the first three runs: 0.177 ms.

Note: Four execution times were supplied. The first three are used for the reported average.

Q12 – Find Candidate FOUND Reports
Run	Planning Time	Execution Time
1	0.226	0.094
2	0.330	0.145
3	0.378	0.128
Average	0.311	0.122
3.3 Q13–Q17: Similarity Matching, Claims and Verification
Q13 – Insert or Update Similarity Match
Run	Planning Time	Execution Time
1	0.072	0.295
2	0.082	0.194
3	0.043	0.109
Average	0.066	0.199

The query uses PostgreSQL's INSERT ... ON CONFLICT DO UPDATE operation to insert a new similarity match or update an existing match.

Q14 – Find Pending Claims for Admin Review
Run	Planning Time	Execution Time
1	0.817	0.137
2	0.429	0.142
3	0.373	0.141
Average	0.540	0.140

This query retrieves pending claims for administrator review by joining the Claim, User, ItemReport and Verification tables.

Q15 – View Claims Submitted by a User
Run	Planning Time	Execution Time
1	0.277	0.121
2	0.327	0.119
3	0.335	0.121
Average	0.313	0.120

This query retrieves claims submitted by a particular user by joining Claim, ItemReport and Match tables.

Q16 – View Confirmed Matches
Run	Planning Time	Execution Time
1	0.821	0.117
2	0.639	0.094
3	0.422	0.080
Average	0.627	0.097

This query retrieves confirmed matches by joining Match with ItemReport and User tables to display lost and found item information and reporter details.

Q17 – View Verification Details
Run	Planning Time	Execution Time
1	0.261	0.110
2	0.231	0.120
3	0.367	0.167
Average	0.286	0.132

This query retrieves pending verification records along with claim and claimant information by joining Verification, Claim and User tables.

3.4 Q18–Q28: Handover, Claims and Report Operations
Query	Description	Run 1	Run 2	Run 3	Average
Q18	View Completed Handovers	0.140	0.109	0.119	0.123
Q19	Count Reports by Category	0.161	0.093	0.114	0.123
Q20	Count Reports by Location	0.152	0.073	0.126	0.117
Q21	Count Reports by Status	0.045	0.068	0.095	0.069
Q22	Count Claims by Status	0.093	0.041	0.067	0.067
Q23	Count Verifications by Status	0.074	0.063	0.054	0.064
Q24	Count Total Handovers	0.050	0.031	0.040	0.040
Q25	View Handover History	0.193	0.128	0.089	0.137
Q26	Find Claims for a Specific Found Item	0.234	0.110	0.049	0.131
Q27	Find Lost Items by Category	0.114	0.080	0.073	0.089
Q28	Find Found Items by Location	0.168	0.168	0.129	0.155
3.5 Q29–Q40: Advanced Search and Reporting Operations
Q29 – Find Reports Within a Date Range
Run	Planning Time	Execution Time
1	0.327	0.103
2	0.324	0.108
3	0.289	0.097
Average	0.313	0.103
Q30 – Search Items by Title
Run	Planning Time	Execution Time
1	0.270	0.102
2	0.270	0.132
3	0.239	0.105
Average	0.260	0.113

The query performs case-insensitive title searching using LOWER() and LIKE.

Q31 – Search Items by Description
Run	Planning Time	Execution Time
1	0.232	0.104
2	0.225	0.106
3	1.951	0.081
Average	0.803	0.097

The query searches item descriptions using case-insensitive matching.

Q32 – Search Items by Color
Run	Planning Time	Execution Time
1	0.327	0.206
2	0.302	0.177
3	0.202	0.086
Average	0.277	0.156

The query searches reports by color using case-insensitive matching.

Q33 – View Reports by User
Run	Planning Time	Execution Time
1	0.365	0.205
2	0.372	0.103
3	0.323	0.105
Average	0.353	0.138

The query retrieves reports submitted by a specific user and joins User, Category and Location.

Q34 – Find Reports by Item Type
Run	Planning Time	Execution Time
1	0.357	0.206
2	0.351	0.160
3	0.384	0.133
Average	0.364	0.166

The query retrieves LOST reports and joins User, Category and Location.

Q35 – Find Reports by Status
Run	Planning Time	Execution Time
1	0.493	0.200
2	0.327	0.127
3	0.216	0.077
Average	0.345	0.135

The query retrieves active reports with reporter, category and location details.

Q36 – Count Reports by User
Run	Planning Time	Execution Time
1	0.379	0.211
2	0.172	0.079
3	0.269	0.124
Average	0.273	0.138

The query counts total, LOST and FOUND reports for each user using LEFT JOIN, GROUP BY and filtered aggregate counts.

Q37 – Count Reports by Category and Type
Run	Planning Time	Execution Time
1	0.308	0.270
2	0.211	0.154
3	0.228	0.140
Average	0.249	0.188

The query groups reports by category and item type and calculates the total number of reports.

Q38 – Find Reports with Pending Matches
Run	Planning Time	Execution Time
1	0.337	0.167
2	0.342	0.132
3	0.500	0.209
Average	0.393	0.169

The query retrieves pending matches with their corresponding lost and found item details, ordered by matching score.

Q39 – View Claims with Verification Details
Run	Planning Time	Execution Time
1	0.318	0.273
2	0.300	0.140
3	0.413	0.155
Average	0.344	0.189

The query retrieves claim information with claimant, found-item and optional verification details using LEFT JOIN.

Q40 – Complete Lost and Found Report Summary
Run	Planning Time	Execution Time
1	0.178	0.097
2	0.158	0.093
3	0.123	0.058
Average	0.153	0.083

The query summarizes reports by item type and status, including unique reporters, categories and locations.

4. Consolidated Benchmark Summary

The following table presents the average execution time of all 40 queries.

Query	Description	Average Execution Time
Q01	User Registration	0.221 ms
Q02	User Login Lookup	0.042 ms
Q03	Database Operation 03	0.256 ms
Q04	Database Operation 04	0.352 ms
Q05	Database Operation 05	0.044 ms
Q06	Database Operation 06	0.307 ms
Q07	Browse Active FOUND Reports	0.161 ms
Q08	Search and Filter Item Reports	0.104 ms
Q09	Single Item Report Details	0.177 ms
Q10	My Reports Dashboard	0.197 ms
Q11	Update Report Status	0.177 ms
Q12	Find Candidate FOUND Reports	0.122 ms
Q13	Insert or Update Similarity Match	0.199 ms
Q14	Find Pending Claims for Admin Review	0.140 ms
Q15	View Claims Submitted by a User	0.120 ms
Q16	View Confirmed Matches	0.097 ms
Q17	View Verification Details	0.132 ms
Q18	View Completed Handovers	0.123 ms
Q19	Count Reports by Category	0.123 ms
Q20	Count Reports by Location	0.117 ms
Q21	Count Reports by Status	0.069 ms
Q22	Count Claims by Status	0.067 ms
Q23	Count Verifications by Status	0.064 ms
Q24	Count Total Handovers	0.040 ms
Q25	View Handover History	0.137 ms
Q26	Find Claims for a Specific Found Item	0.131 ms
Q27	Find Lost Items by Category	0.089 ms
Q28	Find Found Items by Location	0.155 ms
Q29	Find Reports Within a Date Range	0.103 ms
Q30	Search Items by Title	0.113 ms
Q31	Search Items by Description	0.097 ms
Q32	Search Items by Color	0.156 ms
Q33	View Reports by User	0.138 ms
Q34	Find Reports by Item Type	0.166 ms
Q35	Find Reports by Status	0.135 ms
Q36	Count Reports by User	0.138 ms
Q37	Count Reports by Category and Type	0.188 ms
Q38	Find Reports with Pending Matches	0.169 ms
Q39	View Claims with Verification Details	0.189 ms
Q40	Complete Lost and Found Report Summary	0.083 ms
5. Planning Time Summary

Average planning times are available for the following queries:

Query	Average Planning Time
Q08	0.343 ms
Q09	0.435 ms
Q10	0.722 ms
Q12	0.311 ms
Q13	0.066 ms
Q14	0.540 ms
Q15	0.313 ms
Q16	0.627 ms
Q17	0.286 ms
Q29	0.313 ms
Q30	0.260 ms
Q31	0.803 ms
Q32	0.277 ms
Q33	0.353 ms
Q34	0.364 ms
Q35	0.345 ms
Q36	0.273 ms
Q37	0.249 ms
Q38	0.393 ms
Q39	0.344 ms
Q40	0.153 ms

Note: Planning-time records for other queries were not fully available in the collected benchmark data.

6. Methodology

Each query is executed three times using PostgreSQL's EXPLAIN ANALYZE with BUFFERS enabled.

The standard benchmark command is:

sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ...;


Average execution time is calculated using:

text
Average Execution Time =
(Run 1 + Run 2 + Run 3) / 3


All measurements are recorded in milliseconds.

The same SQL query is executed three times to observe execution-time variation.

The following factors may affect the results:

PostgreSQL shared buffer cache.
Database size and number of records.
Index availability.
Query complexity and table joins.
System resources and background activity.
Transaction and constraint processing.
7. Performance Analysis

Based on the recorded benchmark results:

7.1 Fastest Queries

The queries with the lowest average execution times include:

Query	Description	Average
Q24	Count Total Handovers	0.040 ms
Q02	User Login Lookup	0.042 ms
Q05	Database Operation 05	0.044 ms
Q23	Count Verifications by Status	0.064 ms
Q22	Count Claims by Status	0.067 ms

These queries demonstrate low execution times in the current test database.

7.2 Higher Execution Times

The queries with comparatively higher average execution times include:

Query	Description	Average
Q04	Database Operation 04	0.352 ms
Q06	Database Operation 06	0.307 ms
Q03	Database Operation 03	0.256 ms
Q01	User Registration	0.221 ms
Q13	Insert or Update Similarity Match	0.199 ms

These results can be used as a starting point for further query optimization.

7.3 General Observations
Most recorded queries execute in less than 0.2 milliseconds on average.
Simple indexed lookups and aggregate queries show particularly low execution times.
Queries involving multiple joins and filtering operations have varying execution times.
The INSERT ... ON CONFLICT DO UPDATE operation in Q13 also performs efficiently in the current test environment.
Repeated executions show some variation, potentially because of caching and system activity.
Query performance should be evaluated again with larger datasets to understand scalability.

These results represent the current local development database and should not be interpreted as production-scale performance guarantees.

8. Conclusion

The FindBack PostgreSQL database has undergone a comprehensive SQL query performance benchmarking process as part of Checkpoint 3.

A total of 40 queries were benchmarked, with three execution runs recorded per query, giving 120 benchmark executions.

The benchmark covers the major database operations of the FindBack application, including:

User registration and authentication.
Lost and found item reporting.
Searching and filtering item reports.
Similarity matching.
Claims and verification management.
Handover operations.
Category and location reporting.
User-based report statistics.
Administrative reporting and aggregation.

The collected execution times provide a performance baseline for the FindBack application.

The benchmark indicates that the tested queries perform efficiently on the current local database. Further optimization and testing with larger datasets can help evaluate database scalability and performance under higher workloads.

Project Information
Field	Details
Project	FindBack – Campus Lost & Found Platform
Team	T0068
Section	E
Checkpoint	CP3
Database	findback_db
DBMS	PostgreSQL
Total Queries	40
Total Benchmark Runs	120
Benchmark Tool	EXPLAIN (ANALYZE, BUFFERS)
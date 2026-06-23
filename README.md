# NYC Illegal Parking — Squeeze Index

**A dimensional data warehouse + analytics layer over NYC 311 curb complaints and MTA Automated Camera Enforcement (ACE) bus-lane violations, built in dbt on BigQuery.**

> **Course feedback:**
> *"Great introduction, compelling, interesting, clear. Great thinking about challenges and annotations to describe your thinking and design decisions. Really good work."*
> — Prof. Jaclyn Cohen, CIS 9440 Data Warehousing, Baruch Zicklin School of Business

---

## The business question

If you drive a bus in New York City, where and when are you most likely to lose time to illegally parked vehicles? The MTA owns ACE camera data (where bus-lane violations *are* enforced). The City owns 311 data (where curb-blocking is *complained about* but often not enforced). Neither dataset alone tells the operations story — together they reveal which corridors are choking bus service and which neighborhoods are absorbing the externality without enforcement.

This project unifies the two sources into a conformed star schema and exposes cross-mart analytics for borough comparisons, time-of-day patterns, violation-type mix, and complaint-vs-enforcement gaps.

---

## My contributions

| Area | What I did |
|---|---|
| **Data modeling** | Designed and authored the 2-fact, 6-dimension conformed star schema (see [Architecture](#architecture)) |
| **dbt development** | Authored all staging models, conformed dimensions, and fact tables in this repo. 40+ commits visible in [git history](https://github.com/heejeyoo/nyc-analytics-project-hyoo/commits/beginning-staging-work) |
| **Data quality** | Wrote dbt tests (not_null, unique, accepted_values, referential integrity) across every model |
| **Analytics SQL** | Authored the 5 cross-mart analytical queries that drive the final reporting layer (see `sql/Final_Queries.sql`) |
| **Project documentation** | Led drafting of the 16-page final report and appendix |

**Team contributions (acknowledged):** Rabiul Hasan led the team repo and source ingestion strategy. Carlos Austin contributed to source profiling. Riya Prajapati built the Looker Studio visualization layer over the marts.

---

## Architecture

### Sources (raw landing in BigQuery)

- **NYC 311 Traffic** — curb-related service requests (Illegal Parking, Blocked Bike Lane, Double Parking, etc.); ~2.55M rows
- **MTA ACE Violations** — automated camera bus-lane enforcement events; ~6.36M rows

### Star schema (project_work)

```
                       ┌─────────────┐
                       │   dim_date  │  (hour grain, YYYYMMDDHH int key,
                       │             │   peak-period buckets)
                       └──────┬──────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
   ┌──────────▼──────────┐         ┌──────────▼──────────┐
   │ fact_311_complaints │         │ fact_ace_violations │
   └──────────┬──────────┘         └──────────┬──────────┘
              │                               │
              ├──── dim_location ─────────────┤  (conformed)
              │                               │
              │                               ├──── dim_bus_route
              │                               ├──── dim_bus_stop
              │                               └──── dim_ace_violation_type
              │
              └──── dim_311_problem
```

**2 fact tables · 6 dimension tables** (2 conformed shared + 4 mart-specific)

### Why this schema

- **Hour-grain `dim_date`** with peak-period buckets (`AM_PEAK`, `MIDDAY`, `PM_PEAK`, `EVENING`, `OVERNIGHT`) — enables time-of-day analysis a daily grain would lose
- **Conformed `dim_location`** — built by union-distinct of distinct 311 and ACE locations, allowing cross-mart drill-down by borough / zip / neighborhood / council district
- **Borough derivation in `stg_ace`** — raw ACE data lacks borough; derived from `bus_route_id` prefix conventions (Bx*→Bronx, M*→Manhattan, etc.)
- **Dedup CTEs** in staging — raw 311 exports occasionally republish complaints across daily snapshots; `qualify row_number()` keeps the latest version per `complaint_id`

---

## Tech stack

- **Transformation:** dbt Cloud (dbt Core under the hood), `dbt-labs/dbt_utils 1.1.1`, `dbt-labs/codegen 0.12.1`
- **Warehouse:** Google BigQuery (development project: `heejeyoo-cis9440-sp26`; final integration: team-shared GCP project)
- **Source ingestion:** NYC Open Data + NY State Open Data Socrata APIs
- **Visualization:** Looker Studio (dashboard built by teammate — link below)
- **Languages:** SQL (BigQuery dialect), Jinja, YAML

---

## SQL patterns demonstrated

- `safe_cast()` discipline in staging (raw types are all STRING; bad rows → NULL not failure)
- `qualify row_number() over (partition by … order by …)` for dedup
- Conformed dimension construction via `union distinct` of distinct subsets
- `coalesce(field, '~')` join keys to handle nullable natural keys
- Surrogate `row_number()` keys + integer `YYYYMMDDHH` date keys
- `relationships` tests for referential integrity across fact-to-dim edges
- Hour-grain time bucketing with `timestamp_trunc()` and `format_timestamp()`

---

## Visualization layer

The team's Looker Studio dashboard sits directly on top of the marts in this repo: [open dashboard](https://datastudio.google.com/s/ofQg6Rtwmfo).

*Visualization layer built by team member Riya Prajapati. Included to demonstrate how the dbt marts I authored power the final reporting surface — five cross-mart breakdowns (by borough, year, month, day-of-week, and violation-type mix) plus two scorecards for total ACE and total 311 volume.*

---

## Repo structure

```
nyc-analytics-project-hyoo/
├── README.md                ← you are here
├── dbt_project.yml          ← schema config, project + dataset routing
├── packages.yml             ← dbt_utils, codegen
├── docs/
│   └── Final_Report.pdf     ← 16-page final report (team co-authored)
├── sql/
│   └── Final_Queries.sql    ← 5 cross-mart analytical queries
└── models/
    ├── project_work/        ← Squeeze Index (this project)
    │   ├── staging/         ← stg_311, stg_ace + sources.yml + tests
    │   └── marts/
    │       ├── shared/      ← dim_date, dim_location (conformed)
    │       ├── complaints_311/   ← dim_311_problem, fact_311_complaints
    │       └── ace_violations/   ← dim_ace_violation_type, dim_bus_route,
    │                              dim_bus_stop, fact_ace_violations
    └── assignment_work/     ← earlier course work (NYC DOT 311 +
                               Open Restaurant Applications) — left in
                               place to show prior dimensional modeling
```

---

## Future work

Reviewer noted the natural extension: explicit time-series modeling. Camera deployment scaled meaningfully through the data window, so ACE volume growth is partly a coverage artifact, not pure behavioral change. A future pass would model this with a deployment-history dim, lag-adjusted enforcement rates, and seasonal decomposition before drawing trend claims.

---

## Team

- **Rabiul (Lincoln) Hasan** — source ingestion, team repo
- **Heeje Yoo** — dbt models, analytics SQL, documentation *(this fork)*
- **Carlos Austin** — source profiling
- **Riya Prajapati** — Looker Studio visualization layer

Course: CIS 9440 Data Warehousing, Spring 2026 · Baruch Zicklin School of Business

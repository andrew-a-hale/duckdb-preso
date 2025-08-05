---
marp: true
theme: gaia
---

<!-- _class: lead -->

# DuckDB, MotherDuck, and DuckLake

A brief introduction made with marp.

---

# The Parts

- **DuckDB**: Highly Optimised in-process SQL Engine
- **MotherDuck**: Cloud Managed Intrastructure for Compute and Storage
- **DuckLake**: High Performance SQL Catalog

---

# DuckDB

Getting Started

```bash
curl https://install.duckdb.org | sh
```

## Examples
- Create Table from CSV - CLI
- Join JSON with Excel Data - DuckDB UI
- Remote Read - Terminal

---

<style scoped>
section {
  font-size: 1.5em;
}
</style>

# MotherDuck

- Simplify User Management with only Organisations, Admins, and Members
- Dual Execution for individual query nodes
  - Local Compute with DuckDB Client and WASM
  - On-demand and Provisioned compute from MotherDuck
- Consumption
  - Shares
  - Customer-Facing Analytics
- Pricing
  - Flat cost per Org + Compute cost + Storage cost + AI cost
  - Compute costs are highly optimisable with on-demand, provisioned, and local compute
- MotherDuck UI

---

<style scoped>
section {
  font-size: 1.3em;
}
</style>

# DuckLake

*A Database-First Approach to the Lakehouse Architecture*

## Advantages
- Catalog-Based Access Control
- "Data Inlining"
- Multi-Table ACID Compliant
- Database Statistics for Object Storage

## Disadvantages
- Management of SQL Database Catalog
- Not a open standard
- Not mature
  - Support for column and row security is on the roadmap
  - Support for Spark, Iceberg, and Delta Lake are on the roadmap

---

# All Together

- Simple Data Pipeline - Austender Bash Script

---

# Links
- Repo: 
- Austender Bash Script: https://github.com/andrew-a-hale/austender
- XLSX Challenge: https://github.com/andrew-a-hale/xlsx-challenge

---

<style scoped>
section {
  font-size: 1.5em;
}
</style>

# Questions

- Storage
  - Storage Cost is $0.08 per GB while Snowflake is closer to $0.23 per GB ($23 per TB)
- Pricing
  - Is there an apples-to-apples comparison of workloads on DuckDB vs Competitors?
- Security
  - Patterns for handling PII? (Prior to column and row level security which is on the roadmap)
  - Where is the data stored on managed MotherDuck?
- Does managed DuckLake have latency if our Object Storage is in APAC? Since all queries go through the catalog.
- Merch??

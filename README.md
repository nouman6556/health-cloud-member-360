# Health Cloud Member 360 (Apex + LWC)

A consolidated **member view** for payer member-services teams: coverage, care plans, care team and recent encounters in one **Lightning Web Component**, served by an **Apex selector/service layer** that loads everything in a **single SOQL query**. The tests assert that query budget, so it can't quietly regress.

> Portfolio / reference project built with synthetic data. It uses lightweight custom objects shaped like the Health Cloud data model, so it deploys to any org.

## What the component shows

- **Header:** name, age, location, current plan, and a coverage status badge (Active / Terminated / No coverage)
- **Care alerts:** no active coverage; no primary care physician; 2+ ER visits in 12 months; high utilisation with no active care plan
- **Utilisation tiles:** encounters and ER visits in the last 12 months, active care plans, care team size
- **Tabs:** Coverage · Care Plans · Care Team · Recent Encounters

## Design

```
LWC member360 (Contact record page)
   │  @wire, cacheable
   ▼
Member360Controller ──▶ Member360Service ──▶ Member360Selector
                          │ pure build()        │ ONE query:
                          │  coverage status    │ Contact + 4 child subqueries
                          │  12-month counts    │ WITH USER_MODE
                          │  care alerts        │
```

| Class | Role |
|---|---|
| `Member360Selector` | A single parent-child SOQL query (Care Plans, Care Team, Coverages, Encounters) in user mode. |
| `Member360Service` | Builds the view model. `build()` is pure logic: coverage selection (Medical preferred), utilisation windows and alert rules. |
| `Member360Controller` | `@AuraEnabled(cacheable=true)` entry point. Turns access errors into friendly messages. |
| `TestDataFactory` | Synthetic members, coverages, encounters and care teams. |
| `Member360Test` | Query-budget assertion, alert rules, age edge cases, missing records, and a user without the permission set being blocked. |
| `Member_360_User` | Permission set with object, field and class access. |

## Data model and Health Cloud mapping

| This repo | Health Cloud object |
|---|---|
| `Contact` (member) | Person Account / Contact |
| `Member_Coverage__c` | `MemberPlan` |
| `Care_Plan__c` | `CarePlan` |
| `Care_Team_Member__c` | `CareTeam` / `CaseTeamMember` |
| `Encounter__c` | `ClinicalEncounter` |

To run on Health Cloud objects, change only `Member360Selector`. The service, component and tests stay the same.

## Run it

```bash
sf org create scratch -f config/project-scratch-def.json -a m360 -d
sf project deploy start -d force-app
sf org assign permset -n Member_360_User
sf apex run test -l RunLocalTests -w 10 -c
```

Then add **Member 360** to the Contact record page in Lightning App Builder.

## Tech

Salesforce Health Cloud data model · Apex (selector / service layering) · Lightning Web Components · @wire · SOQL parent-child queries · Apex test data factory · Salesforce DX · GitHub Actions

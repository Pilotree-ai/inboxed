# Scoring

Score out of 100 from the `check-dns.sh` output, plus the copy and volume checks when they've been run. Each line below gives the points and the exact condition. Show the subtotal for each group in the report.

## Authentication (45)

| Points | Condition |
|---|---|
| 8 | Exactly one SPF record (`SPF_RECORDS: 1`). Two or more SPF records is a hard fail for SPF, so score 0 here and make it fix #1 |
| 4 | `SPF_LOOKUPS` is 10 or fewer. Over 10 means receivers return `permerror` and SPF fails |
| 3 | `SPF_ALL` is `~all` or `-all`. `?all` scores 1, `+all` scores 0 and is fix #1 (anyone can send as the domain) |
| 15 | At least one DKIM selector at 2048 bits or more. 1024-bit scores 10. `WEAK` scores 4. Not found scores 0, but mark it "~" not "✗" until headers confirm, because the selector may be custom |
| 10 | A DMARC record exists |
| 5 | DMARC `p=quarantine` or `p=reject` (with `pct` absent or 100). `p=none` scores 2: fine while you watch reports, but it doesn't protect anything |

## Reputation (25)

| Points | Condition |
|---|---|
| 15 | No `LISTED` result anywhere. Each distinct listing costs 8 points (minimum 0). A listing on the domain lists (`DOMAIN_BL`) is always fix #1. `INCONCLUSIVE` costs nothing |
| 10 | Domain registered more than 1 year ago: 10. 3 to 12 months: 7. 1 to 3 months: 3. Under 1 month: 0. Unknown: 5, and say so |

## Infrastructure (10)

| Points | Condition |
|---|---|
| 5 | MX records exist. Replies to cold email need somewhere to land, and some receivers distrust domains with no MX. `MX: 0 .` (null MX) or none scores 0 |
| 2 | MTA-STS record present |
| 1 | TLS-RPT record present |
| 2 | BIMI record present. Nice to have, never a priority fix |

## Practice (20)

| Points | Condition |
|---|---|
| 10 | Copy check (`copy-check.md`): 10 with no red flags, minus 3 per red flag and 1 per amber flag, minimum 0 |
| 10 | Volume plan (`warmup.md`): 10 if the planned daily volume is within the safe range for the mailbox's age, 5 if up to 50% over, 0 if more |

**If Practice wasn't checked,** score the other 80 and scale to 100 (`round(score / 80 * 100)`), and add "Practice not checked" next to the score. Never invent copy or volume results.

## Verdict

| Score | Verdict |
|---|---|
| 90 to 100 | Ready |
| 75 to 89 | Close |
| 50 to 74 | Risky |
| Under 50 | Not ready |

Any of these caps the verdict at **Not ready**, whatever the score: no SPF and no DKIM, `+all`, two SPF records, or a confirmed listing on a domain blocklist.

---
name: deliverability
description: Check whether a domain's cold or sales email will land in the inbox, and say exactly how to fix it. Runs read-only DNS checks (SPF, DKIM, DMARC, MX, MTA-STS, BIMI, blocklists, domain age), scores the result out of 100, and writes the exact DNS records to paste in. Can also check an email draft for spam triggers, read the headers of a test email to confirm authentication really passes, and plan a safe warm-up and daily volume. Use this skill whenever the user asks why their emails go to spam, whether their domain is set up for outbound, to check SPF/DKIM/DMARC, to audit a sending domain or mailbox before a campaign, to check a cold email for spam words, to read email headers, or how many emails a day they can safely send, even if they do not say "deliverability".
---

# Inboxed

One domain in, a clear inbox score and the exact fixes out. Everything here is read-only: the skill looks up public DNS records and reads what the user pastes. It never sends email, changes DNS or signs in anywhere.

## The run

Keep the user informed with one short line per step.

| # | Step | Read | When |
|---|---|---|---|
| 1 | Work out the domain. Use the one the user names. If they give an email address, use the part after `@`. If they name a tool (Google Workspace, Microsoft 365, Apollo, Instantly, Smartlead, HubSpot, SendGrid), note it, because it decides which DKIM selector and SPF include to expect | `references/fixes.md` (provider table) | Always |
| 2 | Run `scripts/check-dns.sh <domain>`. If the user knows their DKIM selector, pass it as a second argument. Run it again for any separate cold-outreach domain they mention | | Always |
| 3 | Score it | `references/scoring.md` | Always |
| 4 | Write the fixes: exact records to paste, in priority order | `references/fixes.md` | Anything below full marks |
| 5 | Check the email copy | `references/copy-check.md` | If the user pastes a draft or asks |
| 6 | Read test-email headers | `references/headers.md` | If the user pastes headers, or DKIM wasn't found in step 2 |
| 7 | Plan volume and warm-up | `references/warmup.md` | If the user mentions volume, a new mailbox or a new domain |

Run steps 2 to 4 without asking first: they are free and change nothing. After the report, offer steps 5 to 7 in one line if the user hasn't already covered them.

## The report

Always use this shape, in this order. Keep it tight: the score card first, the fixes second, the detail last.

```
Inbox score for <domain>: <n>/100  <one-word verdict: Ready | Close | Risky | Not ready>

  Authentication  <n>/45   SPF ✓ · DKIM ✓ (google, 2048-bit) · DMARC ✓ p=quarantine
  Reputation      <n>/25   No blocklist hits · registered 2019
  Infrastructure  <n>/10   MX ✓ · MTA-STS ✗ · BIMI ✗
  Practice        <n>/20   <copy and volume, or "not checked">

Fix first
  1. <the single highest-impact fix, in one line> → record below
  2. ...

<exact DNS records, one fenced block per record: type, host, value>

Details
  <anything inconclusive, and what each check means, in plain words>
```

Use ✓, ✗ and ~ (partial or inconclusive). Give the exact host and value for every record, in a form the user can paste into their DNS provider. Never say "consider adding DMARC" without the record itself.

If the Artifact tool is available, offer once to publish the score card as a private page the user can share with their team. Don't publish without a yes.

## Rules

- **Read-only.** Don't edit DNS, send test emails or sign in to any tool. If the user wants a test email checked, ask them to send one to themselves and paste the headers (`references/headers.md`).
- **Inconclusive isn't listed.** Spamhaus and URIBL refuse lookups from big public resolvers and answer `127.255.255.x` or `127.0.0.1`. Report these as "couldn't check from here", never as a listing, and point to the free web lookup (`references/fixes.md`).
- **DKIM may hide behind a custom selector.** "Not found" only means none of the common selectors matched. Say so, and offer the header check, which shows the real selector (`s=` in the DKIM signature).
- **Don't overstate.** A perfect DNS setup doesn't guarantee the inbox: reputation, volume and content matter too. Say this once, plainly, when the score is 90 or above.
- **Respect the user's domain.** Only check domains the user owns or is authorised to check, and don't run the script in a loop against lists of other people's domains.
- **Cold email on the main domain.** If the user plans cold outreach from their primary domain, recommend a separate, similar domain (for example `getacme.com` for `acme.com`) with its own SPF, DKIM and DMARC. Recommend it, don't fail them for it.

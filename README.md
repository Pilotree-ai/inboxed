<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/brand/inboxed-lockup-endorsed-reversed.svg">
    <img src="assets/brand/inboxed-lockup-endorsed.svg" alt="Inboxed by Pilotree" height="72">
  </picture>
</p>

# Inboxed

**Is your email landing in the inbox? Find out in one sentence, and get the exact fix.**

Inboxed is a plugin for [Claude Code](https://claude.com/claude-code). Point it at your domain and it checks everything mailbox providers check before they decide where your email goes: SPF, DKIM, DMARC, blocklists, domain age and more. You get a score out of 100, and every fix comes as a DNS record you can paste in.

```
> is acme.com ready for cold email?
```

```
Inbox score for acme.com: 58/100  Risky

  Authentication  25/45   SPF ✓ · DKIM ~ (not found) · DMARC ✗
  Reputation      22/25   No blocklist hits · registered 2023
  Infrastructure   5/10   MX ✓ · MTA-STS ✗ · BIMI ✗
  Practice         —      not checked

Fix first
  1. Add a DMARC record (monitoring only, blocks nothing) → record below
  2. Switch on DKIM in Google Workspace → Admin console > Gmail > Authenticate email
  3. ...
```

It's read-only. It looks up public DNS and reads what you paste. It never sends email, changes your DNS or signs in anywhere.

---

## Install

```
/plugin marketplace add Pilotree-ai/inboxed
/plugin install inboxed@inboxed
```

The skill shows up as `inboxed:deliverability`. You don't need to call it by name: just ask about your email.

**Needs:** Claude Code, and `dig` and `curl`, which come with macOS and most Linux systems. No accounts, no API keys.

---

## Why it exists

Your emails go to spam and nobody tells you why.

- **The failure is silent.** Google and Microsoft don't bounce your email to spam. They just file it there. You find out weeks later, from a reply rate that quietly fell to zero.
- **The setup is a dark art.** SPF, DKIM, DMARC, alignment, lookup limits, `~all` against `-all`. Most guides explain the theory and leave you to work out the record.
- **The rules got stricter.** Since 2024, Google and Yahoo require SPF, DKIM and DMARC from bulk senders, and treat a 0.3% spam complaint rate as the line.
- **One bad week costs months.** Sending too much, too soon, from a new mailbox can damage a domain's reputation long after you stop.

Inboxed does the checking in seconds and gives you the exact records to paste. You only need to understand what it tells you to do.

---

## What it checks

```
  acme.com
     │
  1  DNS            SPF (records, lookups, ending) · DKIM (common selectors, key size)
                    DMARC (policy, alignment, reports) · MX · MTA-STS · TLS-RPT · BIMI
     │
  2  Reputation     Domain and IP blocklists (Spamhaus, SpamCop, Barracuda, SURBL,
                    URIBL, PSBL) · domain age
     │
  3  Score          Out of 100, with a verdict: Ready · Close · Risky · Not ready
     │
  4  Fixes          Exact records to paste, in priority order, for your provider
     │
     ├─ Copy        Paste a draft: links, formatting, opt-out, pushy wording        optional
     ├─ Headers     Paste a test email's headers: did SPF, DKIM and DMARC
     │              really pass, and do they line up with your From address?        optional
     └─ Volume      How many emails a day each mailbox can safely send, week by week optional
```

---

## Things you can say

```
> is acme.com ready for cold email?
> why are my emails going to spam? I send from sam@acme.com with Google Workspace
> check my SPF, DKIM and DMARC
> check this cold email for spam triggers: <paste>
> here are the headers from my test email: <paste>
> I have 3 new mailboxes. How many emails a day can I send?
> set up DMARC for acme.com
```

---

## Good to know

- **A perfect score isn't a guarantee.** DNS is the part you can check. What recipients do with your email (open, reply, mark as spam) matters as much, and only good lists and good copy fix that.
- **"Inconclusive" isn't "listed".** Some blocklists refuse lookups from big public DNS resolvers. Inboxed says when a list couldn't be checked and links to its free web lookup.
- **Custom DKIM selectors.** If your provider uses an unusual selector, DNS alone can't find it. Paste a test email's headers and Inboxed reads the real one.
- **Headers contain your address and IPs.** Paste them into Claude, not into a public issue.
- **Only check domains you own** or are authorised to check.

---

## What's inside

```
skills/deliverability/
  SKILL.md              the run, the report format and the rules
  scripts/
    check-dns.sh        read-only DNS, blocklist and domain-age checks
  references/
    scoring.md          how the score out of 100 is worked out
    fixes.md            exact records per provider, blocklist removal links
    copy-check.md       red and amber flags in an email draft
    headers.md          reading a test email's authentication results
    warmup.md           safe daily volume per mailbox, week by week
```

Run the checker on its own if you like:

```
skills/deliverability/scripts/check-dns.sh acme.com
```

---

## More from Pilotree

- **[Vetted](https://github.com/Pilotree-ai/vetted):** one sentence in, an approved, personalised outbound campaign out. Run Inboxed first, then Vetted.
- **[Recon](https://github.com/Pilotree-ai/recon):** a weekly digest of what your competitors changed.
- **[Squawk](https://pilotree.ai/squawk):** find out if AI recommends you.

Built by [Pilotree](https://pilotree.ai). MIT licensed.

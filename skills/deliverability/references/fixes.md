# Fixes

Write every fix as an exact record the user can paste. Order them by impact: anything that caps the verdict first, then authentication, then reputation, then infrastructure. Say where to add it ("in your DNS provider, usually where you bought the domain, or Cloudflare if it's on Cloudflare").

Format each record like this:

```
Type:  TXT
Host:  _dmarc            (some providers want the full name: _dmarc.acme.com)
Value: v=DMARC1; p=none; rua=mailto:dmarc@acme.com; adkim=r; aspf=r
TTL:   3600 (or the default)
```

## Provider table

| Sender | SPF include | DKIM selector | Where to switch DKIM on |
|---|---|---|---|
| Google Workspace | `include:_spf.google.com` | `google` | Admin console > Apps > Google Workspace > Gmail > Authenticate email. Generate a 2048-bit key, add the TXT record, then press **Start authentication** |
| Microsoft 365 | `include:spf.protection.outlook.com` | `selector1`, `selector2` (CNAMEs) | Microsoft Defender portal > Email authentication settings > DKIM. Add both CNAMEs, then enable |
| Zoho Mail | `include:zohomail.com` (EU: `include:zohomail.eu`) | set in Zoho admin | Zoho Mail admin > Domains > Email configuration > DKIM |
| SendGrid | `include:sendgrid.net` | `s1`, `s2` (CNAMEs) | Settings > Sender Authentication |
| Mailgun | `include:mailgun.org` | `krs`, `mg`, or a custom one | Sending > Domains > DNS records |
| HubSpot | `include:<id>.spf.hubspotemail.net` (from HubSpot) | `hs1`, `hs2` (CNAMEs) | Settings > Website > Domains & URLs > Email sending domains |
| Amazon SES | `include:amazonses.com` (only if using a custom MAIL FROM) | random tokens (3 CNAMEs) | SES > Verified identities > DKIM |

Apollo, Instantly, Smartlead and Lemlist send through the mailbox you connect (usually Google or Microsoft), so the mailbox provider's records are the ones that matter. Each tool also has a custom tracking domain (a CNAME such as `track.acme.com`). If the user uses open or click tracking, recommend setting it up, because shared tracking domains are often blocklisted.

## Common fixes

**No SPF.** Build it from the providers they actually send with, and end it in `~all`:
`v=spf1 include:_spf.google.com ~all`

**Two SPF records.** Merge them into one. Keep every `include:` from both, once each, then a single `~all`. Delete the other record.

**Over 10 SPF lookups.** Remove includes for tools they no longer use first. If still over, move marketing or transactional email to a subdomain (`mail.acme.com`) with its own SPF. Don't recommend paid "SPF flattening" services by name.

**`+all` or `?all`.** Change the ending to `~all`. Move to `-all` only once DMARC reports show nothing legitimate failing.

**No DKIM.** Point to the right row in the provider table. DKIM can't be written by hand: the provider generates the key. If one exists at 1024 bits, recommend rotating to 2048 where the provider allows it.

**No DMARC.** Start with monitoring, so nothing legitimate gets blocked:
`v=DMARC1; p=none; rua=mailto:dmarc@<domain>; adkim=r; aspf=r`
Then: "After two to four weeks of clean reports, move to `p=quarantine`." The `rua` mailbox must exist. A free DMARC report reader makes the XML readable.

**DMARC `p=none` for months.** Recommend `p=quarantine; pct=100` once the reports show their senders pass.

**Blocklist hit.** Name the list and link its own lookup and removal page:
- Spamhaus: https://check.spamhaus.org
- SpamCop: https://www.spamcop.net/bl.shtml
- Barracuda: https://www.barracudacentral.org/lookups
- SURBL: https://www.surbl.org/surbl-analysis
- URIBL: https://admin.uribl.com
- PSBL: https://psbl.org
Say: stop sending cold email from the domain until it's delisted, and find the cause (a burst of volume, a bought list, a compromised mailbox) before requesting removal.

**Inconclusive blocklist.** "Couldn't check <list> from this network. Look it up for free at <link>."

**No MX.** Add the mailbox provider's MX records so replies can land. Google: `MX 1 smtp.google.com`.

**MTA-STS, TLS-RPT, BIMI.** Low priority. Mention them in one line at the end, with TLS-RPT as the easy one:
`Type: TXT  Host: _smtp._tls  Value: v=TLSRPTv1; rua=mailto:tls-reports@<domain>`

**New domain.** Nothing to paste: it needs time. Point to `warmup.md`.

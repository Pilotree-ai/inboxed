# Header check

DNS shows what a domain publishes. Headers show what a receiver actually decided. Use this when DKIM wasn't found, when the user says emails still go to spam, or when they paste headers.

## Getting the headers

Ask the user to send a normal email from the sending mailbox to a personal Gmail or Outlook address they own, then:

- **Gmail:** open the email > ⋮ > **Show original** > **Copy to clipboard**.
- **Outlook (web):** open the email > ⋯ > **View** > **View message source**.
- **Apple Mail:** View > Message > **All Headers**.

They paste everything. Tell them headers contain their email address and IP addresses, so they shouldn't post them publicly.

## What to read

| Header | What to look for |
|---|---|
| `Authentication-Results` | `spf=pass`, `dkim=pass`, `dmarc=pass`. Note `header.d=` (the DKIM signing domain) and `smtp.mailfrom=` |
| `DKIM-Signature` | `d=` (signing domain) and `s=` (the real selector, so you can re-run `check-dns.sh <domain> <selector>`) |
| `Received-SPF` | `pass` or why it failed |
| `ARC-Authentication-Results` | The same results when the email was forwarded |
| `X-Microsoft-Antispam`, `X-Forefront-Antispam-Report` | Outlook only: `SCL` 0 to 1 is inbox, 5 and up is junk. `compauth=pass` is good |
| `X-Spam-Status`, `X-Spam-Score` | Other servers: the spam score and which rules fired |

## Alignment, in plain words

DMARC passes only if SPF or DKIM passes **and** its domain matches the From address domain.

- DKIM aligned: `header.d=` is the same as the From domain, or a subdomain of it when `adkim=r`.
- SPF aligned: `smtp.mailfrom=` is the same as the From domain, or a subdomain of it when `aspf=r`.

The most common failure: a sending tool signs with its own domain (`d=sendgrid.net`) so DKIM "passes" but isn't aligned. Fix: set up the tool's domain authentication (`fixes.md` provider table).

## Report

```
Test email from <sender> to <receiver>
  SPF    pass ✓  aligned ✓ (acme.com)
  DKIM   pass ✓  aligned ✗ (signed by sendgrid.net, selector s1)
  DMARC  pass ✓  (via SPF)
  Spam   SCL 1, inbox
```

Then the fix for anything not both passing and aligned.

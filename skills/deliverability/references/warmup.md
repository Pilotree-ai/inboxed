# Volume and warm-up

Mailbox providers judge a new sender by how fast its volume grows and how recipients react. The ramp below is conservative on purpose: one bad week can hurt a domain for months.

## Ask (only what's missing)

- How old is the domain and the mailbox? (`check-dns.sh` gives the domain's age.)
- How many mailboxes will send?
- How many cold emails a day do they want to send in total?
- Is it cold outreach, or email to people who asked for it?

## Safe daily cold volume, per mailbox

| Mailbox age | Per day |
|---|---|
| Week 1 | 0 cold. Send normal email to colleagues and contacts and get replies |
| Week 2 | 5 to 10 |
| Week 3 | 10 to 20 |
| Week 4 | 20 to 30 |
| Month 2 | 30 to 40 |
| After that | 40 to 50, and treat 50 as the ceiling for cold email from one mailbox |

Domains under 30 days old: add two weeks before any cold email. If the user needs more volume, add mailboxes (and, for big programmes, a second domain), never more per mailbox.

## Planning the user's numbers

1. Work out the safe total today: mailboxes × the per-day figure for their age.
2. Compare it with what they want. If they want more, say how many mailboxes, or how many weeks of ramp, gets them there.
3. Give a week-by-week table for the next four weeks.

## Signals to stop or slow down

- Bounce rate over 2%: stop and clean the list (verify emails before sending).
- Spam complaint rate over 0.1% (Google Postmaster Tools shows it): halve volume. Over 0.3%: stop. Google and Yahoo treat 0.3% as the line for bulk senders.
- Reply rate falling sharply with the same copy: check placement with a header test (`headers.md`).

Recommend Google Postmaster Tools (https://postmaster.google.com) for any domain sending to Gmail addresses. It's free and shows the domain's reputation as Gmail sees it.

Paid "warm-up networks" that swap fake emails between mailboxes are against most providers' terms. Don't recommend them. Real, gradual sending is the warm-up.

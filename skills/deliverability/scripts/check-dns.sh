#!/usr/bin/env bash
# Inboxed DNS checker. Read-only: it only runs public DNS and RDAP lookups.
#
# Usage: check-dns.sh <domain> [dkim-selector ...]
#
# Prints one section per check, each line "KEY: value", so the skill can score
# the results without guessing. Works with the stock macOS and Linux tools
# (bash 3.2+, dig, curl).

set -u
domain="${1:-}"
if [ -z "$domain" ]; then
  echo "usage: check-dns.sh <domain> [dkim-selector ...]" >&2
  exit 2
fi
shift
domain=$(printf '%s' "$domain" | tr 'A-Z' 'a-z' | sed -e 's#^https\{0,1\}://##' -e 's#/.*##' -e 's/^www\.//')

command -v dig >/dev/null 2>&1 || { echo "ERROR: dig not found (install bind-utils / dnsutils)"; exit 2; }

q()   { dig +short +time=3 +tries=2 "$@" 2>/dev/null; }
txt() { q TXT "$1" | sed -e 's/" "//g' -e 's/^"//' -e 's/"$//'; }
sec() { printf '\n## %s\n' "$1"; }

# Count DNS-querying SPF terms, following include: and redirect= (RFC 7208 limit is 10).
spf_lookups() {
  local dom=$1 depth=$2 rec term n=0 m
  if [ "$depth" -gt 8 ]; then echo 99; return; fi
  rec=$(txt "$dom" | grep -i '^v=spf1' | head -1)
  for term in $rec; do
    term=$(printf '%s' "$term" | tr 'A-Z' 'a-z')
    term=${term#[+~?-]}
    case "$term" in
      include:*)  n=$((n+1)); m=$(spf_lookups "${term#include:}" $((depth+1))); n=$((n+m)) ;;
      redirect=*) n=$((n+1)); m=$(spf_lookups "${term#redirect=}" $((depth+1))); n=$((n+m)) ;;
      a|a:*|a/*|mx|mx:*|mx/*|ptr|ptr:*|exists:*) n=$((n+1)) ;;
    esac
  done
  echo "$n"
}

echo "DOMAIN: $domain"
echo "CHECKED_AT: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

sec MX
mx=$(q MX "$domain" | sort -n)
if [ -n "$mx" ]; then printf '%s\n' "$mx" | sed 's/^/MX: /'; else echo "MX: NONE"; fi

sec SPF
spf=$(txt "$domain" | grep -i '^v=spf1')
spf_count=$(printf '%s\n' "$spf" | grep -c . )
if [ -z "$spf" ]; then
  echo "SPF: NONE"
else
  printf '%s\n' "$spf" | sed 's/^/SPF: /'
  echo "SPF_RECORDS: $spf_count"
  echo "SPF_LOOKUPS: $(spf_lookups "$domain" 0)"
  all=$(printf '%s' "$spf" | grep -oiE '[~?+-]?all' | tail -1)
  echo "SPF_ALL: ${all:-MISSING}"
fi

sec DMARC
dmarc=$(txt "_dmarc.$domain" | grep -i '^v=dmarc1')
if [ -z "$dmarc" ]; then
  echo "DMARC: NONE"
else
  echo "DMARC: $dmarc"
  for tag in p sp pct rua ruf adkim aspf; do
    v=$(printf '%s' "$dmarc" | tr ';' '\n' | sed 's/^ *//' | grep -i "^$tag=" | head -1 | cut -d= -f2-)
    [ -n "$v" ] && echo "DMARC_$(printf '%s' "$tag" | tr 'a-z' 'A-Z'): $v"
  done
fi

sec DKIM
selectors="$*"
if [ -z "$selectors" ]; then
  selectors="google selector1 selector2 k1 k2 k3 s1 s2 default dkim mail smtp mandrill mxvault zoho zmail hs1 hs2 sig1 protonmail protonmail2 protonmail3 cm mailjet everlytickey1 everlytickey2 smtpapi pm mte1 mte2 scph0122 sendgrid amazonses mailgun mg krs"
fi
found=0
# A wildcard *._domainkey record would make every selector look real.
wild=$(txt "inboxed-probe-$$._domainkey.$domain" | head -1)
[ -n "$wild" ] && echo "DKIM_WILDCARD: $wild"
for sel in $selectors; do
  rec=$(txt "$sel._domainkey.$domain" | grep -iE 'v=dkim1|k=rsa|k=ed25519|p=' | head -1)
  [ -z "$rec" ] && continue
  [ -n "$wild" ] && [ "$rec" = "$wild" ] && continue
  found=$((found+1))
  p=$(printf '%s' "$rec" | tr ';' '\n' | sed 's/^ *//' | grep '^p=' | head -1 | cut -d= -f2- | tr -d ' ')
  plen=${#p}
  if [ "$plen" -eq 0 ]; then bits="REVOKED"
  elif [ "$plen" -gt 600 ]; then bits="4096"
  elif [ "$plen" -gt 300 ]; then bits="2048"
  elif [ "$plen" -gt 150 ]; then bits="1024"
  else bits="WEAK(<1024)"
  fi
  echo "DKIM_SELECTOR: $sel bits=$bits"
done
[ "$found" -eq 0 ] && echo "DKIM: NOT_FOUND (checked: $selectors)"

sec EXTRAS
mta=$(txt "_mta-sts.$domain" | grep -i '^v=stsv1')
echo "MTA_STS: ${mta:-NONE}"
tls=$(txt "_smtp._tls.$domain" | grep -i '^v=tlsrptv1')
echo "TLS_RPT: ${tls:-NONE}"
bimi=$(txt "default._bimi.$domain" | grep -i '^v=bimi1')
echo "BIMI: ${bimi:-NONE}"
a=$(q A "$domain" | grep -E '^[0-9.]+$' | head -1)
echo "A: ${a:-NONE}"

sec BLOCKLISTS
# Domain lists. Spamhaus refuses queries from big public resolvers and answers
# 127.255.255.x, which means "could not check", not "listed".
classify() {
  case "$1" in
    "") echo "CLEAN" ;;
    127.255.255.*|127.0.0.255|127.0.0.1) echo "INCONCLUSIVE ($1)" ;;
    127.*) echo "LISTED ($1)" ;;
    *) echo "INCONCLUSIVE ($1)" ;;
  esac
}
for bl in dbl.spamhaus.org multi.surbl.org multi.uribl.com; do
  res=$(q A "$domain.$bl" | head -1)
  echo "DOMAIN_BL $bl: $(classify "$res")"
done
# IP lists, for the website and each MX host.
ips="$a"
for host in $(printf '%s\n' "$mx" | awk '{print $2}'); do
  ips="$ips $(q A "$host" | grep -E '^[0-9.]+$' | head -1)"
done
for ip in $ips; do
  rev=$(printf '%s' "$ip" | awk -F. '{print $4"."$3"."$2"."$1}')
  for bl in zen.spamhaus.org bl.spamcop.net b.barracudacentral.org psbl.surriel.com; do
    res=$(q A "$rev.$bl" | head -1)
    echo "IP_BL $ip $bl: $(classify "$res")"
  done
done

sec DOMAIN_AGE
if command -v curl >/dev/null 2>&1; then
  reg=$(curl -sL --max-time 10 "https://rdap.org/domain/$domain" \
        | tr '{}' '\n\n' | grep '"registration"' | grep -oE '"eventDate" *: *"[^"]*"' \
        | head -1 | sed -E 's/.*"([^"]*)"$/\1/')
fi
if [ -z "${reg:-}" ] && command -v whois >/dev/null 2>&1; then
  reg=$(whois "$domain" 2>/dev/null \
        | grep -iE '^ *(creation date|created|registered on|registration time|domain registration date)' \
        | head -1 | sed -E 's/^[^:]*: *//')
fi
echo "REGISTERED: ${reg:-UNKNOWN}"

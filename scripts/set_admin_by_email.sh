#!/usr/bin/env bash
# Set admin=true on a Firestore users doc by email.
# Usage: ./scripts/set_admin_by_email.sh elyayertey@gmail.com
set -euo pipefail

EMAIL="${1:?Usage: $0 <email>}"
PROJECT_ID="${FIREBASE_PROJECT_ID:-todoos-briktap}"

node <<NODE
const fs = require('fs');
const email = '$EMAIL';

async function main() {
  const configPath = require('path').join(
    process.env.HOME,
    '.config/configstore/firebase-tools.json',
  );
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const token = config.tokens.access_token;

  const queryUrl =
    'https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery';
  const queryBody = {
    structuredQuery: {
      from: [{ collectionId: 'users' }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'email' },
          op: 'EQUAL',
          value: { stringValue: email },
        },
      },
      limit: 1,
    },
  };

  const queryRes = await fetch(queryUrl, {
    method: 'POST',
    headers: {
      Authorization: 'Bearer ' + token,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(queryBody),
  });
  const queryJson = await queryRes.json();

  const doc = Array.isArray(queryJson)
    ? queryJson.find((row) => row.document)?.document
    : null;

  if (!doc) {
    console.error('No users doc found for ' + email + '. Sign in to the app once, then rerun.');
    process.exit(1);
  }

  const uid = doc.name.split('/').pop();
  const patchUrl =
    'https://firestore.googleapis.com/v1/' +
    doc.name +
    '?updateMask.fieldPaths=admin';

  const patchRes = await fetch(patchUrl, {
    method: 'PATCH',
    headers: {
      Authorization: 'Bearer ' + token,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields: { admin: { booleanValue: true } } }),
  });

  if (!patchRes.ok) {
    console.error(await patchRes.text());
    process.exit(1);
  }

  console.log('Set admin=true for ' + email + ' (uid: ' + uid + ')');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
NODE

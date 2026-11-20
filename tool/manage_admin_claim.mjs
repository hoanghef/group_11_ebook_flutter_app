import { readOptions, requireApplyConfirmation,
  requireEbookDevelopmentProject, explainError } from './firebase_dev_guard.mjs';

const flags = ['--project-id', '--uid', '--grant', '--revoke',
  '--apply', '--confirm-project'];

async function main() {
  const options = readOptions(process.argv.slice(2), flags);
  const projectId = requireEbookDevelopmentProject(options['--project-id']);
  requireApplyConfirmation(options);
  const uid = options['--uid'];
  if (!uid || !/^[A-Za-z0-9_-]{1,128}$/.test(uid)) {
    throw new Error('Provide a specific valid --uid.');
  }
  if (Boolean(options['--grant']) === Boolean(options['--revoke'])) {
    throw new Error('Choose exactly one of --grant or --revoke.');
  }
  console.log(`Target project: ${projectId}`);
  console.log(`Target UID: ${uid}`);

  const { initializeApp, applicationDefault } = await import('firebase-admin/app');
  const { getAuth } = await import('firebase-admin/auth');
  const app = initializeApp({ credential: applicationDefault(), projectId });
  const auth = getAuth(app);
  const user = await auth.getUser(uid);
  const before = user.customClaims ?? {};
  const after = { ...before };
  if (options['--grant']) after.admin = true;
  else delete after.admin;
  console.log(`Admin claim: ${before.admin === true} -> ${after.admin === true}`);
  if (!options['--apply']) {
    console.log('Preview only; claim was not changed.');
    return;
  }
  await auth.setCustomUserClaims(uid, after);
  console.log('Claim updated. Refresh the user ID token or sign in again.');
}

main().catch(explainError);

import { readOptions, requireApplyConfirmation,
  requireEbookDevelopmentProject, explainError } from './firebase_dev_guard.mjs';
import { loadDemoDocuments } from './demo_catalog_input.mjs';

const flags = ['--project-id', '--confirm-project', '--apply',
  '--update-existing', '--offline-plan', '--catalog-json'];

async function main() {
  const options = readOptions(process.argv.slice(2), flags);
  const projectId = requireEbookDevelopmentProject(options['--project-id']);
  requireApplyConfirmation(options);
  if (options['--offline-plan'] && options['--apply']) {
    throw new Error('--offline-plan cannot write.');
  }
  const documents = loadDemoDocuments(options['--catalog-json']);
  console.log(`Target project: ${projectId}`);
  console.log(`Demo source: 13 categories, 11 books; ${documents.length} documents.`);
  if (options['--offline-plan']) {
    for (const { collection, value } of documents) {
      console.log(`SOURCE ${collection}/${value.id}`);
    }
    console.log('Offline source plan only; remote Firestore was not read or changed.');
    return;
  }

  const { initializeApp, applicationDefault } = await import('firebase-admin/app');
  const { getFirestore, Timestamp, FieldValue } = await import('firebase-admin/firestore');
  const app = initializeApp({ credential: applicationDefault(), projectId });
  const firestore = getFirestore(app);
  const references = documents.map(({ collection, value }) =>
    firestore.collection(collection).doc(value.id));
  const snapshots = await firestore.getAll(...references);
  const actions = documents.map((document, index) => ({
    ...document,
    reference: references[index],
    action: snapshots[index].exists
      ? (options['--update-existing'] ? 'UPDATE' : 'SKIP')
      : 'CREATE',
  }));
  for (const { collection, value, action } of actions) {
    console.log(`${action} ${collection}/${value.id}`);
  }
  if (!options['--apply']) {
    console.log('Preview only; no Firestore writes.');
    return;
  }
  for (const { collection, value, reference, action } of actions) {
    if (action === 'SKIP') continue;
    const { createdAt, ...fields } = value;
    const payload = {
      ...fields,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (action === 'CREATE') {
      payload.createdAt = collection === 'books'
        ? Timestamp.fromDate(new Date(createdAt))
        : FieldValue.serverTimestamp();
      await reference.create(payload);
    } else {
      // update() keeps id and createdAt unchanged on an existing document.
      const { id, ...mutableFields } = payload;
      await reference.update(mutableFields);
    }
    console.log(`WROTE ${collection}/${value.id}`);
  }
  console.log('Seed completed; no documents were deleted.');
}

main().catch(explainError);

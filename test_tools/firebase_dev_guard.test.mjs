import assert from 'node:assert/strict';
import test from 'node:test';
import { readOptions, requireApplyConfirmation,
  requireEbookDevelopmentProject } from '../tool/firebase_dev_guard.mjs';

test('only explicit Ebook development IDs pass', () => {
  assert.equal(requireEbookDevelopmentProject('ebook-dev-12345'), 'ebook-dev-12345');
  for (const id of [undefined, 'demo-ebook', 'coffee-app-dev',
    'ebook-production', 'ebook-prod-123', 'test-7404a', 'ebook-12345']) {
    assert.throws(() => requireEbookDevelopmentProject(id));
  }
});

test('writes require an exact repeated project ID', () => {
  const flags = ['--project-id', '--confirm-project', '--apply'];
  const options = readOptions(['--project-id', 'ebook-dev-12345',
    '--apply', '--confirm-project', 'ebook-dev-12345'], flags);
  assert.doesNotThrow(() => requireApplyConfirmation(options));
  assert.throws(() => requireApplyConfirmation({
    '--project-id': 'ebook-dev-12345', '--apply': true,
  }));
  assert.throws(() => requireApplyConfirmation({
    '--project-id': 'ebook-dev-12345', '--confirm-project': 'ebook-dev-other',
    '--apply': true,
  }));
  assert.throws(() => readOptions(['--project-id', 'one',
    '--project-id', 'two'], flags));
});

import assert from 'node:assert/strict';
import test from 'node:test';
import { loadDemoDocuments, parseDemoCatalogJson } from '../tool/demo_catalog_input.mjs';

function catalog() {
  return {
    categories: Array.from({ length: 13 }, (_, index) => ({
      id: `category_${index}`, name: `Category ${index}`,
      description: 'Demo category', active: true,
    })),
    books: Array.from({ length: 11 }, (_, index) => ({
      id: String(index + 1), title: `Book ${index + 1}`, author: 'Demo',
      description: 'Demo book', coverRef: 'generated:forest',
      categoryIds: ['category_0'], status: 'published', preview: 'Preview',
      contentRef: '', createdAt: '2026-01-01T00:00:00.000Z',
    })),
  };
}

test('JSON file input loads 24 validated documents without Dart', () => {
  const json = JSON.stringify(catalog());
  let requestedPath;
  const documents = loadDemoDocuments('temporary/catalog.json', (path) => {
    requestedPath = path;
    return json;
  });
  assert.equal(requestedPath, 'temporary/catalog.json');
  assert.equal(documents.length, 24);
  assert.equal(documents[0].collection, 'categories');
  assert.equal(documents.at(-1).value.id, '11');
});

test('JSON input rejects invalid cover, category link and book ID', () => {
  for (const change of [
    (data) => { data.books[0].coverRef = 'assets/old.jpg'; },
    (data) => { data.books[0].categoryIds = ['missing']; },
    (data) => { data.books[0].id = '12'; },
  ]) {
    const data = catalog();
    change(data);
    assert.throws(() => parseDemoCatalogJson(JSON.stringify(data)));
  }
});

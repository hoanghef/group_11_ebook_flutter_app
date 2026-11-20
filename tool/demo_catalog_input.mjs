import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const coverStyles = new Set([
  'generated:midnight', 'generated:lagoon', 'generated:coral',
  'generated:forest', 'generated:plum', 'generated:sunrise',
]);
const validId = /^[A-Za-z0-9_]{1,64}$/;

export function parseDemoCatalogJson(json) {
  const data = JSON.parse(json);
  if (!Array.isArray(data.categories) || data.categories.length !== 13 ||
      !Array.isArray(data.books) || data.books.length !== 11) {
    throw new Error('Demo catalog must contain 13 categories and 11 books.');
  }
  const categoryIds = new Set(data.categories.map((value) => value.id));
  const bookIds = new Set(data.books.map((value) => value.id));
  if (categoryIds.size !== 13 || bookIds.size !== 11 ||
      [...bookIds].some((id) => !/^(?:[1-9]|10|11)$/.test(id))) {
    throw new Error('Demo catalog IDs are missing or duplicated.');
  }
  for (const category of data.categories) {
    if (!validId.test(category.id) || category.active !== true ||
        typeof category.name !== 'string' || !category.name.trim() ||
        typeof category.description !== 'string') {
      throw new Error(`Invalid demo category: ${category.id}`);
    }
  }
  for (const book of data.books) {
    if (!validId.test(book.id) || book.status !== 'published' ||
        !coverStyles.has(book.coverRef) ||
        typeof book.title !== 'string' || !book.title.trim() ||
        typeof book.author !== 'string' || !book.author.trim() ||
        typeof book.description !== 'string' ||
        typeof book.preview !== 'string' || !book.preview.trim() ||
        book.preview.length > 2000 ||
        !Array.isArray(book.categoryIds) || book.categoryIds.length < 1 ||
        book.categoryIds.length > 5 ||
        book.categoryIds.some((id) => !categoryIds.has(id)) ||
        typeof book.contentRef !== 'string' ||
        typeof book.createdAt !== 'string' ||
        Number.isNaN(Date.parse(book.createdAt))) {
      throw new Error(`Invalid demo book: ${book.id}`);
    }
  }
  return [
    ...data.categories.map((value) => ({ collection: 'categories', value })),
    ...data.books.map((value) => ({ collection: 'books', value })),
  ];
}

export function loadDemoDocuments(catalogJson, readText = readFileSync) {
  if (catalogJson) return parseDemoCatalogJson(readText(catalogJson, 'utf8'));
  const windowsDart = process.platform === 'win32'
    ? resolve(dirname(execFileSync('where.exe', ['dart.bat'], {
      encoding: 'utf8',
    }).trim().split(/\r?\n/)[0]), 'cache/dart-sdk/bin/dart.exe')
    : null;
  const json = execFileSync(windowsDart ?? 'dart',
    ['tool/export_demo_catalog.dart'], {
      encoding: 'utf8', maxBuffer: 1024 * 1024,
    });
  return parseDemoCatalogJson(json);
}

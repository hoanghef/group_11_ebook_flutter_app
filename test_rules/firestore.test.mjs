import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import {
  initializeTestEnvironment, assertFails, assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  collection, doc, getDoc, getDocs, query, setDoc, updateDoc, deleteDoc,
  where, Timestamp, serverTimestamp,
} from 'firebase/firestore';

let environment;
const stamp = Timestamp.fromDate(new Date('2026-01-01T00:00:00Z'));
const book = (id = 'book_one') => ({
  id, title: 'A book', author: 'An author', description: 'Description',
  coverRef: 'generated:midnight', categoryIds: ['fiction'],
  status: 'published', createdAt: stamp, updatedAt: stamp,
  preview: 'A short preview', contentRef: '',
});
const category = (id = 'fiction') => ({
  id, name: 'Fiction', description: 'Fiction books', active: true,
  createdAt: stamp, updatedAt: stamp,
});

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-ebook',
    firestore: {
      host: '127.0.0.1', port: 8080,
      rules: readFileSync('firestore.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'books/book_one'), book());
    await setDoc(doc(db, 'books/book_archived'), {
      ...book('book_archived'), status: 'archived',
    });
    await setDoc(doc(db, 'categories/fiction'), category());
    await setDoc(doc(db, 'categories/hidden'), {
      ...category('hidden'), active: false,
    });
  });
});

after(async () => { if (environment) await environment.cleanup(); });

test('guest and user read only published books and active categories', async () => {
  for (const context of [
    environment.unauthenticatedContext(),
    environment.authenticatedContext('reader'),
  ]) {
    const db = context.firestore();
    await assertSucceeds(getDoc(doc(db, 'books/book_one')));
    await assertFails(getDoc(doc(db, 'books/book_archived')));
    await assertSucceeds(getDoc(doc(db, 'categories/fiction')));
    await assertFails(getDoc(doc(db, 'categories/hidden')));
    const books = await assertSucceeds(getDocs(query(
      collection(db, 'books'), where('status', '==', 'published'))));
    assert.equal(books.size, 1);
    await assertFails(getDocs(collection(db, 'books')));
  }
});

test('ordinary users and role fields cannot write catalog', async () => {
  const db = environment.authenticatedContext('reader', { role: 'admin' }).firestore();
  await assertFails(setDoc(doc(db, 'books/new_book'), book('new_book')));
  await assertFails(updateDoc(doc(db, 'books/book_one'), { title: 'Changed' }));
  await assertFails(setDoc(doc(db, 'categories/new_category'), category('new_category')));
});

test('admin claim can create, archive and read catalog', async () => {
  const db = environment.authenticatedContext('admin-user', { admin: true }).firestore();
  await assertSucceeds(setDoc(doc(db, 'books/new_book'), book('new_book')));
  await assertSucceeds(updateDoc(doc(db, 'books/new_book'), { status: 'archived' }));
  await assertSucceeds(getDoc(doc(db, 'books/book_archived')));
  await assertSucceeds(setDoc(doc(db, 'categories/new_category'), category('new_category')));
  await assertSucceeds(updateDoc(doc(db, 'categories/new_category'), { active: false }));
  await assertFails(deleteDoc(doc(db, 'books/new_book')));
});

test('admin cannot write malformed keys, fields or oversized preview', async () => {
  const db = environment.authenticatedContext('admin-user', { admin: true }).firestore();
  await assertFails(setDoc(doc(db, 'books/wrong_id'), book('different_id')));
  await assertFails(setDoc(doc(db, 'books/with_role'), { ...book('with_role'), role: 'admin' }));
  await assertFails(setDoc(doc(db, 'books/bad_categories'), {
    ...book('bad_categories'), categoryIds: [123],
  }));
  await assertFails(setDoc(doc(db, 'books/too_long'), {
    ...book('too_long'), preview: 'x'.repeat(2001),
  }));
  await assertFails(setDoc(doc(db, 'categories/wrong_id'), category('different_id')));
  await assertFails(setDoc(doc(db, 'categories/with_role'), {
    ...category('with_role'), role: 'admin',
  }));
});

test('admin lists all catalog states while IDs and creation times stay fixed', async () => {
  const admin = environment.authenticatedContext('admin-user', { admin: true }).firestore();
  const ordinary = environment.authenticatedContext('reader').firestore();
  const guest = environment.unauthenticatedContext().firestore();
  const allBooks = await assertSucceeds(getDocs(collection(admin, 'books')));
  assert.equal(allBooks.size, 2);
  const draft = doc(admin, 'books/new_draft');
  await assertSucceeds(setDoc(draft, { ...book('new_draft'), status: 'draft' }));
  await assertSucceeds(updateDoc(draft, { status: 'published', updatedAt: Timestamp.now() }));
  await assertSucceeds(updateDoc(draft, { status: 'archived' }));
  await assertFails(updateDoc(draft, { id: 'other' }));
  await assertFails(updateDoc(draft, { createdAt: Timestamp.now() }));
  await assertFails(deleteDoc(draft));
  const categoryRef = doc(admin, 'categories/fiction');
  await assertSucceeds(updateDoc(categoryRef, { active: false, updatedAt: Timestamp.now() }));
  await assertFails(updateDoc(categoryRef, { id: 'other' }));
  await assertFails(updateDoc(categoryRef, { createdAt: Timestamp.now() }));
  await assertFails(deleteDoc(categoryRef));
  await assertFails(setDoc(doc(guest, 'books/guest_book'), book('guest_book')));
  await assertFails(setDoc(doc(ordinary, 'categories/user_cat'), category('user_cat')));
  await assertFails(updateDoc(doc(ordinary, 'categories/fiction'), { active: true }));
});

test('admin writes catalog timestamps with server transforms', async () => {
  const db = environment.authenticatedContext('admin-user', { admin: true }).firestore();
  const newBook = doc(db, 'books/server_book');
  await assertSucceeds(setDoc(newBook, {
    ...book('server_book'), createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(newBook, {
    title: 'Updated title', updatedAt: serverTimestamp(),
  }));
  const newCategory = doc(db, 'categories/server_category');
  await assertSucceeds(setDoc(newCategory, {
    ...category('server_category'), createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(newCategory, {
    active: false, updatedAt: serverTimestamp(),
  }));
});

test('owner may read, write and remove personal library documents', async () => {
  const db = environment.authenticatedContext('reader').firestore();
  const favorite = doc(db, 'users/reader/favorites/book_one');
  const progress = doc(db, 'users/reader/readingProgress/book_one');
  await assertSucceeds(setDoc(favorite, { bookId: 'book_one', createdAt: stamp }));
  await assertSucceeds(getDoc(favorite));
  await assertSucceeds(getDocs(collection(db, 'users/reader/favorites')));
  await assertSucceeds(setDoc(progress, {
    bookId: 'book_one', ratio: 0.45, updatedAt: stamp,
  }));
  await assertSucceeds(getDoc(progress));
  await assertSucceeds(updateDoc(progress, { ratio: 0.8 }));
  await assertSucceeds(deleteDoc(favorite));
  await assertSucceeds(deleteDoc(progress));
});

test('other users and guests cannot access a personal library', async () => {
  for (const context of [
    environment.authenticatedContext('other'),
    environment.unauthenticatedContext(),
  ]) {
    const db = context.firestore();
    const favorite = doc(db, 'users/reader/favorites/book_one');
    const progress = doc(db, 'users/reader/readingProgress/book_one');
    await assertFails(getDoc(favorite));
    await assertFails(getDocs(collection(db, 'users/reader/favorites')));
    await assertFails(setDoc(favorite, { bookId: 'book_one', createdAt: stamp }));
    await assertFails(deleteDoc(favorite));
    await assertFails(getDoc(progress));
    await assertFails(setDoc(progress, {
      bookId: 'book_one', ratio: 0.2, updatedAt: stamp,
    }));
    await assertFails(deleteDoc(progress));
  }
});

test('personal library rejects extra fields, invalid IDs and ratios', async () => {
  const db = environment.authenticatedContext('reader', { role: 'admin' }).firestore();
  await assertFails(setDoc(doc(db, 'users/reader/favorites/wrong'), {
    bookId: 'book_one', createdAt: stamp,
  }));
  await assertFails(setDoc(doc(db, 'users/reader/favorites/book_one'), {
    bookId: 'book_one', createdAt: stamp, email: 'private@example.com',
  }));
  await assertFails(setDoc(doc(db, 'users/reader/readingProgress/book_one'), {
    bookId: 'book_one', ratio: 1.1, updatedAt: stamp,
  }));
  await assertFails(setDoc(doc(db, 'users/reader/readingProgress/book_one'), {
    bookId: 'book_one', ratio: '0.2', updatedAt: stamp,
  }));
  await assertFails(setDoc(doc(db, 'users/reader/readingProgress/book_one'), {
    bookId: 'book_one', ratio: 0.2, updatedAt: stamp, role: 'admin',
  }));
  await assertFails(setDoc(doc(db, 'users/reader/readingProgress/bad.id'), {
    bookId: 'bad.id', ratio: 0.2, updatedAt: stamp,
  }));
});

const bookmark = (bookId = 'book_one') => ({
  bookId, ratio: 0.4, label: 'Return here',
  createdAt: stamp, updatedAt: stamp,
});
const note = (bookId = 'book_one') => ({
  bookId, text: 'A personal thought', createdAt: stamp, updatedAt: stamp,
});

test('owner can create, read, update and delete bookmarks and notes', async () => {
  const db = environment.authenticatedContext('reader').firestore();
  const mark = doc(db, 'users/reader/bookmarks/mark_1');
  const memo = doc(db, 'users/reader/notes/note_1');
  await assertSucceeds(setDoc(mark, bookmark()));
  await assertSucceeds(getDoc(mark));
  await assertSucceeds(getDocs(collection(db, 'users/reader/bookmarks')));
  await assertSucceeds(updateDoc(mark, { label: 'Changed', ratio: 0.8 }));
  await assertSucceeds(deleteDoc(mark));
  await assertSucceeds(setDoc(memo, note()));
  await assertSucceeds(getDoc(memo));
  await assertSucceeds(getDocs(collection(db, 'users/reader/notes')));
  await assertSucceeds(updateDoc(memo, { text: 'Edited' }));
  await assertSucceeds(deleteDoc(memo));
});

test('guest and another UID cannot access bookmarks or notes', async () => {
  for (const context of [
    environment.unauthenticatedContext(),
    environment.authenticatedContext('other'),
  ]) {
    const db = context.firestore();
    for (const [path, payload] of [
      ['bookmarks/mark_1', bookmark()],
      ['notes/note_1', note()],
    ]) {
      const ref = doc(db, `users/reader/${path}`);
      await assertFails(getDoc(ref));
      await assertFails(setDoc(ref, payload));
      await assertFails(updateDoc(ref, { updatedAt: stamp }));
      await assertFails(deleteDoc(ref));
    }
    await assertFails(getDocs(collection(db, 'users/reader/bookmarks')));
    await assertFails(getDocs(collection(db, 'users/reader/notes')));
  }
});

test('bookmark and note schemas reject invalid values and extra fields', async () => {
  const db = environment.authenticatedContext('reader', { role: 'admin' }).firestore();
  const mark = doc(db, 'users/reader/bookmarks/mark_1');
  const memo = doc(db, 'users/reader/notes/note_1');
  await assertFails(setDoc(mark, { ...bookmark(), role: 'admin' }));
  await assertFails(setDoc(mark, { ...bookmark(), ratio: -0.1 }));
  await assertFails(setDoc(mark, { ...bookmark(), ratio: 1.1 }));
  await assertFails(setDoc(mark, { ...bookmark(), label: 'x'.repeat(81) }));
  await assertFails(setDoc(mark, bookmark('bad.id')));
  await assertFails(setDoc(doc(db, 'users/reader/bookmarks/bad.id'), bookmark()));
  await assertFails(setDoc(memo, { ...note(), role: 'admin' }));
  await assertFails(setDoc(memo, { ...note(), text: '' }));
  await assertFails(setDoc(memo, { ...note(), text: 'x'.repeat(2001) }));
  await assertFails(setDoc(memo, note('bad.id')));
  await assertSucceeds(setDoc(memo, note()));
  await assertFails(updateDoc(memo, { bookId: 'other' }));
  await assertFails(updateDoc(memo, { createdAt: Timestamp.now() }));
});

test('owner can create, list, update and delete search history', async () => {
  const db = environment.authenticatedContext('reader').firestore();
  const entry = doc(db, 'users/reader/searchHistory/search_1');
  await assertSucceeds(setDoc(entry, { query: 'Moonlight', submittedAt: stamp }));
  await assertSucceeds(getDoc(entry));
  const list = await assertSucceeds(getDocs(collection(db, 'users/reader/searchHistory')));
  assert.equal(list.size, 1);
  await assertSucceeds(updateDoc(entry, { query: 'Ocean', submittedAt: Timestamp.now() }));
  await assertSucceeds(deleteDoc(entry));
});

test('guest and other UID cannot access search history', async () => {
  for (const context of [
    environment.unauthenticatedContext(),
    environment.authenticatedContext('other'),
  ]) {
    const db = context.firestore();
    const entry = doc(db, 'users/reader/searchHistory/search_1');
    await assertFails(getDoc(entry));
    await assertFails(getDocs(collection(db, 'users/reader/searchHistory')));
    await assertFails(setDoc(entry, { query: 'Moonlight', submittedAt: stamp }));
    await assertFails(deleteDoc(entry));
  }
});

test('search history rejects malformed IDs, fields and oversized queries', async () => {
  const db = environment.authenticatedContext('reader').firestore();
  const entry = doc(db, 'users/reader/searchHistory/search_1');
  await assertFails(setDoc(entry, { query: '', submittedAt: stamp }));
  await assertFails(setDoc(entry, { query: 'x'.repeat(101), submittedAt: stamp }));
  await assertFails(setDoc(entry, { query: 42, submittedAt: stamp }));
  await assertFails(setDoc(entry, { query: 'Moonlight', submittedAt: stamp, uid: 'reader' }));
  await assertFails(setDoc(entry, { query: 'Moonlight', submittedAt: 'today' }));
  await assertFails(setDoc(doc(db, 'users/reader/searchHistory/bad.id'), {
    query: 'Moonlight', submittedAt: stamp,
  }));
});

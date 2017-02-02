/* eslint-env mocha */
/* eslint-disable func-names, prefer-arrow-callback */

import { Factory } from 'meteor/dburles:factory';
import { PublicationCollector } from 'meteor/johanbrook:publication-collector';
import { chai, assert } from 'meteor/practicalmeteor:chai';
import { Random } from 'meteor/random';
import { _ } from 'meteor/underscore';
import { Notes } from '../notes.coffee';
import './publications.coffee';

describe('notes', function () {
  describe('mutators', function () {
    it('builds correctly from factory', function () {
      const note = Factory.create('note');
      assert.typeOf(note, 'object');
      assert.typeOf(note.createdAt, 'date');
    });
  });
  it('leaves createdAt on update', function () {
    const createdAt = new Date(new Date() - 1000);
    let note = Factory.create('note', { createdAt });
    const text = 'some new text';
    Notes.update(note, { $set: { text } });
    note = Notes.findOne(note._id);
    assert.equal(note.text, text);
    assert.equal(note.createdAt.getTime(), createdAt.getTime());
  });
  describe('publications', function () {
    let publicNote;
    let privateNote;
    let userId;
    before(function () {
      userId = Random.id();
      publicNote = Factory.create('note');
      privateNote = Factory.create('note', { userId });
      _.times(3, () => {
        Factory.create('note', { noteId: publicNote._id });
        // NOTE get rid of userId, https://github.com/meteor/notes/pull/49
        Factory.create('note', { noteId: privateNote._id, userId });
      });
    });
    describe('notes.inNote', function () {
      it('sends all notes for a public note', function (done) {
        const collector = new PublicationCollector();
        collector.collect(
          'notes.inNote',
          { noteId: publicNote._id },
          (collections) => {
            chai.assert.equal(collections.notes.length, 3);
            done();
          }
        );
      });
      it('sends all notes for a public note when logged in', function (done) {
        const collector = new PublicationCollector({ userId });
        collector.collect(
          'notes.inNote',
          { noteId: publicNote._id },
          (collections) => {
            chai.assert.equal(collections.notes.length, 3);
            done();
          }
        );
      });
      it('sends all notes for a private note when logged in as owner', function (done) {
        const collector = new PublicationCollector({ userId });
        collector.collect(
          'notes.inNote',
          { noteId: privateNote._id },
          (collections) => {
            chai.assert.equal(collections.notes.length, 3);
            done();
          }
        );
      });
      it('sends no notes for a private note when not logged in', function (done) {
        const collector = new PublicationCollector();
        collector.collect(
          'notes.inNote',
          { noteId: privateNote._id },
          (collections) => {
            chai.assert.isUndefined(collections.notes);
            done();
          }
        );
      });
      it('sends no notes for a private note when logged in as another user', function (done) {
        const collector = new PublicationCollector({ userId: Random.id() });
        collector.collect(
          'notes.inNote',
          { noteId: privateNote._id },
          (collections) => {
            chai.assert.isUndefined(collections.notes);
            done();
          }
        );
      });
    });
  });
});


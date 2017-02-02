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
    const title = 'some new text';
    Notes.update(note, { $set: { title } });
    note = Notes.findOne(note._id);
    assert.equal(note.title, title);
    assert.equal(note.createdAt.getTime(), createdAt.getTime());
  });
  describe('publications', function () {
    let publicNote;
    let privateNote;
    let userId;
    before(function () {
      userId = Random.id();
      publicNote = Factory.create('note');
      privateNote = Factory.create('note', { owner: userId });
      _.times(3, () => {
        Factory.create('note', { parent: publicNote._id });
        // NOTE get rid of userId, https://github.com/meteor/notes/pull/49
        Factory.create('note', { parent: privateNote._id, owner: userId });
      });
    });
    describe('notes.children', function () {
      it('sends all notes for a public note', function (done) {
        const collector = new PublicationCollector();
        collector.collect(
          'notes.children',
          publicNote._id,
          (collections) => {
            chai.assert.equal(collections.notes.length, 3);
            done();
          }
        );
      });
      it('sends all notes for a public note when logged in', function (done) {
        const collector = new PublicationCollector({ userId });
        collector.collect(
          'notes.children',
          publicNote._id,
          'ShareKey12',
          (collections) => {
            chai.assert.equal(collections.notes.length, 3);
            done();
          }
        );
      });
      it('sends all notes for a private note when logged in as owner', function (done) {
        const collector = new PublicationCollector({ userId });
        collector.collect(
          'notes.children',
          privateNote._id,
          (collections) => {
            chai.assert.equal(collections.notes.length, 3);
            done();
          }
        );
      });
      it('sends no notes for a private note when not logged in', function (done) {
        const collector = new PublicationCollector();
        collector.collect(
          'notes.children',
          privateNote._id,
          (collections) => {
            chai.assert.deepEqual(collections.notes,[]);
            done();
          }
        );
      });
      it('sends no notes for a private note when logged in as another user', function (done) {
        const collector = new PublicationCollector({ userId: Random.id() });
        collector.collect(
          'notes.children',
          privateNote._id,
          (collections) => {
            chai.assert.deepEqual(collections.notes,[]);
            done();
          }
        );
      });
    });
  });
});


/* eslint-env mocha */
 
import { Meteor } from 'meteor/meteor';
import { Random } from 'meteor/random';
import { assert } from 'meteor/practicalmeteor:chai';

import { Notes } from './notes.coffee';
import './methods.coffee';
 
if (Meteor.isServer) {
  describe('Notes', () => {
    describe('methods', () => {
      const userId = Random.id();
      let noteId;
 
      beforeEach(() => {
        Notes.remove({});
        noteId = Notes.insert({
          text: 'test note',
          createdAt: new Date(),
          owner: userId,
          username: 'tmeasday',
        });
      });
 
      it('can delete owned note', () => {
        // Find the internal implementation of the note method so we can
        // test it in isolation
        const deleteNote = Meteor.server.method_handlers['notes.remove'];
 
        // Set up a fake method invocation that looks like what the method expects
        const invocation = { userId };
 
        // Run the method with `this` set to the fake invocation
        deleteNote.apply(invocation, [noteId]);
 
        // Verify that the method does what we expected
        assert.equal(Notes.find().count(), 0);
      });
    });
  });
}

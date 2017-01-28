import { Mongo } from 'meteor/mongo';
import { Factory } from 'meteor/dburles:factory';
import { SimpleSchema } from 'meteor/aldeed:simple-schema';
import faker from 'faker';
// import incompleteCountDenormalizer from './incompleteCountDenormalizer.js';

class NotesCollection extends Mongo.Collection {
  insert(doc, callback) {
    const ourDoc = doc;
    ourDoc.createdAt = ourDoc.createdAt || new Date();
    const result = super.insert(ourDoc, callback);
    // incompleteCountDenormalizer.afterInsertNote(ourDoc);
    return result;
  }
  update(selector, modifier) {
    const result = super.update(selector, modifier);
    // incompleteCountDenormalizer.afterUpdateNote(selector, modifier);
    return result;
  }
  remove(selector) {
    // const notes = this.find(selector).fetch();
    const result = super.remove(selector);
    // incompleteCountDenormalizer.afterRemoveNotes(notes);
    return result;
  }
}

export const Notes = new NotesCollection('notes');

// Deny all client-side updates since we will be using methods to manage this collection
Notes.deny({
  insert() { return true; },
  update() { return true; },
  remove() { return true; },
});

Notes.schema = new SimpleSchema({
  _id: {
    type: String,
    regEx: SimpleSchema.RegEx.Id,
  },
  parent: {
    type: String,
    regEx: SimpleSchema.RegEx.Id,
    optional: true,
  },
  title: {
    type: String,
    optional: true,
  },
  createdAt: {
    type: Date,
    denyUpdate: true,
  },
  owner: {
    type: String,
    regEx: SimpleSchema.RegEx.Id,
    optional: true
  },
  level: {
    type: Number,
    optional: true
  },

});

Notes.attachSchema(Notes.schema);

// This represents the keys from Lists objects that should be published
// to the client. If we add secret properties to List objects, don't list
// them here to keep them private to the server.
Notes.publicFields = {
  parent: 1,
  title: 1,
  createdAt: 1,
  owner: 1,
  level: 1
};

// NOTE This factory has a name - do we have a code style for this?
//   - usually I've used the singular, sometimes you have more than one though, like
//   'note', 'emptyNote', 'checkedNote'
Factory.define('note', Notes, {
  listId: () => Factory.get('list'),
  title: () => faker.lorem.sentence(),
  createdAt: () => new Date(),
});

Notes.helpers({
  parent() {
    return Notes.findOne(this.parentId);
  },
  children() {
    return Notes.find({ parent: this._id }, { sort: { createdAt: -1 } });
  },
  editableBy(userId) {
    return this.list().editableBy(userId);
  },
});

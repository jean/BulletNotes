/* eslint-env mocha */
/* eslint-disable func-names, prefer-arrow-callback */


import { Mongo } from 'meteor/mongo';
import { Factory } from 'meteor/dburles:factory';
import { chai } from 'meteor/practicalmeteor:chai';
import { Template } from 'meteor/templating';
import { _ } from 'meteor/underscore';
import { $ } from 'meteor/jquery';

import { withRenderedTemplate } from '../../test-helpers.js';
import '../notes-item.js';

import { Notes } from '../../../api/notes/notes.js';

describe('note @watch', function () {
  beforeEach(function () {
    Template.registerHelper('_', key => key);
  });

  afterEach(function () {
    Template.deregisterHelper('_');
  });

  it('renders correctly with simple data @watch', function () {
    const note = Factory.build('note', { checked: false });
    const data = {
      note: Notes._transform(note),
      onEditingChange: () => 0,
    };

    withRenderedTemplate('Notes_item', data, (el) => {
      chai.assert.equal($(el).find('input[type=text]').val(), note.text);
      chai.assert.equal($(el).find('.note-item.checked').length, 0);
      chai.assert.equal($(el).find('.note-item.editing').length, 0);
    });
  });

  it('renders correctly when checked', function () {
    const note = Factory.build('note', { checked: true });
    const data = {
      note: Notes._transform(note),
      onEditingChange: () => 0,
    };

    withRenderedTemplate('Notes_item', data, (el) => {
      chai.assert.equal($(el).find('input[type=text]').val(), note.text);
      chai.assert.equal($(el).find('.note-item.checked').length, 1);
    });
  });

  it('renders correctly when editing', function () {
    const note = Factory.build('note');
    const data = {
      note: Notes._transform(note),
      editing: true,
      onEditingChange: () => 0,
    };

    withRenderedTemplate('Notes_item', data, (el) => {
      chai.assert.equal($(el).find('input[type=text]').val(), note.text);
      chai.assert.equal($(el).find('.note-item.editing').length, 1);
    });
  });

  it('renders correctly with simple data', function () {
    const parent = Factory.build('note');
    const timestamp = new Date();

    // Create a local collection in order to get a cursor
    // Note that we need to pass the transform in so the documents look right when they come out.
    const notesCollection = new Mongo.Collection(null, { transform: Notes._transform });
    _.times(3, (i) => {
      const note = Factory.build('note', {
        noteId: parent._id,
        createdAt: new Date(timestamp - (3 - i)),
      });
      notesCollection.insert(note);
    });
    const notesCursor = notesCollection.find({}, { sort: { createdAt: -1 } });

    const data = {
      note: () => parent,
      notesReady: true,
      notes: notesCursor,
    };

    withRenderedTemplate('Notes_show', data, (el) => {
      const notesText = notesCursor.map(t => t.text);
      const renderedText = $(el).find('.note-items input[type=text]')
        .map((i, e) => $(e).val())
        .toArray();
      chai.assert.deepEqual(renderedText, notesText);
    });
  });
});


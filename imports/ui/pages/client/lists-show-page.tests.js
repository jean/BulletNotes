/* eslint-env mocha */
/* eslint-disable func-names, prefer-arrow-callback */

import { Meteor } from 'meteor/meteor';
import { Factory } from 'meteor/dburles:factory';
import { Random } from 'meteor/random';
import { chai } from 'meteor/practicalmeteor:chai';
import StubCollections from 'meteor/hwillson:stub-collections';
import { Template } from 'meteor/templating';
import { _ } from 'meteor/underscore';
import { $ } from 'meteor/jquery';
import { FlowRouter } from 'meteor/kadira:flow-router';
import { sinon } from 'meteor/practicalmeteor:sinon';


import { withRenderedTemplate } from '/imports/ui/test-helpers.js';
import '../notes-show-page.coffee';

import { Notes } from '/imports/api/notes/notes.coffee';

describe('Notes_show_page', function () {
  const noteId = Random.id();

  beforeEach(function () {
    StubCollections.stub([Notes]);
    Template.registerHelper('_', key => key);
    sinon.stub(FlowRouter, 'getParam', () => noteId);
    sinon.stub(Meteor, 'subscribe', () => ({
      subscriptionId: 0,
      ready: () => true,
    }));
  });

  afterEach(function () {
    StubCollections.restore();
    Template.deregisterHelper('_');
    FlowRouter.getParam.restore();
    Meteor.subscribe.restore();
  });

  it('renders correctly with simple data', function () {
    Factory.create('note', { _id: noteId });
    const timestamp = new Date();
    const notes = _.times(3, i => Factory.create('note', {
      noteId,
      createdAt: new Date(timestamp - (3 - i)),
    }));

    withRenderedTemplate('Notes_show_page', {}, (el) => {
      const notesText = notes.map(t => t.text).reverse();
      const renderedText = $(el).find('.note-items input[type=text]')
        .map((i, e) => $(e).val())
        .toArray();
      chai.assert.deepEqual(renderedText, notesText);
    });
  });
});

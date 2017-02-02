/* eslint-env mocha */
/* eslint-disable func-names, prefer-arrow-callback */

import { Factory } from 'meteor/dburles:factory';
import { chai } from 'meteor/practicalmeteor:chai';
import { Template } from 'meteor/templating';
import { $ } from 'meteor/jquery';
import { Notes } from '/imports/api/notes/notes';


import { withRenderedTemplate } from '/imports/ui/test-helpers.js';
import '/imports/ui/components/note/note.coffee';

describe('Notes_item', function () {
  beforeEach(function () {
    Template.registerHelper('_', key => key);
  });

  afterEach(function () {
    Template.deregisterHelper('_');
  });

  xit('renders correctly with simple data', function () {
    const note = Factory.build('note');
    const data = {
      note: Notes._transform(note),
      onEditingChange: () => 0,
    };

    withRenderedTemplate('note', data, (el) => {
      chai.assert.equal($(el).find('.title').html(), note.title);
      // chai.assert.equal($(el).find('.list-item.checked').length, 0);
      // chai.assert.equal($(el).find('.list-item.editing').length, 0);
    });
  });

  xit('renders correctly when marked done', function () {
    const note = Factory.build('note', { title: 'All #done' });
    const data = {
      note: Notes._transform(note),
      onEditingChange: () => 0,
    };

    withRenderedTemplate('note', data, (el) => {
      chai.assert.equal($(el).hasClass('.tag-done'), 1);
      chai.assert.equal($(el).find('.title').html(), note.title);
    });
  });
});

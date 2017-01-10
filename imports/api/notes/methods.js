// Methods related to links

import { Meteor } from 'meteor/meteor';
import { check } from 'meteor/check';
import { Notes } from './notes.js';

Meteor.methods({
  'notes.insert'(title) {
    check(title, String);

    if (! this.userId) {
      throw new Meteor.Error('not-authorized');
    }

    var nextRank = Notes.find().count() + 1;

    return Notes.insert({
      title,
      createdAt: new Date(),
      rank: nextRank,
      owner: this.userId,
      level: 0
    });
  },
  'notes.update'(id,title,rank) {
    check(title, String);
    check(rank, Number);

    return Notes.update(id,{ $set: {
      rank: rank,
      title: title
    }});
  },
  'notes.updateBody'(id,body) {
    check(body, String);
    
    return Notes.update(id,{ $set: {
      body: body
    }});
  },
  'notes.makeChild'(id,parent) {
    check(parent, String);
    var note = Notes.findOne(id);
    var parent = Notes.findOne(parent);
    console.log(parent,"---",note);
    if (!note || !parent) {
      return false;
    }
    Notes.update(id,{ $set: {
      parent: parent._id,
      level: parent.level+1
    }});

    var children = Notes.find({parent:id});
    children.forEach(function(child) {
      Meteor.call('notes.makeChild',child._id,id);
    });
    
  },
  'notes.remove'(id) {
    check(id, String);
    var children = Notes.find({parent:id});
    children.forEach(function(child) {
      Meteor.call('notes.remove',child._id);
    });
    Notes.remove(id);
  },
  'notes.outdent'(id) {
    var note = Notes.findOne(id);
    var parent = Notes.findOne(note.parent);
    parent = Notes.findOne(parent.parent);
    if (parent) {
      Meteor.call('notes.makeChild',note._id,parent._id);
    } else {
      // No parent left to go out to, set things to top level.
      var children = Notes.find({parent:note._id});
      children.forEach(function(child) {
        Notes.update(child._id,{$set:{level: 1}});
      });

      return Notes.update(id,{ $set: {
        level: 0,
        parent: null
      }});
    }

  }
});

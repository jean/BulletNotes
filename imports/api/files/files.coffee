import { Mongo } from 'meteor/mongo'
import { Factory } from 'meteor/dburles:factory'
import SimpleSchema from 'simpl-schema'
import faker from 'faker'

export Files = new Mongo.Collection 'files'

# Deny all client-side updates since we will
# be using methods to manage this collection
Files.deny
  insert: -> yes
  update: -> yes
  remove: -> yes


Files.schema = new SimpleSchema
  _id:
    type: String
    regEx: SimpleSchema.RegEx.Id
    optional: yes
  noteId:
    type: String
    regEx: SimpleSchema.RegEx.Id
  data:
    type: String
  uploadedAt:
    type: Date
  owner:
    type: String
    regEx: SimpleSchema.RegEx.Id

Files.attachSchema Files.schema

# This represents the keys from Notes objects that should be published
# to the client. If we add secret properties to Note objects, don't note
# them here to keep them private to the server.
Files.publicFields =
  noteId: 1
  data: 1
#
# # NOTE This factory has a name - do we have a code style for this?
# #   - usually I've used the singular, sometimes you have more than one though, like
# #   'note', 'emptyNote', 'checkedNote'
# Factory.define 'note', Notes,
#   title: ->
#     faker.lorem.sentence()
#
#   createdAt: ->
#     new Date()
#
# Notes.helpers
#   note: ->
#     Notes.findOne @noteId
#
#   editableBy: (userId) ->
#     @note().editableBy userId

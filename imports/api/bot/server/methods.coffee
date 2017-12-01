pjson = require('/package.json')

import { Meteor } from 'meteor/meteor'
import { Random } from 'meteor/random';

import { _ } from 'meteor/underscore'
import { ValidatedMethod } from 'meteor/mdg:validated-method'
import SimpleSchema from 'simpl-schema'
import { DDPRateLimiter } from 'meteor/ddp-rate-limiter'

import { Notes } from '/imports/api/notes/notes.coffee'
import childCountDenormalizer from '/imports/api/notes/childCountDenormalizer.coffee'

unless localStorage?
  {LocalStorage} = require('node-localstorage')

Bot = {}

Bot.maxTitleLength = 100
Bot.maxMobileTitleLength = 80
Bot.maxNoteReturn = 100
Bot.defaultLimit = 9

Bot.formatNote = (note, mobileFormat) ->
  if note.title
    title = note.title.replace(/(<([^>]+)>|:|_)/ig, " ")
  if mobileFormat
    if title
      if title.length > Bot.maxTitleLength
        title = title.substr(0,Bot.maxMobileTitleLength) + '...'
      title
    else
      '_( Empty Note )_'
  else
    if title
      if title.length > Bot.maxTitleLength
        title = title.substr(0,Bot.maxTitleLength) + '...'
      title + ' - ' + Meteor.settings.public.url + '/note/' + note._id
    else
      '_( Empty Note )_ - ' + Meteor.settings.public.url + '/note/' + note._id

Bot.formatNotes = (notes, limitMultiplier, mobileFormat) ->
  if notes.count()
    ii = 1
    noteIds = []
    notes = notes.fetch()

    showNextPage = false

    if notes.length > Bot.defaultLimit * limitMultiplier
      # There are more notes to scroll to, show the next page option
      showNextPage = true
      notes.pop()

    notes = notes.slice(Bot.defaultLimit * -1)
    msg = ''
    if limitMultiplier > 1
      msg = msg + '`-1` - _( Previous Notes )_\n'
    if showNextPage
      msg = msg + '`0` - _( More Notes )_\n'

    msg = msg + '\n'

    for note in notes
      childCount = note.children || 0
      msg = msg + '`' + ii + '` - ' + '_[' + childCount + ']_ - ' + Bot.formatNote(note, mobileFormat) + '\n'
      ii++

  else
    msg = '_( No Notes )_\n'

  msg

Bot.generateNoteIds = (notes, limitMultiplier) ->
  noteIds = []
  notes = notes.fetch()
  if notes.length > Bot.defaultLimit * limitMultiplier
    notes.pop()
  notes = notes.slice(Bot.defaultLimit * -1)
  for note in notes
    noteIds.push note._id
  noteIds

Bot.getNoteRange = (conversation) ->
  (Bot.defaultLimit * (conversation.limitMultiplier-1) + 1)+'-'+(Bot.defaultLimit * (conversation.limitMultiplier))

Bot.getRecent = (limit,user) ->
  if limit
    limit = Math.min Bot.maxNoteReturn, limit
  else
    limit = Bot.defaultLimit

  notes = Notes.find({owner:user._id,deleted:{$exists: false}},{sort:{createdAt:-1},limit:limit})

  msg = 'Here are your most recent '+limit+' notes:\n\n'
  ii = 1
  notes.forEach (note) ->
    msg = msg + '*' + ii + '* - ' + Bot.formatNote(note,user.telegramBotMobileFormat) + '\n'
    ii++
  msg

Bot.isYes = (command) ->
  if command
    if command.toLowerCase() == 'y' || command.toLowerCase() == 'yes'
      true

Bot.deleteNote = (noteId) ->
  note = Notes.findOne noteId
  Notes.update note._id, $set:
      deleted: new Date()

  if note
    childCountDenormalizer.afterInsertNote note.parent

  msg = '`Note deleted successfully!` - ' + Bot.formatNote(note,false) + '\n\n'

# Actual chat method

export chat = new ValidatedMethod
  name: 'bot.chat'
  validate: new SimpleSchema
    chat:
      type: String
    userId:
      type: String
      regEx: SimpleSchema.RegEx.Id
      optional: true
    apiKey:
      type: String
      optional: true
  .validator
    clean: yes
    filter: no
  run: ({ chat, userId = null, apiKey = null }) ->
    command = chat.split ' '
    if !command[0]
      false

    if userId
      user = Meteor.users.findOne userId
    else if apiKey
      user = Meteor.users.findOne apiKey:apiKey
      if !user
        return 'Bad API Key Provided. Get a new one at ' + Meteor.settings.public.url + 'settings'
    else
      user = Meteor.user()

    if !user
      return 'Please login. You can register at ' + Meteor.settings.public.url + ' or chat me on Telegram at @BulletNotesBot'

    conversation = new LocalStorage('./conversations'+user._id)

    # Check for an active conversation

    if conversationCommand = conversation.getItem 'command'
      limitMultiplier = conversation.getItem('limitMultiplier') || 1
      switch conversationCommand

        when 'delete'
          if command[0] == "0"
            # Advance pagination
            if limitMultiplier < 10
              limitMultiplier = limitMultiplier + 1
              conversation.setItem 'limitMultiplier', limitMultiplier
              command[0] = "/delete"
            else
              msg = 'Sorry that is all the notes I can show you. Try searching with `/find stuff` or browsing with `/browse`.\n\n'
          else 
            deleteId = conversation.getItem('deleteId')
            noteIds = conversation.getItem('noteIds')

            if noteIds
              noteIds = noteIds.split ','
            
            # If we have a '# y', delete it right away
            if (deleteId && Bot.isYes chat) || (command.length == 2 && Bot.isYes command[1])
              deleteId = deleteId || noteIds[command[0]-1]
              msg = Bot.deleteNote deleteId
              msg = msg + Bot.getRecent Bot.defaultLimit, user
              conversation.clear()

            # Otherwise get confirmation
            else if !deleteId
              if noteSelected = parseInt chat, 10
                note = Notes.findOne noteIds[noteSelected-1]
                conversation.setItem 'deleteId', note._id

                msg = 'Selected note: ' + Bot.formatNote(note,user.telegramBotMobileFormat) + ' - *Really delete it?* `(Y)es`/`(N)o`'
              else
                msg = '`Delete note cancelled`.\n\n'
                msg = msg + Bot.getRecent Bot.defaultLimit, user
                conversation.clear()
            else
              msg = '`Delete note cancelled.`\n\n'
              msg = msg + Bot.getRecent Bot.defaultLimit, user
              conversation.clear()
    else
      limitMultiplier = 1

    # We don't have a conversation going, move on to the commands

    if !msg
      switch command[0]
        when '/help', '/h'
          if command.length < 2
            msg = 'Hi, I\'m *BulletNotesBot*!\n'
            msg = msg + 'I have the following commands available:\n\n'
            
            msg = msg + '`/delete` `/del` `/d` - Delete a note.\n'
            msg = msg + '`/edit` `/e` - Edit a note.\n'
            msg = msg + '`/find (term)` `/f` - Search your notes.\n'
            msg = msg + '`/mobile` - Toggle mobile formatting of results.\n'
            msg = msg + '`/recent` `/r` - Show your newest notes.\n'
            msg = msg + '`/stats` `/s` - Get stats on your BulletNotes usage.\n'
            msg = msg + '`/support` - Detailed support information.\n'

            msg = msg + '\nType `/help command` to get more information about it.'
          else
            switch command[1]
              when 'delete', '/delete', '/del', '/d', 'd'
                msg = '`Delete Note`\n\n'
                msg = msg + 'This command can be used several ways to delete a specific note.\n\n'
                msg = msg + '`/delete` - Returns your 9 most recent notes for you to choose which one to delete.\n'
                msg = msg + '`/delete 2` - Ask to delete your second most recent note. This is a shortcut if you already know the recent number of the note you want to delete.\n'
                msg = msg + '`/delete 2 y` - If you are really sure you know which note is the second to last note, adding a `y` to the end will skip the confirmation.\n'
                msg = msg + '`/delete search` - Returns 9 most recent notes containing the search query for you to choose which one to delete.\n'

                msg = msg + '\n`/delete` `/del` or `/d` may be used interchangeably.'

              when 'edit', '/edit', '/e', 'e'
                msg = '`Edit Note`\n\n'
                msg = msg + 'This command can be used several ways to edit a specific note.'
                msg = msg + '`/edit` - Returns your 9 most recent notes for you to choose which one to edit.\n'
                msg = msg + '`/edit 2` - Ask to edit your second most recent note. This is a shortcut if you already know the recent number of the note you want to edit.\n'
                msg = msg + '`/edit 2 New Text` - Adding the edit text after the note number will update the note without needing a confirmation.\n'
                msg = msg + '`/edit search` - Returns 9 most recent notes containing the search query for you to choose which one to edit.\n'

                msg = msg + '\n`/edit` or `/e` may be used interchangeably.'

              when 'find', '/find', '/f', '/search', 'f', 'search'
                msg = '`Find Notes`\n\n'
                msg = msg + 'This command is used to find notes.\n\n'
                msg = msg + '`/find search query` - Returns your 9 most recent notes containing the search query.\n'

                msg = msg + '\n`/find` `/f` or `/search` may be used interchangeably.'

              when 'mobile', '/mobile'
                msg = '`Mobile Mode`\n\n'
                msg = msg + 'Toggles whether to receive note summaries for mobile, or more detailed results for desktop use.'

              when 'recent', '/recent', '/r', 'r'
                msg = '`Recent Notes`\n\n'
                msg = msg + 'This command is used to view recent notes.\n\n'
                msg = msg + '`/recent 25` - Returns your 25 most recent notes.\n'

                msg = msg + '\n`/recent` or `/r` may be used interchangeably.'

              when 'stats', '/stats', '/s', 's'
                msg = '`Statistics`\n\n'
                msg = msg + 'Mostly for fun. ;)'

                msg = msg + '\n`/stats` or `/s` may be used interchangeably.'

              when 'support', '/suuport'
                msg = '`Support`\n\n'
                msg = msg + 'How to get help from BulletNotes community and staff.'

        when '/support'
            msg = 'BulletNotes Version: ' + pjson.version + '\n'
            msg = msg + 'Build Date: ' + pjson.releaseDate + '\n\n'
            msg = msg + 'https://bulletnotes.io\n\nSupport: `http://bulletnotes.helpy.io/admin/topics`\nTweet at us: `https://twitter.com/BulletNotes_io`'

        when '/stats', '/s'
          today = new Date
          date_to_reply = new Date(user.createdAt)
          millis = date_to_reply.getTime() - today.getTime()
          days = Math.ceil(millis / (1000 * 60 * 60 * 24)) * -1
          noteCount = user.notesCreated || 0
          notesDay = (Math.round(noteCount / days * 100) * .01 || 0)

          if user.telegramBotMobileFormat
            mobileStatus = 'You are viewing `mobile` formatted results. (`/mobile` to toggle)'
          else
            mobileStatus = 'You are viewing `detailed` results. (`/mobile` to toggle)'

          msg = mobileStatus + '\n' +
          'Your account was created `' + moment(user.createdAt).fromNow() + '. 📆`\n'+
          'Since then you have created `' + noteCount + '` notes. 😎\n'+
          'That is `' + notesDay + '` notes a day! 👍\n'+
          'We have talked `' + user.telegramBotUseCount + '` times so far. ❤️\n'+
          'Keep up the great work, and thanks for using BulletNotes! 😄'

        when '/mobile'
          if !user.telegramBotMobileFormat
            Meteor.users.update user._id, $set:
              telegramBotMobileFormat:true
            msg = 'Now showing shorter (mobile-friendly) results. Type `/mobile` again to toggle back.'
          else
            Meteor.users.update user._id, $set:
              telegramBotMobileFormat:false
            msg = 'Now showing more detailed results. Type `/mobile` again to toggle back.'

        when '/find', '/f', '/search'
          # If a limit is not provided as the first param, use 10
          if command.length < 2
            msg = 'You must provide a search term. Example: `/find #work`'
          else
            # Drop the /find from the command
            command.shift()
            searchTerm = command.join(' ')
            notes = Notes.search searchTerm, user._id, Bot.defaultLimit

            msg = 'Here are your search results:\n\n'
            ii = 1
            notes.forEach (note) ->
              title = Bot.formatNote note

              # Highlight search terms
              regex = new RegExp searchTerm, 'gi'
              title = title.replace regex, '`$&`'

              msg = msg + '*' + ii + '* - ' + title + '\n'
              ii++

        when '/recent', '/r'

          # If a limit is not provided as the first param, use the default
          msg = Bot.getRecent command[1], user

        when '/delete', '/del', '/d'
          # We add one to the default limit to enable pagining
          notes = Notes.find({owner:user._id,deleted:{$exists: false}},{sort:{createdAt: -1},limit:Bot.defaultLimit * limitMultiplier + 1})
          noteIds = Bot.generateNoteIds notes, limitMultiplier
          if command.length < 2
            # We don't have a search param, grab the most recent notes

            msg = Bot.formatNotes notes, user.telegramBotMobileFormat

            msg = msg + '\n`Reply` with the number of the note you want to delete, or reply with `(N)o` to cancel.'
            noteIds = Bot.generateNoteIds notes, limitMultiplier
            conversation.setItem 'command', 'delete'
            conversation.setItem 'noteIds', noteIds

          else

            # We have params, if the first is a number, select that note.
            noteSelected = parseInt command[1], 10
            if noteSelected && note = Notes.findOne noteIds[noteSelected-1]
              # We have a note, if there is a second param of yes, just delete it now
              if Bot.isYes command[2]
                msg = Bot.deleteNote note._id
                msg = msg + Bot.getRecent Bot.defaultLimit, user

              # No yes, confirm deletion
              else
                conversation.setItem 'command', 'delete'
                conversation.setItem 'deleteId', note._id
                msg = 'Selected note: ' + Bot.formatNote(note,user.telegramBotMobileFormat) + ' - *Really delete it?* `(Y)es`/`(N)o`'

            else
              # We do have a search, find recent notes matching the search
              command.shift()
              searchTerm = command.join(' ')
              notes = Notes.search searchTerm, user._id, Bot.defaultLimit
              msg = 'Here are your most recent '+Bot.defaultLimit+' notes containing `' + searchTerm + '`:\n\n'

              noteIds = Bot.generateNoteIds notes, limitMultiplier
              msg = msg + Bot.formatNotes notes, user.telegramBotMobileFormat

              msg = msg + '\n`Reply` with the number of the note you want to delete, or reply with `(N)o` to cancel.'

              if searchTerm
                regex = new RegExp searchTerm, 'gi'
                msg = msg.replace regex, '*$&*'

              conversation.setItem 'command', 'delete'
              conversation.setItem 'noteIds', noteIds




        when '/edit', '/e'
          if command.length < 2
            # We don't have a search param, grab the most recent notes
            notes = Notes.find({owner:user._id,deleted:{$exists: false}},{sort:{createdAt:-1},limit:Bot.defaultLimit+1})

            msg = 'Here are your most recent '+Bot.defaultLimit+' notes:\n\n'
          else
            # We do have a search, find recent notes matching the search
            command.shift()
            searchTerm = command.join(' ')
            notes = Notes.search searchTerm, user._id, Bot.defaultLimit+1
            msg = 'Here are your most recent '+Bot.defaultLimit+' notes containing `' + searchTerm + '`:\n\n'

          noteIds = Bot.generateNoteIds notes, limitMultiplier
          msg = msg + Bot.formatNotes notes, user.telegramBotMobileFormat
          
          msg = msg + '\n`Reply` with the number of the note you want to edit, or reply with `(N)o` to cancel.'

          if searchTerm
            regex = new RegExp searchTerm, 'gi'
            msg = msg.replace regex, '`$&`'

        # Extras

        when '/random'
          msg = Math.round(Math.random()*100)


        # End Switch

    # If we got a chat from a function above, send that.
    if msg
      msg
    # Otherwise add the chat as a note to the Inbox
    else
      noteId = Meteor.call 'notes.inbox',
        title: chat
        userId: user._id

      msg = '`Note Saved!` ' + Bot.formatNote({_id:noteId,title:chat}, false) + '\n\n'
      msg = msg + Bot.getRecent Bot.defaultLimit, user
      msg



    #   # Start the conversation
    #   Bot.startConversation username, data.chat.id, ((username, chat, chat_id) ->
    #     conversation = _.find(Bot.conversations[chat_id], (conversation) ->
    #       conversation.username == username
    #     )
    #     if !conversation.editId

    #       # We haven't picked what to edit yet
    #       noteSelected = parseInt chat, 10
    #       if noteSelected > 0
    #         command = chat.split ' '

    #         # We have an edit included, apply that right away
    #         if command.length > 1
    #           command.shift()
    #           title = command.join ' '
    #           Notes.update conversation.noteIds[noteSelected-1], $set:
    #             title: title
    #           note = Notes.findOne conversation.noteIds[noteSelected-1]
    #           Bot.send 'Note edited successfully! ' + Bot.formatNote(note,user.telegramBotMobileFormat), chat_id
    #           Bot.endConversation username, chat_id

    #         # No included edit, return the full note text to be edited
    #         else
    #           note = Notes.findOne conversation.noteIds[noteSelected-1]
    #           conversation.editId = note._id
    #           msg = 'Current note text: ' + note.title + '\n\n`Reply` with the updated text you would like.'
    #           Bot.send msg, chat_id, true
    #       else if chat == "0" || chat == "-1"
    #         # They have opted to view the next page
    #         msg = ''
    #         if chat == "0"
    #           if conversation.limitMultiplier < 10
    #             conversation.limitMultiplier = conversation.limitMultiplier + 1
    #           else
    #             msg = 'Sorry that is all the notes I can show you. Try searching with `/find stuff` or browsing with `/browse`.\n\n'
    #         # Load the previous page
    #         else
    #           if conversation.limitMultiplier > 0
    #             conversation.limitMultiplier = conversation.limitMultiplier - 1
    #           else
    #             msg = 'Already at the first note.\n\n'

    #         if searchTerm
    #           msg = msg + 'Here are '+Bot.getNoteRange(conversation)+' of your most recent notes containing `' + searchTerm + '`:\n\n'
    #           notes = Notes.search searchTerm, user._id, Bot.defaultLimit * conversation.limitMultiplier + 1
    #         else
    #           msg = msg + 'Here are '+Bot.getNoteRange(conversation)+' of your most recent notes:\n\n'
    #           notes = Notes.find({owner:user._id,deleted:{$exists: false}},{sort:{createdAt:-1},limit:Bot.defaultLimit * conversation.limitMultiplier + 1})

    #         conversation.noteIds = Bot.generateNoteIds notes, conversation.limitMultiplier
    #         msg = msg + Bot.formatNotes notes, conversation.limitMultiplier

    #         msg = msg + '\n`Reply` with the number of the note you want to edit, or reply with `(N)o` to cancel.'

    #         if searchTerm
    #           regex = new RegExp searchTerm, 'gi'
    #           msg = msg.replace regex, '`$&`'
    #         Bot.send msg, chat_id, true
    #       else
    #         Bot.send 'Edit note cancelled.', chat_id
    #         Bot.endConversation username, chat_id
    #     else          
    #       Notes.update conversation.editId, $set:
    #         title: chat
    #       note = Notes.findOne conversation.editId
    #       Bot.send 'Note edited successfully! ' + Bot.formatNote(note,user.telegramBotMobileFormat), chat_id
    #       Bot.endConversation username, chat_id
    #   ),
    #     noteIds: noteIds
    #     limitMultiplier: 1

    #   # The return in this listener will be the first prompt
    #   msg

    # Bot.addListener '/browse', (command, username, data) ->
    #   user = Bot.getUser data
    #   if !user
    #     return false

    #   notes = Notes.find({owner:user._id,deleted:{$exists: false},parent:null},{sort:{rank:1},limit:Bot.defaultLimit + 1})

    #   msg = 'Reply with the number `#` of the note you want to zoom into, `(N)ew` to create a new note, `(E)dit #` to edit a note, `(D)elete #` to delete a note, or `E(x)it` to exit browse mode.\n\n'

    #   msg = msg + 'Here are your top level notes: \n\n'

    #   noteIds = Bot.generateNoteIds notes, 1

    #   msg = msg + Bot.formatNotes notes, 1, user.telegramBotMobileFormat


    #   # Start the conversation
    #   Bot.startConversation username, data.chat.id, ((username, chat, chat_id) ->
    #     conversation = _.find(Bot.conversations[chat_id], (conversation) ->
    #       conversation.username == username
    #     )

    #     conversation.noteIds = Bot.generateNoteIds notes, conversation.limitMultiplier
    #     msg = ''
    #     command = chat.split ' '

    #     # Handle note creation
    #     if conversation.creatingNote
    #       conversation.creatingNote = false
    #       noteId = Meteor.call 'notes.insert',
    #         title: chat
    #         parent: conversation.lastNoteId
    #         ownerId: user._id
    #         rank: 0
    #       Bot.send 'Note Saved! ' + Bot.formatNote({_id:noteId,title:chat},user.telegramBotMobileFormat), data.chat.id, true
    #       createdNote = true

    #     # Handle note deletion
    #     if conversation.deleteId
    #       if chat.toLowerCase() == 'y' || chat.toLowerCase() == 'yes'
    #         Notes.update conversation.deleteId, $set:
    #             deleted: new Date()
    #         msg = 'Note deleted successfully.\n\n'
    #       else
    #         msg = 'Delete note cancelled.\n\n'

    #       conversation.deleteId = null
    #       deletedNote = true

    #     # Handle note editing
    #     if conversation.editId
    #       Notes.update conversation.editId, $set:
    #         title: chat
    #       note = Notes.findOne conversation.editId
    #       Bot.send 'Note edited successfully! ' + Bot.formatNote(note,user.telegramBotMobileFormat), chat_id

    #       conversation.editId = null
    #       editedNote = true

    #     msg = msg + '\n`Reply` with the number `#` of the note you want to zoom into, `(U)p` to go up a level, `(N)ew` to create a new note, `(E)dit #` to edit a note, `(D)elete #` to delete a note, or `E(x)it` to exit browse mode.\n\n'

    #     noteSelected = parseInt chat, 10
    #     # Load the parent note based on various conditions
    #     if noteSelected > 0
    #       note = Notes.findOne conversation.noteIds[noteSelected-1]
    #       conversation.currentNoteId = note._id
    #     else if chat == "-1"
    #       if conversation.limitMultiplier > 0
    #         conversation.limitMultiplier = conversation.limitMultiplier - 1
    #       else
    #         msg = 'Already at the first note.\n\n'
    #       note = Notes.findOne conversation.lastNoteId
    #     else if chat == "0"
    #       if conversation.limitMultiplier < 10
    #         conversation.limitMultiplier = conversation.limitMultiplier + 1
    #       else
    #         msg = 'Sorry that is all the notes I can show you.. Try searching with `/find stuff` or browsing with `/browse`.\n\n'
    #       note = Notes.findOne conversation.lastNoteId
    #     else if chat.toLowerCase() == 'u' || chat.toLowerCase() == 'up'
    #       conversation.limitMultiplier = 1
    #       lastNote = Notes.findOne conversation.lastNoteId
    #       if lastNote
    #         note = Notes.findOne lastNote.parent
    #       else
    #         # Just show the same note set again
    #         note = Notes.findOne conversation.lastNoteId
    #         msg = 'Already at the top level!\n\n'
    #     # We have to make sure we didn't try and delete a note here, because if we picked No, n, it would trigger this.
    #     else if !deletedNote && (command[0].toLowerCase() == 'n' || command[0].toLowerCase() == 'new')
    #       if command.length < 2
    #         conversation.creatingNote = true
    #         Bot.send 'Send your new note!', chat_id
    #         return false
    #       else
    #         command.shift()
    #         noteId = Meteor.call 'notes.insert',
    #           title: command.join ' '
    #           parent: conversation.lastNoteId
    #           ownerId: user._id
    #           rank: 0
    #         Bot.send 'Note Saved! ' + Bot.formatNote({_id:noteId,title:chat},user.telegramBotMobileFormat), data.chat.id, true

    #         # Just show the same note set again
    #         note = Notes.findOne conversation.lastNoteId
    #     else if command[0].toLowerCase() == 'd' || command[0].toLowerCase() == 'delete'
    #       if command.length > 1 && noteSelected = parseInt command[1], 10
    #         # If we have a third param, and that is 'y', delete without confirmation
    #         if command.length == 3 && command[2] == "y"
    #           note = Notes.findOne conversation.noteIds[noteSelected-1]
    #           Notes.update note._id, $set:
    #               deleted: new Date()

    #           if note
    #             childCountDenormalizer.afterInsertNote note.parent

    #           msg = 'Note deleted successfully.\n\n'
    #           # Just show the same note set again
    #           note = Notes.findOne conversation.lastNoteId
    #         # Otherwise get confirmation
    #         else
    #           note = Notes.findOne conversation.noteIds[noteSelected-1]
    #           conversation.deleteId = note._id
    #           msg = 'Selected note: ' + Bot.formatNote(note,user.telegramBotMobileFormat) + ' - *Really delete it?* `(Y)es`/`(N)o`'
    #           Bot.send msg, chat_id, true
    #           return false
    #       else
    #         msg = 'You must specify a note number. Example: `d 5`\n\n'
    #     else if command[0].toLowerCase() == 'e' || command[0].toLowerCase() == 'edit'
    #       if command.length > 1 && noteSelected = parseInt command[1], 10
    #         # We have params after the number, save that as the note
    #         if command.length > 2
    #           command = command.slice 2
    #           editId = conversation.noteIds[noteSelected-1]
    #           title = command.join ' '
    #           Notes.update editId, $set:
    #             title: title
    #           note = Notes.findOne conversation.editId
    #           Bot.send 'Note edited successfully! ' + Bot.formatNote({_id:editId,title:title},user.telegramBotMobileFormat), chat_id
    #           # Just show the same note set again
    #           note = Notes.findOne conversation.lastNoteId
    #         else
    #           note = Notes.findOne conversation.noteIds[noteSelected-1]
    #           conversation.editId = note._id
    #           msg = 'Current note text: `' + note.title + '`\n\n`Reply` with the updated text you would like.'
    #           Bot.send msg, chat_id, true
    #           return false
    #       else
    #         msg = 'You must specify a note number. Example: `e 5`\n\n'
    #     else if createdNote || deletedNote || editedNote
    #       # Just show the same note set again
    #       note = Notes.findOne conversation.lastNoteId
    #     else
    #       Bot.send 'Exited browse mode.', chat_id
    #       Bot.endConversation username, chat_id
    #       return false

    #     if note
    #       conversation.lastNoteId = note._id
    #       msg = msg + 'Here are the child notes of ' + Bot.formatNote(note,user.telegramBotMobileFormat) + ': \n\n'
    #     else
    #       conversation.lastNoteId = null
    #       msg = msg + 'Here are your top level notes: \n\n'

    #     # We add + 1 to this for pagination purposes. So formatNotes can detect if there are more notes to be shown.
    #     notes = Notes.find({owner:user._id,deleted:{$exists: false},parent:conversation.lastNoteId},{sort:{rank:1},limit:Bot.defaultLimit * conversation.limitMultiplier + 1})

    #     msg = msg + Bot.formatNotes notes, conversation.limitMultiplier, user.telegramBotMobileFormat

    #     conversation.noteIds = noteIds
    #     Bot.send msg, chat_id, true 
    #   ),
    #     noteIds: noteIds
    #     lastNoteId: null
    #     limitMultiplier: 1

    #   # The return in this listener will be the first prompt
    #   msg












    msg

NOTES_METHODS = _.pluck([
  chat
], 'name')

if Meteor.isServer
  # Only allow 5 bot operations per connection per 10 seconds
  DDPRateLimiter.addRule {
    name: (name) ->
      _.contains NOTES_METHODS, name

    # Rate limit per connection ID
    connectionId: ->
      yes

  }, 5, 10000

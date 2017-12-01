import { Accounts } from 'meteor/accounts-base'

if Meteor.isServer
  Meteor.startup ->
    TelegramBot.token = Meteor.settings.telegramKey
    TelegramBot.start()

    TelegramBot.getUser = (data) ->
      user = Meteor.users.findOne({telegramId:data.chat.id.toString()})
      if !user
        msg = 'Hello, I am BulletNotesBot! 😄 \n\nI can help you manage your notes for free.\n\n' +
        'To get started just type `/register`.\n\n'+
        'Or to link your existing BulletNotes account, click here: ' + 
        Meteor.settings.public.url + '/telegramAuth/' + data.chat.id

        TelegramBot.send msg, data.chat.id, true

        false
      else
        Meteor.users.update user._id, $inc:
          telegramBotUseCount:1

        user

    # Listeners

    TelegramBot.setCatchAllText true, (_, message) ->
      user = TelegramBot.getUser message
      if !user
        return false

      Meteor.call 'bot.chat',
        chat: message.text
        userId: user._id
      , (err, res) ->
        TelegramBot.send res, message.chat.id, true

    TelegramBot.addListener '/start', (command, username, data) ->
      user = TelegramBot.getUser data
      if user
        'Your account is linked. Simply send me any note like `Walk the dog` to get started. Type `/help` for more commands.\n'+
        'The `/browse` and `/recent` commands are worth exploring.'


    TelegramBot.addListener '/register', (command, username, data) ->
      user = Meteor.users.findOne({telegramId:data.chat.id.toString()})
      if !user
        Meteor.users.insert
          telegramId: data.chat.id.toString()
          telegramSignUp: true
          createdAt: new Date()

        'You are good to go! Just send me any note you want to rememeber or get done, like `Fix flat tire`.\n\n'+
        'The `/help` command is always there for you if you need it.\n\n'+
        'Welcome to BulletNotes.io! 👍 😎\n\n'+
        '(To link your email later so you can login to the website run `/email`.)'

    TelegramBot.addListener '/email', (command, username, data) ->
      user = TelegramBot.getUser data
      if !user
        false

      email = command[1]

      emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/

      # ` 'Fix' for dumb Sublimetext syntax highlihting

      if emailRegex.test email
        Accounts.addEmail user._id, email

        'Alright, you can now request a password for the website here: ' + Meteor.settings.public.url + '/forgot-password'
      else
        'Please provide a valid email.'

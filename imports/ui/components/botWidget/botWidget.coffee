require './botWidget.jade'

Template.botWidget.onRendered ->
  $('.botChat').linkify()

Template.botWidget.events
  'click #closeBotWidget': (event, instance) ->
    Session.set 'showBotWidget', false

  'keypress #chatInput': (event, instance) ->
    if event.keyCode == 13
      message = $(event.currentTarget).val()
      Meteor.call 'bot.chat',
        chat: message
      , (err, res) ->
        converter = new Showdown.converter()
        formattedRes = res.replace(/(?:\r\n|\r|\n)/g, '<br />')
        formattedRes = converter.makeHtml formattedRes

        $('.botPending').last().html(formattedRes).removeClass('botPending')
        $("#chatArea").animate({ scrollTop: $("#chatArea")[0].scrollHeight }, 200)

      $('#chatArea').append('<div class="chat userChat">'+message+'</div>')
      $('#chatArea').append('<div class="chat botChat botPending">...</div>')
      $(event.currentTarget).val('')
      $("#chatArea").animate({ scrollTop: $("#chatArea")[0].scrollHeight }, 200)

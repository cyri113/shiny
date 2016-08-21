mandrill = require('mandrill-api/mandrill')
client = new (mandrill.Mandrill)(process.env.MANDRILL_API_KEY)
async = require('async')
moment = require('moment')

console.log 'Mandrill API Loaded'

module.exports =
  welcome: (user, next) ->
    template = 'shiny-account-activation'
    message =
      to: [ {
        email: user.email
        type: 'to'
      } ]
    EmailService.sendTemplate template, null, message, (err) ->
      console.log 'Got a Mandrill response.'
      return next err
    return

  confirmation: (order, user, next) ->
    template: 'shiny-order-confirmation'

    if order.address.email == user.email
      to = [{
        email: user.email
        type: 'to'
      }]
    else
      to = [
        { email: user.email, type: 'to' }
        { email: order.address.email, type: 'to' }
      ]

    items = []

    async.each ['BED','BAT','IRO','WIN'], (sku, done) ->
      order.getItem sku, (item) ->
        items[sku] = item
        return done()
      return
    , (err) ->
      throw err if err
      message =
        to: to
        global_merge_vars: [
          {
            name: 'BEDROOMS'
            content: items['BED']
          }
          {
            name: 'BATHROOMS'
            content: items['BAT']
          }
          {
            name: 'IRON'
            content: items['IRO']
          }
          {
            name: 'WINDOWS'
            content: items['WIN']
          }
          {
            name: 'DATE'
            content: moment(order.schedule.date).format('dd, Mo MMM YYYY')
          }
          {
            name: 'TIME'
            content: moment(order.schedule.time).format('HH:mm')
          }
          {
            name: 'RULE'
            content: order.schedule.rule.name
          }
          {
            name: 'PRICE'
            content: order.total_price
          }
          {
            name: 'FULL_NAME'
            content: order.address.first_name + ' ' + order.address.last_name
          }
          {
            name: 'EMAIL'
            content: order.address.email
          }
          {
            name: 'TELEPHONE'
            content: order.address.telephone
          }
          {
            name: 'HOUSE'
            content: order.address.house || null
          }
          {
            name: 'HOUSING'
            content: order.address.housing || null
          }
          {
            name: 'BUILDING'
            content: order.address.building || null
          }
          {
            name: 'APARTMENT'
            content: order.address.apartment || null
          }
          {
            name: 'STEET'
            content: order.address.street
          }
          {
            name: 'NOTES'
            content: order.address.note
          }
        ]

      EmailService.sendTemplate template, null, message, (err) ->
        console.log 'Got a Mandrill response.'
        return next err
      return
    return

  sendTemplate: (name, content, message, next) ->
    ip_pool = 'Main Pool'

    try
      client.messages.sendTemplate
        'template_name': name
        'template_content': content
        'message': message
        'async': false
        'ip_pool': ip_pool
      , (res) ->
        return next(null, res)
      , (err) ->
        if err
          throw err
      return
    catch error
      console.error error
      return next()
    return

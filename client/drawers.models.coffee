Backbone = require "backbone"
_  = require 'underscore'

models = NS "PWB.drawers.models"

now = -> new Date().getTime()




# Model for client only settings. Such as selected tool etc.
class models.ToolSettings extends Backbone.Model
  defaults:
    tool: "Pencil"
    size: 5
    color: "black"
    panningSpeed: null

  constructor: ->
    super

    if localStorage.settings
      $.extend @attributes, JSON.parse localStorage.settings

    @bind "change", => @save()

  save: ->
    localStorage.settings = JSON.stringify @attributes




# Persistent shared model between clients.
class models.RoomModel extends Backbone.Model

  defaults:
    background: false
    publishedImage: false
    position: 0
    name: null

  constructor: (opts) ->
    super
    {@socket} = opts

    # updateAttrs is a socket message that updates models on all clients
    @socket.on "updateAttrs", (attrs) =>

      # If remote changed the background we need to clear this local cache
      if attrs.background
        delete @backgroundDataURL

      @set attrs

  setPublishedImage: (dataURL, cb=->) ->
    @socket.emit "publishedImageData", dataURL, =>
      @set publishedImage: new Date().getTime()
      cb()

  saveBackground: (dataURL, cb=->) ->
    @backgroundDataURL = dataURL
    @set background: new Date().getTime()

    @socket.emit "backgroundData", dataURL, =>
      @trigger "background-saved"
      cb()

  getBackgroundURL: ->
    # We created the background. No need to download it.
    return @backgroundDataURL if @backgroundDataURL

    "#{ location.protocol }//#{ location.host }/#{ @get "roomName" }/#{ @get "position" }/bg?v=#{ @get "background" }"

  getPublishedImageURL: ->
    "#{ location.protocol }//#{ location.host }/#{ @get "roomName" }/#{ @get "position" }/published.png"

  getCacheImageURL: (pos) ->
    "/#{ @get "roomName" }/#{ @get "position" }/bitmap/#{ pos }"




# Model for drawing statistics. Mainly for debugging purposes.
class models.StatusModel extends Backbone.Model

  defaults:
    status: "starting"

    cachedDraws: 0
    startDraws: 0
    userDraws: 0
    remoteDraws: 0
    totalDraws: 0
    position:
      x: 0
      y: 0
    areaSize:
      width: 0
      height: 0
    drawingSize:
      width: 0
      height: 0



  constructor: ->
    super
    @loading = true
    @bind "change", =>
      if @get("status") is "ready"
        @loading = false
      @set totalDraws:(
        @get("cachedDraws") +
        @get("userDraws") +
        @get("remoteDraws") +
        @get("startDraws")
      )


  addClient: (client) ->
    clients = @get("clients") or {}
    clients[client.id] = client
    @set clients: clients

  removeClient: (client) ->
    clients = @get("clients") or {}
    delete clients[client.id]
    @set clients: clients


  getClientCount: ->
    _.size @get("clients") or {}


  addUserDraw: (i=1)->
    @set userDraws: @get("userDraws") + i

  addRemoteDraw: (i=1)->
    if not @loading
      @set remoteDraws: @get("remoteDraws") + i


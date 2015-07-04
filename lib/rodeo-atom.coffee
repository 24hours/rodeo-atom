CliStatusView = require './cli-status-view'
{CompositeDisposable} = require 'atom'

module.exports = RodeoAtom =
  cliStatusView: null
  state : null

  activate: (state) ->
    @state = state
    console.log(atom.config.get('rodeo-atom.enableOnStart'))
    if atom.config.get('rodeo-atom.enableOnStart')
      atom.packages.onDidActivateInitialPackages =>
        @cliStatusView = new CliStatusView(state.cliStatusViewState)

    atom.commands.add 'atom-workspace', 'rodeo-atom:enable': => @enable()

  deactivate: ->
    @cliStatusView.destroy()

  enable: ->
    @cliStatusView = new CliStatusView(@state.cliStatusViewState)

  serialize: ->

  config:
    'windowHeight':
      type: 'integer'
      default: 30
      minimum: 0
      maximum: 80
    'clearCommandInput':
      type: 'boolean'
      default: true
    'logConsole':
      type: 'boolean'
      default: false
    'overrideLs':
      title: 'Override ls'
      type: 'boolean'
      default: true
    'shell':
      type: 'string'
      default: if process.platform is 'win32'
          'cmd.exe'
        else
          process.env.SHELL ? '/bin/bash'
    'enableOnStart':
      type: 'boolean'
      default: 'true'

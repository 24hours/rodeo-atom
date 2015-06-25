{TextEditorView, View} = require 'atom-space-pen-views'
http = require 'http'
stringify = require 'querystring'
convert = require 'ansi-to-html'
{addClass, removeClass} = require 'domutil'
{resolve, dirname, extname} = require 'path'
fs = require 'fs'

lastOpenedView = null

module.exports =
class CommandOutputView extends View
  cwd: null
  @content: ->
    @div tabIndex: -1, class: 'panel cli-status panel-bottom', =>
      @div class: 'cli-panel-body', =>
        @pre class: "terminal", outlet: "cliOutput"
      @div class: 'cli-panel-input', =>
        @subview 'cmdEditor', new TextEditorView(mini: true, placeholderText: 'input your command here')
        @div class: 'btn-group', =>
          @button outlet: 'killBtn', click: 'kill', class: 'btn hide', 'kill'
          @button click: 'destroy', class: 'btn', 'destroy'
          @span class: 'icon icon-x', click: 'close'

  initialize: ->
    atom.commands.add 'atom-workspace',
      "rodeo-atom:toggle-output": => @toggle()
    @line = 0
    @indentLevel = 0
    @commandLine = ''
    @multiline = false
    @sendCmd 'print get_ipython().banner'
    atom.commands.add @cmdEditor.element,
      'core:confirm': =>
        inputCmd = @cmdEditor.getModel().getText().replace /\s+$/g, ""
        if @multiline isnt true
          @cliOutput.append "\nIn [#{@line}]:#{inputCmd}\n"
          @commandLine = inputCmd
        else
          pad_no =  "In [#{@line}]:".length - 5

          @cliOutput.append "\n#{Array(pad_no+1).join(' ')}....:#{inputCmd}\n"
          @commandLine = @commandLine + '\n' + inputCmd

        if inputCmd.slice(-1) is ':'
          @multiline = true
          @indentLevel++
        else if inputCmd is ''
          @multiline = false
          @indentLevel = 0

        @cmdEditor.setText(Array(@indentLevel*4+1).join(' '))

        @scrollToBottom()
        if @multiline isnt true and @commandLine.trim() isnt ''
          console.log(@commandLine.trim())
          @sendCmd @commandLine.trim()

  showCmd: ->
    @cmdEditor.show()
    @cmdEditor.css('visibility', '')
    @cmdEditor.getModel().selectAll()
    @cmdEditor.setText('') if atom.config.get('rodeo-atom.clearCommandInput')
    @cmdEditor.focus()
    @scrollToBottom()

  scrollToBottom: ->
    @cliOutput.scrollTop 10000000

  destroy: ->
    _destroy = =>
      if @hasParent()
        @close()
      if @statusIcon and @statusIcon.parentNode
        @statusIcon.parentNode.removeChild(@statusIcon)
      @statusView.removeCommandView this

      _destroy()

  open: ->
    @lastLocation = atom.workspace.getActivePane()
    @panel = atom.workspace.addBottomPanel(item: this) unless @hasParent()
    if lastOpenedView and lastOpenedView != this
      lastOpenedView.close()
    lastOpenedView = this
    @scrollToBottom()
    @statusView.setActiveCommandView this
    @cmdEditor.focus()
    @cliOutput.css('font-family', atom.config.get('editor.fontFamily'))
    @cliOutput.css('font-size', atom.config.get('editor.fontSize') + 'px')
    @cliOutput.css('max-height', atom.config.get('terminal-panel.windowHeight') + 'vh')

  close: ->
    @lastLocation.activate()
    @detach()
    @panel.destroy()
    lastOpenedView = null

  toggle: ->
    if @hasParent()
      @close()
    else
      @open()

  getCwd: ->
    extFile = extname atom.project.getPaths()[0]

    if extFile == ""
      if atom.project.getPaths()[0]
        projectDir = atom.project.getPaths()[0]
      else
        if process.env.HOME
          projectDir = process.env.HOME
        else if process.env.USERPROFILE
          projectDir = process.env.USERPROFILE
        else
          projectDir = '/'
    else
      projectDir = dirname atom.project.getPaths()[0]

    @cwd or projectDir or @userHome

  sendCmd: (cmd) ->
    @cmdEditor.css('visibility', 'hidden')
    #get_ipython().banner call this just when initialize
    ansihtml = new convert()
    shell = atom.config.get 'terminal-panel.shell'
    cmd_data = stringify.stringify {'code':cmd}
    req = http.request({hostname: 'localhost'
                        , port: 5000
                        , method: 'POST'
                        , headers: { 'Content-Type': 'application/x-www-form-urlencoded'
                                    ,'Content-Length': cmd_data.length}})
    req.write(cmd_data)
    req.on 'response', (resp)=>
      rodeo_resp = resp
      rodeo_resp.on 'data', (chunk) =>
        data = JSON.parse(chunk.toString())
        console.log(data)
        output = data['output'] or data['error']
        data = ansihtml.toHtml(output) if output
        @cliOutput.append data
        @scrollToBottom()
      #rodeo_resp.read()
    req.end()
    @showCmd()
    @line++

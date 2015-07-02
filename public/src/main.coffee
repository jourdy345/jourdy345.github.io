jQuery ->
  Messenger.options = {
    theme: 'air'
    extraClasses: 'messenger-fixed messenger-on-bottom messenger-on-right'
  }
  BrowserDetect = 
    init: ->
        @browser = @searchString(@dataBrowser) or "Other";
        @version = @searchVersion(navigator.userAgent) or @searchVersion(navigator.appVersion) or "Unknown";

    searchString: (data) -> 
        for datum in data
            dataString = datum.string
            @versionSearchString = datum.subString

            if dataString.indexOf(datum.subString) isnt -1
                return datum.identity
    
    searchVersion: (dataString) ->
        index = dataString.indexOf @versionSearchString
        if index is -1
          return

        rv = dataString.indexOf "rv:"
        if @versionSearchString is "Trident" and rv isnt -1
            return parseFloat dataString.substring rv + 3
        else
          return parseFloat dataString.substring(index + @versionSearchString.length + 1)
  

    dataBrowser: [
        {string: navigator.userAgent, subString: "Chrome", identity: "Chrome"},
        {string: navigator.userAgent, subString: "MSIE", identity: "Explorer"},
        {string: navigator.userAgent, subString: "Trident", identity: "Explorer"},
        {string: navigator.userAgent, subString: "Firefox", identity: "Firefox"},
        {string: navigator.userAgent, subString: "Safari", identity: "Safari"},
        {string: navigator.userAgent, subString: "Opera", identity: "Opera"}
    ]
    
  BrowserDetect.init()
  if BrowserDetect.browser is 'Explorer'
    Messenger().post
      message: 'Oh! I\'m sorry but features are limited on Internet Explorer.'
      type: 'error'
      showCloseButton: true
  else
    Messenger().post
      message: 'Good to see you off Internet Explorer!'
      type: 'info'
      showCloseButton: true


  window.Player = undefined
  done = false
  $(document)
    .on 'keydown', (e) ->
      $active = $ '#playlist .item.active'
      $this = $active.first()
      if e.shiftKey
        if e.keyCode is 8
          if $this.attr('data-video-id') is window.Player.getVideoData().video_id
            alert "Cannot delete currently running video."
          else
            window.Playlist.remove($this.attr('id'))
            i = _.findIndex window.Playlist.get(), (chr) ->
              return chr.id is window.Player.getVideoData().video_id
            offset = $('#' + i).find('td:first').offset()
            height = $('#' + i).height()
            $ '.bar-container'
              .css
                'top': offset.top + 37 + height * 0.5
                'left': offset.left - 10
        return true
      return true
  $ ->
    $('#sortable').sortable
      stop: (event, ui) ->
        window.Playlist.remap()
        return
    $('#sortable').disableSelection()
    return

  $ '.playlist-button button'
      .on 'click', (e) ->
        $this = $ this
        if $this.hasClass 'button-active'
          $this.removeClass 'button-active'
        else
          $this.addClass 'button-active'
          $this.siblings().removeClass 'button-active'


  onPlayerReady = (event) ->
    event.target.playVideo()
    return

  onPlayerStateChange = (event) ->
    if event.data is YT.PlayerState.ENDED
      if $('.playlist-button .repeat-all').hasClass 'button-active'
        if window.Player.getVideoData().video_id is window.Playlist.get()[window.Playlist.get().length - 1].id
          window.Playlist.play 0
        else
          currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
            return chr.id is window.Player.getVideoData().video_id
          window.Playlist.play currentVideoIndex + 1
      else if $('.playlist-button .repeat-one').hasClass 'button-active'
        currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
            return chr.id is window.Player.getVideoData().video_id
        window.Playlist.play currentVideoIndex
      else if $('.playlist-button .shuffle').hasClass 'button-active'
        currentVideoIndex =  _.findIndex window.ShuffledPlaylist, (chr) ->
          return chr.id is window.Player.getVideoData().video_id
        delete window.ShuffledPlaylist[currentVideoIndex]
        window.ShuffledPlaylist = _.compact window.ShuffledPlaylist
        if window.ShuffledPlaylist.length
          i = _.findIndex window.Playlist.get(), (chr) ->
            return chr.id is window.ShuffledPlaylist[0].id
          window.Playlist.play i
        else
          window.ShuffledPlaylist = _.shuffle window.Playlist.get()
          i = Math.floor(Math.random()*window.Playlist.get().length)
          window.Playlist.play i
      else
        currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
          return chr.id is window.Player.getVideoData().video_id
        window.Playlist.play currentVideoIndex+1


  stopVideo = ->
    window.Player.stopVideo()
    return

  window.onYouTubeIframeAPIReady = ->
    window.Player = new YT.Player 'player',
      height: '631.8'
      width: '1036.8'
      videoId: ''
      playerVars:
        'autoplay': 1
        'controls': 1
      events:
        # 'onReady': onPlayerReady
        'onStateChange': onPlayerStateChange
    return

  ## Create a class to wrap all the functions needed when controlling the playlist
  class Playlist
    constructor: (@list) ->
      # unless @list
      #   @list = []
      
      @list = JSON.parse(localStorage.videos or '[]')
      @render() if @list.length
      # for video in videos
      #   @add video
    
    get: ->
      @list

    add: (item) ->
      # {
      #   id: 'movie id'
      #   title: '...'
      # }
      @list.push item
      
      localStorage.videos = JSON.stringify @list
    add_to_next: (item) ->
      @list.unshift item

    check: (item) ->
      for each in @list
        templist = JSON.stringify @list, null, '  '
        if templist.match item.id
          return true
        return false
      
    render: ->
      $playtemplate = $ '.play-template'
      $ '#playlist .item'
        .remove()

      for item in @list
        index = _.findIndex @list, (chr) ->
          return chr.id is item.id
        $playtemplate = $('#playlist .play-template').clone()
        $playtemplate
          .find '.playlist-title'
          .html item.title
        $playtemplate
          .data 'video-id', item.id
        $playtemplate
          .attr 'id', index
        $playtemplate
          .attr 'data-video-id', item.id
        
        $playtemplate.removeClass 'play-template'
        $playtemplate.removeClass 'hide'
        $playtemplate.addClass 'item'
        $ '#playlist tbody'
          .append $playtemplate
      $ '#playlist .item'
        .on 'click', (e) ->
          $this = $ this
          $this.addClass 'active'
          $this.siblings().removeClass 'active'
        .on 'dblclick', (e) ->
          $this = $ this
          offset = $this.find('td:first').offset()
          height = $this.height()
          window.Playlist.play $this.attr 'id'
      
      window.ShuffledPlaylist = _.shuffle @get()
      # $.ajax
      #   url: '/video/add'
      #   method: 'post'
      #   data:
      #     video_list: JSON.stringify(@get())
      #   success: (d, s, x) ->
      #     console.log x.status
      #     console.log d
      #   error: (x, s, d) ->
      #     console.log s, d
      # return true

    play: (i) ->
      for item in @list
        item.playing = 0
      @list[i].playing = 1
      offset = $("#" + i).find('td:first').offset()
      height = $("#" + i).height()
      $ '.bar-container'
        .css
          'top': offset.top + 37 + height * 0.5
          'left': offset.left - 10
      window.Player.loadVideoById @list[i].id, 0, 'large'


    remove: (i) ->
      delete @list[i]
      @list = _.compact @list
      @render()
      localStorage.videos = JSON.stringify @list
  
    clear: ->
      @list = []
      @render()
      $ '.bar-container'
        .css
          'top': -9999
          'left': -9999
      localStorage.videos = JSON.stringify @list

    remap: ->
      mapping = _.compact($("#sortable").sortable("toArray", {attribute: "id"}))
      tempPlaylist = []
      tempPlaylist[i] = @list[mapping[i]] for i in [0..(@list.length-1)]
      @list[i] = tempPlaylist[i] for i in [0..(@list.length-1)]
      window.Playlist.render()
      index = _.findIndex @list, (chr) ->
        return chr.id is window.Player.getVideoData().video_id
      offset = $('#'+index).find('td:first').offset()
      height = $('#'+index).height()
      $ '.bar-container'
        .css
          'top': offset.top + 37 + height * 0.5
          'left': offset.left - 10


  window.Playlist = new Playlist()

  Results = new Bloodhound 
    datumTokenizer: (d) ->
      Bloodhound.tokenizers.whitespace(d.title)
    queryTokenizer: Bloodhound.tokenizers.whitespace
    limit: 50
    remote: 
      url: "https://www.googleapis.com/youtube/v3/search?q=__QUERY__&part=snippet&maxResults=50&type=video&key=AIzaSyCImmWz0DcJdeD45YTwGB_ZmhNv167bwpM"
      wildcard: '__QUERY__'
      filter: (response) ->
        data = []
        for item in response.items
          data.push {
            title: item.snippet.title
            id: item.id.videoId
            imgUrl: item.snippet.thumbnails.default.url
            playing: 0
          }
        return data
  
  Results.initialize()
  $ '#bloodhound .typeahead'
    .typeahead 
      limit: 5
      minLength: 1
      highlight: true
    , 
      name: 'searchYoutube'
      minLength: 1
      highlight: true
      valueKey: 'name'
      source: Results.ttAdapter()
      templates: 
        suggestion: Handlebars.compile '<img src="{{imgUrl}}" /><p><strong>{{title}} | {{date}}<strong></p>'
    .on 'typeahead:selected', (e, suggestion, name) ->
      window.Playlist.add suggestion
      window.Playlist.render()

  $ '.delete-all'
    .on 'click', (e) ->
      if window.Playlist.get().length
        if confirm 'This cannot be undone. Do you want to proceed?'
          window.Playlist.clear()
          return true
        else
          e.preventDefault()
          return false
      else
        alert 'There\'s nothing to delete.'
  $ '.btn-related-videos'
    .on 'click', (e) ->
      currentVideoId = window.Player.getVideoData().video_id
      if currentVideoId
        $.ajax
          url: 'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=50&key=AIzaSyCImmWz0DcJdeD45YTwGB_ZmhNv167bwpM&relatedToVideoId=' + currentVideoId
          method: 'get'
          success: (d, s, x) ->
            for item in d.items
              $template = $('.related-template').clone()
              $template
                .find '.related-img'
                .attr 'src', item.snippet.thumbnails.default.url
              $template
                .find '.related-title'
                .html item.snippet.title
              $template
                .find '.related-description'
                .html item.snippet.description
              $template
                .data 'video-id', item.id.videoId
              $template
                .attr 'data-video-id', item.id.videoId
              $template
                .data 'video-title', item.snippet.title
              $template
                .data 'video-date', item.snippet.publishedAt[0..9]
              $template
                .addClass 'related-item'
              $template
                .removeClass 'hide'
              $template
                .removeClass 'related-template'
              $ '#myrelatedModal .related-body'
                .append $template
            $ '.related-item'
              .on 'click', (e) ->
                $this = $ this
                window.Playlist.add
                  id: $this.data 'video-id'
                  title: $this.data 'video-title'
                  date: $this.data 'video-date'
                window.Playlist.render()
            true  
          error: (x, s, d) ->
            alert x.status
            e.preventDefault()
            e.stopPropagation()
            false
      else
        e.preventDefault()
        e.stopPropagation()
        alert 'No running video.'



  $ '#signinModal'
    .on 'shown.bs.modal', (e) ->
      $ '#signinModal #UserID'
        .focus()


  $ '#signup-ConfirmPassword'
    .on 'keyup', (e) ->
      $this = $ this
      if $this.val() isnt $('.sign-up-container #signup-UserPassword').val()
        $ '.password-check'
          .removeClass 'hide'
      else
        $ '.password-check'
          .addClass 'hide'

  $ '.sign-up-container button'
    .on 'click', (e) ->
      if $('#signup-ConfirmPassword').val() isnt $('#signup-UserPassword').val()
        e.preventDefault()
        e.stopPropagation()
        Messenger().post
          message: 'Passwords do not match.'
          type: 'error'
          showCloseButton: true
        $('#signup-ConfirmPassword').focus()



  $('.playlist-menu').popover 
    html: true
    title: "
      <div class='playlist-popover'>
        <ul class='nav nav-tabs' role='tablist'>
          <li role='presentation' class='active'><a href='#choosePlaylist' class='choosePlaylist-a' aria-controls='choosePlaylist' role='tab' data-toggle='tab'>Choose Playlist</a></li>
          <li role='presentation'><a href='#addPlaylist' class='addPlaylist-a' aria-controls='addPlaylist' role='tab' data-toggle='tab'>Add Playlist</a></li>
        </ul>
      </div>
      "
    content: "
      <div class='tab-content'>
        <div role='tabpanel' class='tab-pane fade in active' id='choosePlaylist'>
          <div class='appendPlaylist'>
            <div class='choosePlaylist-template hide'>
              <p>...</p>
            </div>
          </div>
        </div>
        <div class='playlist-create-success hide'>
          <h1>Playlist created!</h1>
        </div>
        <div role='tabpanel' class='tab-pane fade' id='addPlaylist'>
          <form>
            <div class='form-group'>
              <p class='successfully-added hide' style='color:#C10010'>Successfully added</p>
              <label for='PlaylistName'>New Playlist</label>
              <input type='text' class='form-control' name='PlaylistName' id='PlaylistName' placeholder='New Playlist' autocomplete='off' autofocus>
            </div>
            <button type='submit' class='btn btn-success'>Add</button>
          </form>
        </div>
      </div>
      "

  $('.playlist-menu')
    .on 'inserted.bs.popover', ->
      $ '#addPlaylist form'
        .on 'submit', (e) ->
          # e.preventDefault()
          # e.stopPropagation()
          if $('#PlaylistName').val().trim().length is 0
            return alert 'Please make a name for the Playlist.'
            
          $.ajax
            url: '/playlist/add'
            method: 'post'
            data: 
              playlist_name: $('#PlaylistName').val()
            headers: 
              Accept: 'application/json'
            success: (d, s, x) ->
              console.log d
              if x.status isnt 200
                return 'Error'
              $('.successfully-added').removeClass('hide')

              true
            error: (x, s, d) ->
              console.log s, d

          return false
    .on 'click', ->
      $.ajax
        url: '/playlist'
        method: 'get'
        success: (d, s, x) ->
          console.log x.status
          console.log d
          $ '.choosePlaylist-item'
            .remove()
          for each in d
            $template = $('.choosePlaylist-template').clone()
            $template
              .find 'p'
              .html each.playlist_name
            $template
              .data 'playlist-id', each.id
            $template.removeClass 'hide'
            $template.removeClass 'choosePlaylist-template'
            $template.addClass 'choosePlaylist-item'
            $('.appendPlaylist').append $template
        error: (x, s, d) ->
          alert 'Error: ' + s
      return true
  $('a[href=#choosePlaylist]')
    .on 'click', (e) ->
      e.preventDefault()
      e.stopPropagation()
      $(this).tab('show')
  $('a[href=#addPlaylist]')
    .on 'click', (e) ->
      e.preventDefault()
      e.stopPropagation()
      $(this).tab('show')




  $('#comment').popover
    html: true
    content: "
      <div>
        <p></p>
      </div>
      <div>
        <p> Leave a comment </p>
        <form>
            <div class='form-group'>
              <label for='comment-form'>New Playlist</label>
              <input type='text' class='form-control' name='comment-form' id='comment-form' autocomplete='off' autofocus>
            </div>
            <button type='submit' class='btn btn-success'>Add</button>
        </form>
      </div>
      "
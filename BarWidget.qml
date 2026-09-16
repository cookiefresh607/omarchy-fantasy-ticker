import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root

  moduleName: "fantasy-ticker"

  property bool popupOpen: false
  property bool loading: false
  property bool hasData: false
  property string statusText: "Loading…"
  property string errorText: ""
  property string seasonText: "2026 Season"
  property string weekText: ""
  property string matchupText: ""
  property string myTeamName: "Your team"
  property string opponentTeamName: "Opponent"
  property string myScoreText: "—"
  property string opponentScoreText: "—"
  property string lastUpdatedText: ""

  readonly property string apiBase: "https://api.sleeper.app/v1"
  readonly property string maxResponseBytes: "1048576"
  readonly property string limiterPath: Qt.resolvedUrl("bounded_response.py").toString().replace(/^file:\/\//, "")
  readonly property string userId: String(setting("userId", ""))
  readonly property string leagueId: String(setting("leagueId", ""))
  readonly property string leagueName: configuredLeagueName()
  readonly property int refreshIntervalMs: configuredRefreshSeconds() * 1000

  property var nflState: null
  property var rosters: []
  property var leagueUsers: []

  function validConfiguration() {
    return /^\d+$/.test(userId) && /^\d+$/.test(leagueId)
  }

  function configuredRefreshSeconds() {
    var seconds = Number(setting("refreshSeconds", 60))
    if (!isFinite(seconds) || seconds <= 0) return 60
    return Math.max(30, Math.floor(seconds))
  }

  function scoreText(value) {
    if (value === null || value === undefined || value === "") return "—"
    var score = Number(value)
    return isFinite(score) ? score.toFixed(2) : "—"
  }

  function cleanName(value) {
    return String(value === null || value === undefined ? "" : value)
      .replace(/[\r\n\t]+/g, " ").trim().slice(0, 80)
  }

  function configuredLeagueName() {
    return cleanName(setting("leagueName", "Fantasy League")) || "Fantasy League"
  }

  function boundedCurlCommand(url) {
    return [
      "bash", "-o", "pipefail", "-c",
      "curl --fail --silent --show-error --max-time 10 --max-filesize \"$3\" -- \"$1\" | python3 \"$2\"",
      "fantasy-ticker-request", url, limiterPath, maxResponseBytes
    ]
  }

  function teamNameForRoster(roster, fallback) {
    var ownerId = String(roster && roster.owner_id || "")
    for (var i = 0; i < leagueUsers.length; i++) {
      var user = leagueUsers[i]
      if (String(user && user.user_id || "") !== ownerId) continue

      var metadataName = cleanName(user.metadata && user.metadata.team_name)
      if (metadataName) return metadataName

      var displayName = cleanName(user.display_name)
      if (displayName) return displayName

      var username = cleanName(user.username)
      if (username) return username
    }
    return fallback
  }

  function localTimestamp(date) {
    function twoDigits(value) {
      return value < 10 ? "0" + value : String(value)
    }

    var hours = date.getHours()
    var suffix = hours >= 12 ? "PM" : "AM"
    hours = hours % 12
    if (hours === 0) hours = 12
    return hours + ":" + twoDigits(date.getMinutes()) + ":"
      + twoDigits(date.getSeconds()) + " " + suffix
  }

  function fail(message) {
    loading = false
    errorText = message
    statusText = hasData ? "Offline — showing last successful data" : "Offline"
  }

  function refresh() {
    if (loading) return
    if (!validConfiguration()) {
      fail("Invalid Sleeper configuration")
      return
    }

    loading = true
    errorText = ""
    statusText = hasData ? "Refreshing…" : "Loading…"
    stateProcess.command = boundedCurlCommand(apiBase + "/state/nfl")
    stateProcess.running = true
  }

  function processState(raw) {
    try {
      var parsed = JSON.parse(raw || "{}")
      var week = Number(parsed.display_week || parsed.week)
      if (!isFinite(week) || week < 1 || week > 22) {
        fail("Sleeper returned an invalid NFL week")
        return
      }
      nflState = parsed
      seasonText = String(parsed.season || "NFL") + " Season"
      weekText = "Week " + Math.floor(week)
      fetchRosters(Math.floor(week))
    } catch (error) {
      fail("Could not read Sleeper NFL state")
    }
  }

  function fetchRosters(week) {
    rostersProcess.command = boundedCurlCommand(apiBase + "/league/" + leagueId + "/rosters")
    rostersProcess.running = true
  }

  function processRosters(raw, week) {
    try {
      var parsed = JSON.parse(raw || "[]")
      if (!Array.isArray(parsed)) {
        fail("Sleeper returned invalid roster data")
        return
      }
      rosters = parsed
      fetchUsers(week)
    } catch (error) {
      fail("Could not read Sleeper roster data")
    }
  }

  function fetchUsers(week) {
    usersProcess.command = boundedCurlCommand(apiBase + "/league/" + leagueId + "/users")
    usersProcess.running = true
  }

  function processUsers(raw, week) {
    try {
      var parsed = JSON.parse(raw || "[]")
      if (!Array.isArray(parsed)) {
        fail("Sleeper returned invalid user data")
        return
      }
      leagueUsers = parsed
      fetchMatchups(week)
    } catch (error) {
      fail("Could not read Sleeper user data")
    }
  }

  function fetchMatchups(week) {
    matchupsProcess.command = boundedCurlCommand(apiBase + "/league/" + leagueId + "/matchups/" + week)
    matchupsProcess.running = true
  }

  function processMatchups(raw) {
    try {
      var parsed = JSON.parse(raw || "[]")
      if (!Array.isArray(parsed)) {
        fail("Sleeper returned invalid matchup data")
        return
      }

      var myRoster = null
      for (var i = 0; i < rosters.length; i++) {
        if (String(rosters[i].owner_id || "") === userId) {
          myRoster = rosters[i]
          break
        }
      }
      if (!myRoster) {
        fail("Your roster was not found in this league")
        return
      }

      var myMatchup = null
      for (var j = 0; j < parsed.length; j++) {
        if (String(parsed[j].roster_id) === String(myRoster.roster_id)) {
          myMatchup = parsed[j]
          break
        }
      }
      if (!myMatchup || myMatchup.matchup_id === null || myMatchup.matchup_id === undefined) {
        fail("You do not have a current matchup")
        return
      }

      var opponent = null
      for (var k = 0; k < parsed.length; k++) {
        if (String(parsed[k].matchup_id) === String(myMatchup.matchup_id)
            && String(parsed[k].roster_id) !== String(myMatchup.roster_id)) {
          opponent = parsed[k]
          break
        }
      }
      if (!opponent) {
        fail("Your opponent was not found")
        return
      }

      var opponentRoster = null
      for (var m = 0; m < rosters.length; m++) {
        if (String(rosters[m].roster_id) === String(opponent.roster_id)) {
          opponentRoster = rosters[m]
          break
        }
      }
      myTeamName = teamNameForRoster(myRoster, "Your team")
      opponentTeamName = teamNameForRoster(opponentRoster, "Opponent")
      myScoreText = scoreText(myMatchup.points)
      opponentScoreText = scoreText(opponent.points)
      matchupText = "Matchup " + String(myMatchup.matchup_id)
      lastUpdatedText = localTimestamp(new Date())
      hasData = true
      loading = false
      errorText = ""
      statusText = "Live"
    } catch (error) {
      fail("Could not read Sleeper matchup data")
    }
  }

  function open() {
    popupOpen = true
  }

  function close() {
    popupOpen = false
  }

  function toggle() {
    popupOpen = !popupOpen
  }

  Component.onCompleted: Qt.callLater(refresh)

  Timer {
    interval: root.refreshIntervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: stateProcess
    command: []
    stdout: StdioCollector {
      id: stateOutput
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode === 0) root.processState(stateOutput.text)
      else root.fail("Sleeper NFL state request failed")
    }
  }

  Process {
    id: rostersProcess
    command: []
    stdout: StdioCollector {
      id: rostersOutput
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode === 0) root.processRosters(rostersOutput.text, Number(root.nflState.display_week || root.nflState.week))
      else root.fail("Sleeper roster request failed")
    }
  }

  Process {
    id: matchupsProcess
    command: []
    stdout: StdioCollector {
      id: matchupsOutput
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode === 0) root.processMatchups(matchupsOutput.text)
      else root.fail("Sleeper matchup request failed")
    }
  }

  Process {
    id: usersProcess
    command: []
    stdout: StdioCollector {
      id: usersOutput
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode === 0) root.processUsers(usersOutput.text, Number(root.nflState.display_week || root.nflState.week))
      else root.fail("Sleeper user request failed")
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "🏈"
    tooltipText: "Fantasy Ticker"
    labelVisible: true
    onPressed: root.toggle()
  }

  PopupCard {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(240))
    contentHeight: popup.fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      anchors.fill: parent
      spacing: Style.space(6)

      Text {
        text: "Fantasy Ticker"
        textFormat: Text.PlainText
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
      }

      Text {
        text: root.leagueName
        textFormat: Text.PlainText
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
      }

      Text {
        text: root.seasonText
        textFormat: Text.PlainText
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
      }

      Text {
        text: root.weekText + (root.matchupText ? " · " + root.matchupText : "")
        textFormat: Text.PlainText
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Text {
        text: root.myTeamName + ": " + root.myScoreText
        textFormat: Text.PlainText
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
      }

      Text {
        text: root.opponentTeamName + ": " + root.opponentScoreText
        textFormat: Text.PlainText
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
      }

      Text {
        text: "Status: " + root.statusText
        textFormat: Text.PlainText
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Text {
        visible: root.errorText !== ""
        text: root.errorText
        textFormat: Text.PlainText
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.Wrap
      }

      Text {
        visible: root.lastUpdatedText !== ""
        text: "Last updated: " + root.lastUpdatedText
        textFormat: Text.PlainText
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }
}

require 'json'
require 'pry'
require 'date'

COMMA_SEP        = ','.freeze
COMMA_DELIM      = ', '.freeze
USER_ROW_TYPE    = 'user'.freeze
SESSION_ROW_TYPE = 'session'.freeze
CHROME_REGEX     = /^CHROME/.freeze
IE_REGEX         = /^INTERNET EXPLORER/.freeze

def parse_user(user)
  fields = user.split(COMMA_SEP)
  {
    id:        fields[1],
    full_name: "#{fields[2]} #{fields[3]}"
  }
end

def parse_session(session)
  fields = session.split(COMMA_SEP)
  {
    user_id:    fields[1],
    session_id: fields[2],
    browser:    fields[3].upcase!,
    time:       fields[4],
    date:       fields[5]
  }
end

def work(data_file, disable_gc: false)
  users             = []
  sessions_by_users = {}
  unique_browsers   = []
  total_sessions    = 0

  File.open(data_file, 'r').each do |row|
    users << parse_user(row) if row.start_with?(USER_ROW_TYPE)

    next unless row.start_with?(SESSION_ROW_TYPE)

    session = parse_session(row)
    sessions_by_users[session[:user_id]] ||= []
    sessions_by_users[session[:user_id]] << session
    unique_browsers << session[:browser]
    total_sessions += 1
  end

  unique_browsers.uniq!

  report = {}

  report[:totalUsers]          = users.length
  report[:uniqueBrowsersCount] = unique_browsers.length
  report[:totalSessions]       = total_sessions
  report[:allBrowsers]         = unique_browsers.sort!.join(COMMA_SEP)
  report[:usersStats]          = {}

  until users.empty?
    user              = users.shift
    user_sessions     = sessions_by_users.delete(user[:id]) || []
    sessions_duration = user_sessions.map { |s| s[:time].to_i }
    browsers          = user_sessions.map { |s| s[:browser] }

    report[:usersStats][user[:full_name]] = {
      sessionsCount:    user_sessions.length,
      totalTime:        "#{sessions_duration.sum} min.",
      longestSession:   "#{sessions_duration.max} min.",
      browsers:         browsers.sort!.join(COMMA_DELIM),
      usedIE:           browsers.any? { |b| b.match?(IE_REGEX) },
      alwaysUsedChrome: browsers.all? { |b| b.match?(CHROME_REGEX) },
      dates:            user_sessions.map { |s| Date.strptime(s[:date], '%Y-%m-%d') }.sort!.reverse!.map!(&:iso8601)
    }
  end

  File.write('files/result.json', "#{report.to_json}\n")
end

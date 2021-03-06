require 'json'
require 'date'
require 'minitest/autorun'

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
    browser:    fields[3],
    time:       fields[4],
    date:       fields[5]
  }
end

def work(data_file, report_file)
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
    browser = session[:browser].upcase!
    unique_browsers << browser unless unique_browsers.include?(browser)
    total_sessions += 1
  end

  report = {}

  report[:totalUsers]          = users.count
  report[:uniqueBrowsersCount] = unique_browsers.count
  report[:totalSessions]       = total_sessions
  report[:allBrowsers]         = unique_browsers.sort!.join(COMMA_SEP)
  report[:usersStats]          = {}

  until users.empty?
    user              = users.shift
    user_sessions     = sessions_by_users.delete(user[:id]) || []
    sessions_duration = user_sessions.map { |s| s[:time].to_i }
    browsers          = user_sessions.map { |s| s[:browser] }

    report[:usersStats][user[:full_name]] = {
      sessionsCount:    user_sessions.count,
      totalTime:        "#{sessions_duration.sum} min.",
      longestSession:   "#{sessions_duration.max} min.",
      browsers:         browsers.sort!.join(COMMA_DELIM),
      usedIE:           browsers.any? { |b| b =~ IE_REGEX },
      alwaysUsedChrome: browsers.all? { |b| b =~ CHROME_REGEX },
      dates:            user_sessions.map { |s| Date.strptime(s[:date], '%Y-%m-%d') }.sort!.reverse!.map!(&:iso8601)
    }
  end

  File.write(report_file, "#{report.to_json}\n")
end

work('data_large.txt', 'result.json')

class TaskTest < Minitest::Test
  def test_result
    work('files/test_data.txt', 'files/result.json')

    assert_equal File.read('files/test_result.json'), File.read('files/result.json')
  end
end

require 'json'
require 'pry'
require 'date'

COMMA_SEP        = ','.freeze
USER_ROW_TYPE    = 'user'.freeze
SESSION_ROW_TYPE = 'session'.freeze

class User
  attr_reader :attributes, :sessions

  def initialize(attributes:, sessions:)
    @attributes = attributes
    @sessions = sessions
  end
end

def parse_user(user)
  fields = user.split(COMMA_SEP)
  {
    id:         fields[1],
    first_name: fields[2],
    last_name:  fields[3],
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

def work(data_file, disable_gc: false)
  users           = []
  users_sessions  = {}
  unique_browsers = []
  total_sessions  = 0

  File.open(data_file, 'r').each do |row|
    users << parse_user(row) if row.start_with?(USER_ROW_TYPE)

    next unless row.start_with?(SESSION_ROW_TYPE)

    session = parse_session(row)
    users_sessions[session[:user_id]] ||= []
    users_sessions[session[:user_id]] << session
    browser = session[:browser].upcase!
    unique_browsers << browser unless unique_browsers.include?(browser)
    total_sessions += 1
  end

  # Отчёт в json
  #   - Сколько всего юзеров +
  #   - Сколько всего уникальных браузеров +
  #   - Сколько всего сессий +
  #   - Перечислить уникальные браузеры в алфавитном порядке через запятую и капсом +
  #
  #   - По каждому пользователю
  #     - сколько всего сессий +
  #     - сколько всего времени +
  #     - самая длинная сессия +
  #     - браузеры через запятую +
  #     - Хоть раз использовал IE? +
  #     - Всегда использовал только Хром? +
  #     - даты сессий в порядке убывания через запятую +

  report = {}

  report[:totalUsers] = users.count

  # Подсчёт количества уникальных браузеров

  report[:uniqueBrowsersCount] = unique_browsers.count

  report[:totalSessions] = total_sessions

  report[:allBrowsers] = unique_browsers.sort!.join(COMMA_SEP)

  report[:usersStats] = {}

  users.each do |user|
    user_sessions = users_sessions.delete(user[:id]) || []
    report[:usersStats][user[:full_name]] = {
      sessionsCount: user_sessions.count,
      totalTime: user_sessions.map {|s| s[:time]}.map {|t| t.to_i}.sum.to_s + ' min.',
      longestSession: user_sessions.map {|s| s[:time]}.map {|t| t.to_i}.max.to_s + ' min.',
      browsers: user_sessions.map {|s| s[:browser]}.map {|b| b.upcase}.sort.join(', '),
      usedIE: user_sessions.map{|s| s[:browser]}.any? { |b| b.upcase =~ /INTERNET EXPLORER/ },
      alwaysUsedChrome: user_sessions.map{|s| s[:browser]}.all? { |b| b.upcase =~ /CHROME/ },
      dates: user_sessions.map{|s| s[:date]}.map {|d| Date.strptime(d, '%Y-%m-%d')}.sort.reverse.map { |d| d.iso8601 }
    }
  end

  File.write('files/result.json', "#{report.to_json}\n")
end

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
    last_name:  fields[3]
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

def collect_stats_from_users(report, users_objects, &block)
  users_objects.each do |user|
    user_key = "#{user.attributes[:first_name]}" + ' ' + "#{user.attributes[:last_name]}"
    report[:usersStats][user_key] ||= {}
    report[:usersStats][user_key] = report[:usersStats][user_key].merge(block.call(user))
  end
end

def calculate_users_objects(users, users_sessions)
  # Статистика по пользователям
  users_objects = []

  users.each do |user|
    attributes = user
    user_sessions = users_sessions[user[:id]]
    user_object = User.new(attributes: attributes, sessions: user_sessions)
    users_objects << user_object
  end

  users_objects
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

  users_objects = calculate_users_objects(users, users_sessions)

  report[:usersStats] = {}

  # Собираем количество сессий по пользователям
  collect_stats_from_users(report, users_objects) do |user|
    { sessionsCount: user.sessions.count }
  end

  # Собираем количество времени по пользователям
  collect_stats_from_users(report, users_objects) do |user|
    { totalTime: user.sessions.map {|s| s[:time]}.map {|t| t.to_i}.sum.to_s + ' min.' }
  end

  # Выбираем самую длинную сессию пользователя
  collect_stats_from_users(report, users_objects) do |user|
    { longestSession: user.sessions.map {|s| s[:time]}.map {|t| t.to_i}.max.to_s + ' min.' }
  end

  # Браузеры пользователя через запятую
  collect_stats_from_users(report, users_objects) do |user|
    { browsers: user.sessions.map {|s| s[:browser]}.map {|b| b.upcase}.sort.join(', ') }
  end

  # Хоть раз использовал IE?
  collect_stats_from_users(report, users_objects) do |user|
    { usedIE: user.sessions.map{|s| s[:browser]}.any? { |b| b.upcase =~ /INTERNET EXPLORER/ } }
  end

  # Всегда использовал только Chrome?
  collect_stats_from_users(report, users_objects) do |user|
    { alwaysUsedChrome: user.sessions.map{|s| s[:browser]}.all? { |b| b.upcase =~ /CHROME/ } }
  end

  # Даты сессий через запятую в обратном порядке в формате iso8601
  collect_stats_from_users(report, users_objects) do |user|
    { dates: user.sessions.map{|s| s[:date]}.map {|d| Date.parse(d)}.sort.reverse.map { |d| d.iso8601 } }
  end

  File.write('files/result.json', "#{report.to_json}\n")
end

require 'rubygems'
require 'sinatra'
require 'pg'
require 'uuidtools'
require 'yaml'
#require './config.rb'

set :bind, '0.0.0.0'
set :port, 9999

class Dbc
  def self.config
    YAML.safe_load(ERB.new(File.read('db_config.yml')).result)
  end
end

get '/' do
  f = File.open('score_left.txt', 'r')
  @score_left = f.read
  f.close

  f = File.open('score_right.txt', 'r')
  @score_right = f.read
  f.close

  f = File.open('fouls_left.txt', 'r')
  @fouls_left = f.read
  f.close

  f = File.open('fouls_right.txt', 'r')
  @fouls_right = f.read
  f.close

  f = File.open('period.txt', 'r')
  @period = f.read
  f.close

  f = File.open('posession_left.txt', 'r')
  @posession_left = f.read
  f.close

  f = File.open('posession_right.txt', 'r')
  @posession_right = f.read
  f.close

  # This should be left.
  f = File.open('bonus_left.txt', 'r')
  @bonus_left = f.read
  f.close

  f = File.open('bonus_right.txt', 'r')
  @bonus_right = f.read
  f.close

  erb :scoreboard
end

get '/initialize' do
  %w{score_left score_right fouls_left fouls_right}.each do |f|
    f = File.open("#{f}.txt", 'w')
    f.write('0')
    f.close
  end

  f = File.open('period.txt', 'w')
  f.write('1')
  f.close

  %w{posession_left posession_right bonus_left bonus_right}.each do |f|
    f = File.open("#{f}.txt", 'w')
    f.close
  end

  redirect '/'
end

# TEAM ROUTES

get '/teams' do
  t = []
  t_error = []

  begin
    db = PG.connect :dbname => Dbc.config['db']['name'],
		    :user => Dbc.config['db']['user'],
		    :password => Dbc.config['db']['pass'],
		    :host => Dbc.config['db']['host']

    teams = db.exec 'SELECT * FROM teams'

    unless teams.nil?
    puts teams
      teams.each do |team|
        t.unshift({
	  team_id: team['team_id'],
	  team_name: team['team_name'],
	  team_year: team['team_year']
	})
      end
    else
      t.unshift({
	team_id: ':(',
	team_name: 'No Teams, ',
	team_year: 'Yet. '
      })
    end

  rescue PG::Error => e
    t_error.unshift(e.message.to_s)

  ensure
    db.close if db

  end

  erb :teams, :locals => {:t => t, :t_error => t_error }
end

get '/teams/new' do
  erb :teams_new
end

post '/teams/new/submit' do
  if ( params[:team_name] != '' )
    begin
      db = PG.connect :dbname => Dbc.config['db']['name'],
		      :user => Dbc.config['db']['user'],
		      :password => Dbc.config['db']['pass'],
		      :host => Dbc.config['db']['host']

      team_uuid = UUIDTools::UUID.random_create.to_s

      db.exec "INSERT INTO teams(team_id, team_name, team_year) \
	       VALUES ('#{team_uuid}', '#{params[:team_name]}', '#{params[:team_year]}');"

    rescue PG::Error => e
      puts e.message.to_s

    ensure
      db.close if db

    end
  else
    puts "team name should not be empty."
  end

  redirect "/teams"
end


# PLAYER ROUTES

get '/players' do
  p = []
  p_error = []

  begin
    db = PG.connect :dbname => Dbc.config['db']['name'],
		    :user => Dbc.config['db']['user'],
		    :password => Dbc.config['db']['pass'],
		    :host => Dbc.config['db']['host']

    players = db.exec 'SELECT * FROM players'

    players.each do |player|
      t = []
      team = db.exec "SELECT team_name FROM teams WHERE team_id='#{player['player_team_id']}'"

      team.each do |t|
	team_name = t['team_name']
	break #Only set first team name if more exist.
      end

      p.unshift({
	player_id: player['player_id'],
	player_fname: player['player_fname'],
	player_lname: player['player_lname'],
	player_number: player['player_number'],
	player_year: player['player_year'],
	player_team: "#{team_name}"
      })
    end

  rescue PG::Error => e
    p_error.unshift(e.message.to_s)

  ensure
    db.close if db

  end

  erb :players, :locals => {:p => p, :p_error => p_error }
end

get '/players/new' do
  t = []
  t_error = []

  begin
    db = PG.connect :dbname => Dbc.config['db']['name'],
		    :user => Dbc.config['db']['user'],
		    :password => Dbc.config['db']['pass'],
		    :host => Dbc.config['db']['host']

    teams = db.exec 'SELECT * FROM teams'

    teams.each do |team|
      t.unshift({
	team_id: team['team_id'],
	team_name: team['team_name']
      })
    end

  rescue PG::Error => e
    t_error.unshift(e.message.to_s)

  ensure
    db.close if db

  end

  erb :players_new, :locals => {:t => t, :t_error => t_error }
end

post '/players/new/submit' do
  player_school_id = "0"

  if (( params[:team] != '' ) and
      ( params[:player_number] != '' ))

    begin
      db = PG.connect :dbname => Dbc.config['db']['name'],
		      :user => Dbc.config['db']['user'],
		      :password => Dbc.config['db']['pass'],
		      :host => Dbc.config['db']['host']

      player_uuid = UUIDTools::UUID.random_create.to_s

      db.exec "INSERT INTO players(player_id, player_fname, player_lname, player_number, player_team_id, player_school_id, player_year) \
	       VALUES ('#{player_uuid}', '#{params[:player_fname]}', '#{params[:player_lname]}', '#{params[:player_number]}', '#{params[:team]}', '#{player_school_id}', '#{params[:player_year]}');"

    rescue PG::Error => e
      puts e.message.to_s

    ensure
      db.close if db

    end
  else
    puts "team name and player number should not be empty."
  end

  redirect "/players"
end


# SCORE ROUTES

%w{right left}.each do |side|
  %w{1 2 3}.each do |i|
    get "/score/#{side}/plus_#{i}" do
      if !File.exist?("score_#{side}.txt")
	f = File.new("score_#{side}.txt", 'w')
	f.write(i)
	f.close
      else
	f = File.open("score_#{side}.txt", 'r')
	s = f.read
	s = s.to_i + i.to_i
	f.close

	f = File.open("score_#{side}.txt", 'w')
	f.write(s)
	f.close
      end

      redirect '/'
    end
  end
end


# FOUL ROUTES

%w{right left}.each do |side|
  # This is fixed in another branch
  get "/fouls/#{side}/plus_1" do

    fn = "fouls_#{side}.txt"

    if side == "right"
      bonus_f = 'bonus_left.txt'
    else
      bonus_f = 'bonus_right.txt'
    end

    if !File.exist?(fn)
      f = File.new(fn, 'w')
      f.write('1')
      f.close
    else
      f = File.open(fn, 'r')
      s = f.read
      s = s.to_i + 1
      f.close

      f = File.open(fn, 'w')
      f.write(s)
      f.close
    end

    if (s > 9)
      bs = "BB"
    elsif (s > 6)
      bs = "B"
    else
      bs = ''
    end

    f = File.open(bonus_f, 'w')
    f.write(bs)
    f.close

    redirect '/'
  end

  get "/posession/#{side}" do

    fnl = 'posession_left.txt'
    fnr = 'posession_right.txt'

    if side == "left"
      f = File.new(fnr, 'w')
      f.write('')			  # Shouldn't actually need this line
      f.close

      f = File.new(fnl, 'w')
      f.write('<')
      f.close
    else
      f = File.new(fnr, 'w')
      f.write('>')
      f.close

      f = File.new(fnl, 'w')
      f.write('')			  # Shouldn't actually need this line
      f.close
    end

    redirect '/'
  end
end


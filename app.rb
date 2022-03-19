require 'rubygems'
require 'sinatra'
require 'pg'
require 'uuidtools'

set :bind, '0.0.0.0'
set :port, 9999

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


class Rater
  include DataMapper::Resource
  property :id,         Serial 
  property :name,       String
end

class Vote
  include DataMapper::Resource
  property :id, Serial 
end

class Article
  include DataMapper::Resource
  property :id,         Serial 
  property :name,       String

  is :slope_one, :rater_model => "Rater", :rating_model => "Vote", :rating_property => :preference

end
db = 'dm_slope_one'
# DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "postgres://asher@localhost/#{db}")
# DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.auto_migrate! if defined?(DataMapper)

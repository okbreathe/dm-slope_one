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

  is :filterable, :by => "Rater", :on => "Vote"

end

DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.auto_migrate! if defined?(DataMapper)

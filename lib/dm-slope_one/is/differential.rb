class Differential

  include DataMapper::Resource

  property :count,     Integer
  property :source_id, Integer, :min => 1, :key => true
  property :target_id, Integer, :min => 1, :key => true

end

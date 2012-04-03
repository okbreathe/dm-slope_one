require 'pathname'

# Add all external dependencies for the plugin here
require 'dm-ar-finders'
require 'dm-validations'
require 'dm-constraints'
require 'dm-transactions'

# Require plugin-files

dir = File.dirname(__FILE__) + '/dm-slope_one/is/'

require dir + 'slope_one.rb'
require dir + 'rating.rb'

# Include the plugin in Resource
DataMapper::Model.append_extensions DataMapper::Is::SlopeOne

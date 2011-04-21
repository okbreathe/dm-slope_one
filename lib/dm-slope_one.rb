require 'pathname'

# Add all external dependencies for the plugin here
require 'dm-ar-finders'
require 'dm-validations'

# Require plugin-files

dir = File.dirname(__FILE__) + '/dm-slope_one/is/'

require dir + 'filterable.rb'
require dir + 'differential.rb'
require dir + 'rating.rb'

# Include the plugin in Resource
DataMapper::Model.append_extensions DataMapper::Is::Filterable



require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'shoulda'
require 'rr'
require 'dm-migrations'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'dm-slope_one'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end

class Object

  def shout(*msgs)
    wrap = "\n" + "="*80 + "\n"
    msg  = wrap + "#{msgs.collect{|m| m.inspect}.join("\n")}" + wrap
    $stdout.puts "[1;35m%s[0m" % msg
  end

end

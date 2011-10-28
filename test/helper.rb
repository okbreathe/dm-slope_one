require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest/spec'
require 'minitest/autorun'
require 'rr'
require 'dm-migrations'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'dm-slope_one'

class MiniTest::Unit::TestCase
  include RR::Adapters::MiniTest

  def diff_test(values = nil,debug = false)
    values ||= {        
      ['i2' ,'i1'] => [2 , -0.3],
      ['i3' ,'i1'] => [3 , -0.5],
      ['i4' ,'i1'] => [2 , -0.6],
      ['i3' ,'i2'] => [3 , -0.2],
      ['i4' ,'i2'] => [2 , -0.4],
      ['i4' ,'i3'] => [3 , -0.8]
    }
    values.each do |(a,b),(c,d)|
      diff = ArticleDiff.first(:source => Article.first(:name => a),:target => Article.first(:name => b))
			assert_equal a, diff.source.name
			assert_equal b, diff.target.name
			assert_equal c, diff.count
			assert_in_delta d, diff.sum
    end
  end
  
  def recommendations_test(recommendations,values)
    recommendations.map(&:id) == values
  end
end

MiniTest::Unit.autorun

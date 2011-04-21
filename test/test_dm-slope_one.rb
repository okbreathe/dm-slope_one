require 'helper'
require 'data'

class TestDmSlopeOne < Test::Unit::TestCase
  context "dm-slop_one" do
    setup do
      %w(u1 u2 u3 u4).each do |user|
        Rater.create :name => user
      end
      %w(i1 i2 i3 i4).each do |name|
        Article.create(:name => name)
      end

      user_data = {
        'u1' => { 'i1'=> 1,   'i2'=> 0.5, 'i3'=> 0.2 },
        'u2' => { 'i1'=> 1,   'i3'=> 0.5, 'i4'=> 0.2 }, 
        'u3' => { 'i1'=> 0.2, 'i2'=> 0.4, 'i3'=> 1, 'i4'=> 0.4 },
        'u4' => { 'i2'=> 0.9, 'i3'=> 0.4, 'i4'=> 0.5 }
      }

      user_data.each do |k,v|
        user = Rater.first(:name => k)
        v.each do |a,score|
          Vote.create(:rater => user, :article => Article.first(:name => a) ,:score => score)
        end
      end
    end

    should "work" do
      assert_equal 4,  Rater.count
      assert_equal 4,  Article.count
      assert_equal 13, Vote.count
      assert_equal 12, Differential.count
    end

    should "allow you to predict based on the user" do
      rs = Rater.all
      as = Article.all
      assert_same_elements [as[2], as[1], as[0], as[3]], Article.predict(rs[0])
      assert_same_elements [as[2], as[0], as[1], as[3]], Article.predict(rs[1])
      assert_same_elements [as[0], as[1], as[2], as[3]], Article.predict(rs[2])
      assert_same_elements [as[2], as[0], as[1], as[3]], Article.predict(rs[3])
    end

    should "allow you to predict based on the resource" do
      as = Article.all
      assert_same_elements [as[1], as[2], as[3]], Article.predict(as[0])
      assert_same_elements [as[0], as[2], as[3]], Article.predict(as[1])
      assert_same_elements [as[0], as[1], as[3]], Article.predict(as[2])
      assert_same_elements [as[0], as[2], as[1]], Article.predict(as[3])
    end

    should "allow you to predict based on the resource and user" do
      rater = Rater.first
      as    = Article.all
      assert_same_elements [as[2], as[1], as[3]], Article.predict(rater,as[0])
      assert_same_elements [as[2], as[0], as[3]], Article.predict(rater,as[1])
      assert_same_elements [as[1], as[0], as[3]], Article.predict(rater,as[2])
      assert_same_elements [as[2], as[1], as[0]], Article.predict(rater,as[3])
    end

    teardown do
      Rater.all.destroy
      Article.all.destroy
      Vote.all.destroy
      Differential.all.destroy
    end
  end
end

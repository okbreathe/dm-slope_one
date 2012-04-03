require 'helper'
require 'data'

describe DataMapper::Is::SlopeOne do


  describe "generating diffs" do

    before do
      generate_ratings({
        'u1' => { 'i1'=> 1.0, 'i2'=> 0.5, 'i3'=> 0.2 },
        'u2' => { 'i1'=> 1.0, 'i3'=> 0.5, 'i4'=> 0.2 }, 
        'u3' => { 'i1'=> 0.2, 'i2'=> 0.4, 'i3'=> 1.0, 'i4'=> 0.4 },
        'u4' => { 'i2'=> 0.9, 'i3'=> 0.4, 'i4'=> 0.5 }
      })
    end

    it "should work" do
      assert_equal 4,  Rater.count
      assert_equal 4,  Article.count
      assert_equal 13, Vote.count
      assert_equal 6,  ArticleDiff.count
    end

    it "should correctly incrementally generate diffs" do
      diff_test
    end

    it "should correctly generates diffs on item creation" do
      Vote.generate_diffs!
      diff_test

    end
    it "should correctly update diffs on item update" do
      updates = {
        ['u1','i1']=>0.3,
        ['u1','i2']=>0.8,
        ['u1','i3']=>0.1,
        ['u2','i1']=>0.7,
        ['u2','i3']=>0.9,
        ['u2','i4']=>0.4,
        ['u3','i1']=>0.2,
        ['u3','i2']=>0.3,
        ['u3','i3']=>0.7,
        ['u3','i4']=>0.6,
        ['u4','i2']=>0.4,
        ['u4','i3']=>0.5,
        ['u4','i4']=>0.7
      }
      updates.each do |(a,b),c|
        Vote.first(:rater => Rater.first(:name => a), :article => Article.first(:name => b)).update(:preference => c)
      end
      values = {
        ['i2' ,'i1'] => [2 ,  0.6],
        ['i3' ,'i1'] => [3 ,  0.5],
        ['i4' ,'i1'] => [2 ,  0.1],
        ['i3' ,'i2'] => [3 , -0.2],
        ['i4' ,'i2'] => [2 ,  0.6],
        ['i4' ,'i3'] => [3 , -0.4]
      }
      diff_test(values, true)
    end

    it "should correctly update diffs on item deletion" do
      Vote.first(:rater => Rater.first(:name => 'u1'), :article => Article.first(:name => 'i3')).destroy
      values = {
        ['i2' ,'i1'] =>[2 , -0.3],
        ['i3' ,'i1'] =>[2 ,  0.3],
        ['i4' ,'i1'] =>[2 , -0.6],
        ['i3' ,'i2'] =>[2 ,  0.1],
        ['i4' ,'i2'] =>[2 , -0.4],
        ['i4' ,'i3'] =>[3 , -0.8]
      }
      diff_test(values, true)

      Vote.first(:rater => Rater.first(:name => 'u2'), :article => Article.first(:name => 'i4')).destroy
      values = {
        ['i2' ,'i1'] =>[2 , -0.3],
        ['i3' ,'i1'] =>[2 ,  0.3],
        ['i4' ,'i1'] =>[1 ,  0.2],
        ['i3' ,'i2'] =>[2 ,  0.1],
        ['i4' ,'i2'] =>[2 , -0.4],
        ['i4' ,'i3'] =>[2 , -0.5]
      }
      diff_test(values, true)

      Vote.first(:rater => Rater.first(:name => 'u3'), :article => Article.first(:name => 'i4')).destroy
      values ={
        ['i4' ,'i1'] =>[0 ,    0],
        ['i2' ,'i1'] =>[2 , -0.3],
        ['i3' ,'i1'] =>[2 ,  0.3],
        ['i3' ,'i2'] =>[2 ,  0.1],
        ['i4' ,'i2'] =>[1 , -0.4],
        ['i4' ,'i3'] =>[1 ,  0.1]
      }
      diff_test(values, true)
    end

  end # Generating incrementally

  describe "Predicting" do

    before do
      generate_ratings({
        'u1' => { 'i1'=> 1.0, 'i2'=> 0.5, 'i3'=> 0.2 },
        'u2' => { 'i1'=> 1.0, 'i3'=> 0.5, 'i4'=> 0.2 }, 
        'u3' => { 'i1'=> 0.2, 'i2'=> 0.4, 'i3'=> 1.0, 'i4'=> 0.4 },
        'u4' => { 'i2'=> 0.9, 'i3'=> 0.4, 'i4'=> 0.5 }
      })
    end

    it "should allow you to recommend based on the resource" do
      recommendations = Article.first.recommend
      values = [ 'i4' , 'i3' , 'i2' ]
      recommendations_test(recommendations,values)

      recommendations = Article.first(:offset => 1).recommend
      values = [ 'i4' , 'i3' , 'i1' ]
      recommendations_test(recommendations,values)

      recommendations = Article.first(:offset => 2).recommend
      values = [ 'i4' , 'i2' , 'i1' ]
      recommendations_test(recommendations,values)

      recommendations = Article.last.recommend
      values = [ 'i2' , 'i3' , 'i1' ]
      recommendations_test(recommendations,values)
    end

    it "should allow you to recommend based on the user" do
      recommendations = Article.recommend_for_user(Rater.first)
      values = ['i3' , 'i2' , 'i1' , 'i4'] 
      recommendations_test(recommendations,values)

      recommendations = Article.recommend_for_user(Rater.first(:offset =>1))
      values = ['i3' , 'i1' , 'i2' , 'i4'] 
      recommendations_test(recommendations,values)

      recommendations = Article.recommend_for_user(Rater.first(:offset =>2))
      values = ['i1' , 'i2' , 'i3' , 'i4']
      recommendations_test(recommendations,values)

      recommendations = Article.recommend_for_user(Rater.last)
      values = ['i3' , 'i1' , 'i2' , 'i4']
      recommendations_test(recommendations,values)
    end

    it "should allow you to exclude items already rated by the user in recommendations" do
      recommendations = Article.recommend_for_user(Rater.first,:exclusive => true)
      values = ['i4']
      recommendations_test(recommendations,values)

      recommendations = Article.recommend_for_user(Rater.first(:offset =>1),:exclusive => true)
      values = ['i2']
      recommendations_test(recommendations,values)

      recommendations = Article.recommend_for_user(Rater.first(:offset =>2),:exclusive => true)
      values = []
      recommendations_test(recommendations,values)

      recommendations = Article.recommend_for_user(Rater.last,:exclusive => true)
      values = ['i1']
      recommendations_test(recommendations,values)
    end

  end # Predicting

  after do
    Rater.all.destroy
    Article.all.destroy
    Vote.all.destroy
    ArticleDiff.all.destroy
  end

  def generate_ratings(user_data)
    user_data.each do |rater,data|
      data.each do |item,preference|
        Vote.create(:rater => Rater.first_or_create( :name => rater ), :article => Article.first_or_create(:name => item) ,:preference => preference)
      end
    end
  end

  def get_freq(i1,i2)
    get_article_diff(i1,i2).frequency
  end

  def get_diff(i1,i2)
    get_article_diff(i1,i2).difference
  end

  def get_article_diff(i1,i2)
    ArticleDiff.first(:source => Article.first(:name => "i#{i1}"), :target => Article.first(:name => "i#{i2}"))
  end
end

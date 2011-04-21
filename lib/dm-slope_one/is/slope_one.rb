module DataMapper
  module Is
    module SlopeOne

      # Add the slope one recommendation algorithm to a given resource
      #
      # @example
      #
      #   class Post
      #     include DataMapper::Resource
      #
      #     property :id,      Serial
      #     property :name,    String
      #
      #     is :slope_one
      #   end
      #
      # @param [Hash] options(optional)
      #   A hash with options
      # @option options [String] :rater_model
      #   Stringified name of the DataMapper model that should become the rater
      #   default: User
      # @option options [String] :rating_model
      #   Stringified name of the DataMapper model that stores the rater's ratings 
      #   default: #{Resource}Rating
      # @option options [String] :diff_model
      #   Stringified name of the DataMapper model that stores the rating differentials
      #   default: #{Resource}Diff
      # @option options [Symbol] :rating_property
      #   The property that will be used when generating differentials
      #   default: score
      # @option options [Boolean] - If true then inserting resources and ratings will not
      #   trigger diff updates. This is useful if you plan to batch process
      #   ratings offline.
      #   default:false
      # @option options [String] :rating_type
      #   Can be Integer or Float
      #   default: Float
      # @option options [Integer] :rating_precision
      #   Only applicable to Float type
      #   default: 3
      # @option options [Integer] :rating_scale
      #   Only applicable to Float type
      #   default: 2
      #
      # @api public
      def is_slope_one(opts={})

        extend  DataMapper::Is::SlopeOne::ClassMethods
        include DataMapper::Is::SlopeOne::InstanceMethods

        inf             = DataMapper::Inflector
        resource_model  = self
        rater_model     = inf.constantize( opts[:rater_model]    || "User" )
        diff_model      = inf.classify( opts[:diff_model]        || "#{name}Diff" )
        rating_property = inf.underscore( opts[:rating_property] || "score" )
        rating_model    = inf.classify(  opts[:rating_model]     || "#{inf.underscore(name)}_ratings" ) 

        class << self; attr_reader :slope_one_options; end

        o = @slope_one_options = { 
          :resource_table   => inf.tableize(name),
          :resource_key     => inf.foreign_key(name),
          :rater_table      => inf.tableize(rater_model),
          :rater_key        => inf.foreign_key(rater_model),
          :rating_table     => inf.tableize(rating_model),
          :diff_table       => inf.tableize(diff_model),
          :diff_model       => diff_model,
          :rating_property  => rating_property,
          :rating_type      => "Float",
          :rating_precision => 3,
          :rating_scale     => 2
        }.merge(opts)

        rating_property_attributes = o[:rating_type] == "Float" ? 
          [Float, :precision => o[:rating_precision], :scale => o[:rating_scale], :default => 0.0] : 
            [Integer, :default => 0]

        # Setup the diff model

        diff_model = ::Object.const_set(diff_model, Class.new(::Object) )
        diff_model.class_eval do
          include ::DataMapper::Resource unless ancestors.include?(::DataMapper::Resource)
          property :count, Integer, :required => true, :min => 0, :default => 0
          property :sum, *rating_property_attributes
          belongs_to :source, resource_model.to_s, :child_key => [:source_id], :key => true
          belongs_to :target, resource_model.to_s, :child_key => [:target_id], :key => true
        end

        # Enhance the existing rating model
        rating_model = begin ::Object.const_get(rating_model); rescue ::Object.const_set(rating_model, Class.new(::Object) ); end
        rating_model.class_eval do
          include ::DataMapper::Resource unless ancestors.include?(::DataMapper::Resource)
          property rating_property, *rating_property_attributes
          belongs_to inf.underscore(rater_model),    :key => true
          belongs_to inf.underscore(resource_model), :key => true
          define_singleton_method :slope_one_options do resource_model.slope_one_options; end
          extend ::DataMapper::Is::SlopeOne::Rating
        end

        # Setup relationships

        has n, inf.tableize(rating_model), :constraint => :destroy
        rater_model.has n, inf.tableize(rating_model), :constraint => :destroy

        # Create empty diffs after we add a rateable item

        after :create do
          q = "INSERT INTO #{inf.tableize diff_model} (source_id, target_id) SELECT ?, id FROM #{inf.tableize self.class.name} WHERE id <> ?"
          repository.adapter.execute q, id, id
        end

        before :destroy do
          (diff_model.all(:target => self) | diff_model.all(:source => self)).destroy!
        end

      end

      module ClassMethods

        # @api public
        def using_slope_one?
          true
        end

        # Find resources based on user's previous ratings
        # @return DataMapper::Collection
        def recommend_for_user(user,opts={})
          o = slope_one_options
          q = %Q{
               SELECT a.*
                 FROM #{o[:resource_table]} a, (#{frequency_matrix}) f
                 JOIN #{o[:rating_table]} r1 ON r1.#{o[:resource_key]} = f.target_id
            LEFT JOIN #{o[:rating_table]} r2 ON r2.#{o[:resource_key]} = f.source_id AND r2.#{o[:rater_key]} = r1.#{o[:rater_key]}
                WHERE r1.#{o[:rater_key]} = ?
                  AND f.count > 0 
                  AND a.id = f.source_id
               #{"AND r2.#{o[:resource_key]} IS NULL" if opts[:exclusive]}
             GROUP BY f.source_id, a.id
             ORDER BY ( SUM(f.sum + f.count * r1.#{o[:rating_property]}) / SUM(f.count) ) DESC LIMIT ?;
          }
          find_by_sql [q, user.id, opts[:limit] || 20]
        end

        # Find similar resources to the given
        # @return DataMapper::Collection
        def recommend_for_resource(resource,opts={})
          q = %Q{
               SELECT a.*
                 FROM (#{frequency_matrix}) f, #{slope_one_options[:resource_table]} a
                WHERE count > 0 
                  AND source_id = ? 
                  AND a.id = target_id
             ORDER BY (sum / count) DESC LIMIT ?;
          }
          find_by_sql [q, resource.id, opts[:limit] || 20]
        end

        protected

        def frequency_matrix
          @frequency_matrix ||=
          %Q{
            SELECT source_id, target_id, count, sum 
              FROM #{slope_one_options[:diff_table]} 
             UNION 
            SELECT target_id, source_id, count, -sum 
              FROM #{slope_one_options[:diff_table]}
          }
        end

      end # ClassMethods

      module InstanceMethods

        # Find resources based on user's previous ratings
        # @return DataMapper::Collection
        def recommend(opts={})
          self.class.recommend_for_resource(self,opts)
        end

      end # InstanceMethods

    end # SlopeOne
  end # Is
end # DataMapper

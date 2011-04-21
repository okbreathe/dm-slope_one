module DataMapper
  module Is
    module Filterable

      # Make a resource filterable using the slope one algorithm
      #
      # @example
      #
      #   class Post
      #     include DataMapper::Resource
      #
      #     property :id,      Serial
      #     property :name,    String
      #     property :content, Text
      #
      #     is :filterable
      #   end
      #
      # @param [Hash] options(optional)
      #   A hash with options
      # @option options [String] :by
      #   Stringified name of the DataMapper model that should become the rater
      #   default: User
      # @option options [String] :on
      #   Stringified name of the DataMapper model that stores the rater's ratings
      #   default: Rating
      # @option options [Symbol] :rating_property
      #   The property that will be used when generating differentials
      #   The same name will be used for both the rating model as well as the differential model
      #   default: score
      #   e.g @rating.score
      # @option options [String] :rating_type
      #   default: Float
      # @option options [Integer] :rating_precision
      #   default: 6
      # @option options [Integer] :rating_scale
      #   default: 6
      #
      # @api public
      def is_filterable(options={})

        extend  DataMapper::Is::Filterable::ClassMethods
        include DataMapper::Is::Filterable::InstanceMethods

        class << self
          attr_reader :slope_one_options
        end

        o   = @slope_one_options = {}
        inf = DataMapper::Inflector

        o[:rater_model]              = inf.constantize(options[:by] || "User")
        o[:rater_name]               = inf.underscore(o[:rater_model])
        o[:rater_key]                = inf.foreign_key(o[:rater_model])
        o[:resource_key]             = inf.foreign_key(name)
        o[:resource_name]            = inf.underscore(name)
        o[:resource_relationship]    = inf.pluralize(o[:resource_name])
        o[:rating_model]             = (options[:on] || "Rating").to_sym
        o[:rating_relationship_name] = inf.pluralize(inf.underscore(o[:rating_model])).to_sym
        o[:rating_property]        ||= :score
        o[:rating_type]            ||= "Float"
        o[:rating_precision]       ||= 5
        o[:rating_scale]           ||= 2

        has n, o[:rating_relationship_name]
        o[:rater_model].has n, o[:rating_relationship_name]

        Differential.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          property :#{o[:rating_property]}, #{ o[:rating_type] == "Float" ? "Float, :precision => #{o[:rating_precision]}, :scale => #{o[:rating_scale]}" : "Integer"}, :default => 0

          belongs_to :source, "#{name}", :child_key => [:source_id]
          belongs_to :target, "#{name}", :child_key => [:target_id]

        RUBY

        shout o

        rating_model = ::Object.const_defined?(o[:rating_model]) ? ::Object.const_get(o[:rating_model]) : ::Object.const_set(o[:rating_model], Class.new(::Object) )
        rating_model.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def self.slope_one_options
            #{name}.slope_one_options
          end
        RUBY
        rating_model.extend DataMapper::Is::Filterable::Rating
      end

      module ClassMethods

        # @api public
        def filterable?
          true
        end

        # Depending on the arguments, will filter differently
        # @return DataMapper::Collection
        def predict(user_or_resource,resource=nil,limit=nil)
          limit = resource && limit ? limit : 10
          if user_or_resource.kind_of?(self)
            predict_for_resource(user_or_resource,limit) 
          elsif resource
            predict_for_user_and_resource(user_or_resource,resource,limit) 
          else
            predict_for_user(user_or_resource,limit) 
          end
        end

        # Find resources based on user's previous ratings
        # @return DataMapper::Collection
        def predict_for_user(user,limit=10)
          o = slope_one_options
          find_by_sql([%Q{
              SELECT a.*
                FROM differentials d, #{o[:rating_relationship_name]} r, #{o[:resource_relationship]} a
               WHERE r.#{o[:rater_key]} = ?
                 AND d.source_id    = r.#{o[:resource_key]}
                 AND d.target_id   != r.#{o[:resource_key]}
                 AND a.id           = d.target_id
            GROUP BY d.target_id 
            ORDER BY SUM(r.#{o[:rating_property]} * d.count - d.#{o[:rating_property]}) / SUM(d.count) DESC LIMIT ?
          },
          user.id,
          limit ])
        end


        # Find similar resources to the given
        # @return DataMapper::Collection
        def predict_for_resource(resource,limit=10)
          o = slope_one_options
          find_by_sql([%Q{
             SELECT a.*
               FROM differentials d, #{o[:resource_relationship]} a
              WHERE d.source_id = ? 
                AND a.id        = d.target_id
           GROUP BY d.target_id
           ORDER BY SUM(d.#{o[:rating_property]} / d.count) LIMIT ?
         }, 
         resource.id, 
         limit ])
        end

        # Find resources based on user's previous ratings as well as similarity to
        # the given resource
        # NOTE Not sure this actually works!
        # @return DataMapper::Collection
        def predict_for_user_and_resource(user,resource,limit=10)
          o = slope_one_options
          find_by_sql([%Q{
              SELECT a.*
                FROM differentials d, #{o[:rating_relationship_name]} r, #{o[:resource_relationship]} a
               WHERE r.#{o[:rater_key]} = ?
                 AND d.source_id  = ?
                 AND d.target_id != r.#{o[:resource_key]}
                 AND a.id         = d.target_id
            GROUP BY d.target_id 
            ORDER BY SUM(r.#{o[:rating_property]} * d.count - d.#{o[:rating_property]}) / SUM(d.count) DESC LIMIT ?
          },
          user.id,
          resource.id,
          limit ])
        end

      end # ClassMethods

      module InstanceMethods

        def predict(limit=10)
          self.class.predict_for_resource(self,limit)
        end

        def predict_for_user(user,limit=10)
          self.class.predict_for_user_and_resource(user,self,limit)
        end

      end # InstanceMethods

    end # Filterable
  end # Is
end # DataMapper

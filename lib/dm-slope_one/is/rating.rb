module DataMapper
  module Is
    module Filterable
      module Rating

        def self.extended(base)
          o = base.slope_one_options
          base.extend ClassMethods
          base.send :include, InstanceMethods
          base.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            include ::DataMapper::Resource unless ancestors.include?(::DataMapper::Resource)

            property :id, Serial 
            property :#{o[:rating_property]}, #{ o[:rating_type] == "Float" ? "Float, :precision => #{o[:rating_precision]}, :scale => #{o[:rating_scale]}" : "Integer"}, :default => 0

            belongs_to :#{o[:rater_name]}
            belongs_to :#{o[:resource_name]}

            after :save, :update_differentials

          RUBY
        end
        
        module ClassMethods

          # Will generate differentials for the entire table 
          # NOTE All existing differentials will be destroyed
          def update_differentials!
            o = slope_one_options
            Differential.all.destroy!
            resource_ids = repository.adapter.select(%Q{SELECT DISTINCT #{o[:resource_key]} FROM #{o[:rating_relationship_name]}})
            resource_ids.each do |resource_id|
              repository.adapter.execute(%Q{
                INSERT into differentials (source_id,target_id,count,#{o[:rating_property]})
                    SELECT a.#{o[:resource_key]} AS source_id, b.#{o[:resource_key]} AS target_id, count(*) AS count, SUM(a.#{o[:rating_property]}-b.#{o[:rating_property]}) AS sum
                      FROM #{o[:rating_relationship_name]} a, #{o[:rating_relationship_name]} b 
                     WHERE a.#{o[:resource_key]} = ?
                       AND b.#{o[:resource_key]} != a.#{o[:resource_key]} 
                       AND a.#{o[:rater_key]} = b.#{o[:rater_key]} 
                  GROUP BY a.#{o[:resource_key]}, b.#{o[:resource_key]}
              }, resource_id)
            end
          end

        end

        module InstanceMethods

          protected
          
          # This is fairly ineffecient
          def update_differentials
            o = self.class.slope_one_options
            resource_id = self.send("#{o[:resource_key]}")
            user_id     = self.send("#{o[:rater_key]}")
              
            # Get all the ratings for the just rated resource
            ratings = repository.adapter.select(%Q{
              SELECT DISTINCT r.#{o[:resource_key]}, r2.#{o[:rating_property]} - r.#{o[:rating_property]} as rating_difference 
                FROM #{o[:rating_relationship_name]} r, #{o[:rating_relationship_name]} r2 
               WHERE r.#{o[:rater_key]} = ? 
                 AND r2.#{o[:resource_key]} = ? 
                 AND r2.#{o[:rater_key]} = ?
            },
            user_id, resource_id, user_id)
            ratings.each do |rating|
              other_resource_id = rating.send("#{o[:resource_key]}")
              rating_difference = rating.rating_difference.round(o[:rating_scale])
              next if other_resource_id == resource_id
              
              if d = Differential.first(:source_id => resource_id, :target_id => other_resource_id)
                d.update(:count => d.count+1, o[:rating_property] => (d.send(o[:rating_property])+rating_difference).round(o[:rating_scale]))
                d = Differential.first(:source_id => other_resource_id, :target_id => resource_id)
                d.update(:count => d.count+1, o[:rating_property] => (d.send(o[:rating_property])-rating_difference).round(o[:rating_scale]))
              else # Create differentials
                Differential.create(:source_id => resource_id, :target_id => other_resource_id, :count => 1, o[:rating_property] => rating_difference)
                if resource_id != other_resource_id          
                  Differential.create(:source_id => other_resource_id, :target_id => resource_id, :count => 1, o[:rating_property] => -rating_difference)
                end
              end
            end
          end

        end # InstanceMethods

      end # Rating
    end # Filterable
  end # Is
end # DataMapper

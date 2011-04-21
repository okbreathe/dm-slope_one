module DataMapper
  module Is
    module SlopeOne
      module Rating

        def self.extended(base)
          o = base.slope_one_options
          base.class_eval do

            unless o[:offline]
              after  :create,  :create_diffs
              before :update,  :revert_diffs
              after  :update,  :update_diffs
              before :destroy, :remove_diffs
            end

            # Generates differentials for the entire table 
            # NOTE - All existing differentials will be destroyed.
            define_singleton_method :generate_diffs! do
              DataMapper::Inflector.constantize(o[:diff_model]).all.destroy!
              q = %Q{
                INSERT INTO #{o[:diff_table]} ( source_id , target_id , sum , count ) 
                     SELECT r2.#{o[:resource_key]}, r1.#{o[:resource_key]}, SUM(r2.#{o[:rating_property]} - r1.#{o[:rating_property]} ), COUNT(1)
                       FROM #{o[:rating_table]} r1, #{o[:rating_table]} r2
                      WHERE r1.#{o[:rater_key]} = r2.#{o[:rater_key]}
                        AND r1.#{o[:resource_key]} < r2.#{o[:resource_key]}
                   GROUP BY r1.#{o[:resource_key]}, r2.#{o[:resource_key]}
                     HAVING COUNT(1) >= ?
              }
              repository.adapter.execute(q,1)
            end

            define_method :create_diffs do
              update_diff_table("SET count = count + 1, sum = sum + r2.#{o[:rating_property]} - r1.#{o[:rating_property]}") 
            end

            define_method :revert_diffs do
              update_diff_table("SET sum = sum - (r2.#{o[:rating_property]} - r1.#{o[:rating_property]})") 
            end

            define_method :update_diffs do
              update_diff_table("SET sum = sum + r2.#{o[:rating_property]} - r1.#{o[:rating_property]}") 
            end

            define_method :remove_diffs do
              update_diff_table("SET count = count - 1, sum = sum - (r2.#{o[:rating_property]} - r1.#{o[:rating_property]})" )
            end

            protected

            define_method :update_diff_table do |q|
              query = %Q{
                UPDATE #{o[:diff_table]}
                #{q}
                FROM #{o[:rating_table]} r1, #{o[:rating_table]} r2
               WHERE r1.#{o[:rater_key]} = r2.#{o[:rater_key]} AND r2.#{o[:rater_key]} = ?
                 AND (
                   ( r1.#{o[:resource_key]} = ? AND r1.#{o[:resource_key]} = target_id AND r2.#{o[:resource_key]} = source_id)
                   OR 
                   ( r2.#{o[:resource_key]} = ? AND r2.#{o[:resource_key]} = source_id AND r1.#{o[:resource_key]} = target_id)
                )
              }
              repository.adapter.execute(query,send(o[:rater_key]), send(o[:resource_key]), send(o[:resource_key]))
            end
          end
        end # self.extended

      end # Rating
    end # SlopeOne
  end # Is
end # DataMapper

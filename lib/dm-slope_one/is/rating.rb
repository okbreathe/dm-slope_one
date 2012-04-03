module DataMapper
  module Is
    module SlopeOne
      module Rating

        def self.extended(base)
          base.class_eval do

            unless slope_one_options[:offline]
              after  :create,  :create_diffs
              before :update,  :revert_diffs
              after  :update,  :update_diffs
              before :destroy, :remove_diffs
            end

            # Generate differentials for the entire table 
            # NOTE - All existing differentials will be destroyed.
            def self.generate_diffs!
              o = slope_one_options
              DataMapper::Inflector.constantize(o[:diff_model]).all.destroy!
              q = %Q{
                INSERT INTO #{o[:diff_table]} ( source_id , target_id , difference , frequency )
                     SELECT r2.#{o[:resource_key]}
                          , r1.#{o[:resource_key]}
                          , SUM(r2.#{o[:rating_property]} - r1.#{o[:rating_property]})
                          , COUNT(1)
                       FROM #{o[:rating_table]} r1
                 INNER JOIN #{o[:rating_table]} r2 ON r1.#{o[:rater_key]} = r2.#{o[:rater_key]}
                      WHERE r1.#{o[:resource_key]} < r2.#{o[:resource_key]}
                   GROUP BY r1.#{o[:resource_key]}
                          , r2.#{o[:resource_key]}
                     HAVING COUNT(1) >= 1
              }
              repository.adapter.execute(q)
            end

            def create_diffs
              r = self.class.slope_one_options[:rating_property]
              update_diff_table("SET frequency = frequency + 1, difference = difference + r2.#{r} - r1.#{r}") 
            end

            def revert_diffs
              r = self.class.slope_one_options[:rating_property]
              update_diff_table("SET difference = difference - (r2.#{r} - r1.#{r})") 
            end

            def update_diffs
              r = self.class.slope_one_options[:rating_property]
              update_diff_table("SET difference = difference + r2.#{r} - r1.#{r}") 
            end

            def remove_diffs
              r = self.class.slope_one_options[:rating_property]
              update_diff_table("SET frequency = frequency - 1, difference = difference - (r2.#{r} - r1.#{r})" )
            end

            protected

            def update_diff_table(q)
              o = self.class.slope_one_options
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


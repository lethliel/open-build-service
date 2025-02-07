require 'highline/import'

namespace :data do
  namespace :backfill do
    desc 'Backfill source fields on bs_request_actions'
    task source_fields_on_bs_request_actions: :environment do
      puts "This rake task will possibly touch all BsRequestActions database rows of your environment (#{Rails.env})"
      unless HighLine.agree('Do you want to proceed? [yes/no]')
        puts 'OK, exiting...'
        exit
      end

      # rubocop:disable Rails/SkipsModelValidations
      bs_request_actions = BsRequestAction.where(source_project_id: nil, source_package_id: nil).where.not(source_project: nil)
      bs_request_actions.in_batches do |batch|
        batch.find_each do |action|
          if action.source_package.present?
            source_package = Package.find_by_project_and_name(action.source_project, action.source_package)
            if source_package
              action.update_columns(source_project_id: source_package.project.id, source_package_id: source_package.id)
            end
            next
          end

          source_project = Project.find_by(name: action.source_project)
          if source_project
            action.update_columns(source_project_id: source_project.id)
          end
        end
      end
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end

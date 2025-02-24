module Webui
  module Users
    class BsRequestsController < WebuiController
      before_action :redirect_legacy
      before_action :require_login
      before_action :set_user

      include Webui::RequestsFilter

      REQUEST_METHODS = {
        'all_requests_table' => :requests,
        'requests_out_table' => :outgoing_requests,
        'requests_declined_table' => :declined_requests,
        'requests_in_table' => :incoming_requests,
        'reviews_in_table' => :involved_reviews
      }.freeze

      def index
        respond_to do |format|
          format.html do
            filter_requests

            @bs_requests = @bs_requests.order('number DESC').page(params[:page])
            @bs_requests = @bs_requests.includes(:bs_request_actions, :comments, :reviews)
            @bs_requests = @bs_requests.includes(:labels) if Flipper.enabled?(:labels, User.session)
          end
          # TODO: Remove this old index action when request_index feature is rolled-over
          format.json do
            parsed_params = BsRequest::DataTable::ParamsParser.new(params).parsed_params
            requests_query = BsRequest::DataTable::FindForUserOrGroupQuery.new(@user_or_group, request_method, parsed_params)
            @requests_data_table = BsRequest::DataTable::Table.new(requests_query, parsed_params[:draw])

            render 'webui/shared/bs_requests/index'
          end
        end
      end

      private

      def filter_by_involvement(involvement)
        return filter_by_involvement_staging_project(involvement) if staging_projects.present?

        case involvement
        when 'all'
          User.session.requests
        when 'incoming'
          User.session.incoming_requests.unscope(where: :state)
        when 'outgoing'
          User.session.outgoing_requests.unscope(where: :state)
        end
      end

      def filter_by_involvement_staging_project(involvement)
        case involvement
        when 'all'
          User.session.requests.where(staging_project: staging_projects)
        when 'incoming'
          User.session.incoming_requests.where(staging_project: staging_projects)
        when 'outgoing'
          User.session.outgoing_requests.where(staging_project: staging_projects)
        end
      end

      def set_user
        @user_or_group = User.session
      end

      def request_method
        REQUEST_METHODS[params[:dataTableId]] || :requests
      end

      def redirect_legacy
        redirect_to(my_tasks_path) unless Flipper.enabled?(:request_index, User.session) || request.format.json?
      end
    end
  end
end

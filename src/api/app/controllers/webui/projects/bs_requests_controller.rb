module Webui
  module Projects
    class BsRequestsController < WebuiController
      include Webui::RequestsFilter

      before_action :set_project
      before_action :redirect_legacy
      before_action :set_bs_requests

      def index
        if Flipper.enabled?(:request_index, User.session)
          # FIXME: Once we roll out filter_requests should become a before_action
          filter_requests
          @bs_requests = @bs_requests.order('number DESC').page(params[:page])
        else
          parsed_params = BsRequest::DataTable::ParamsParserWithStateAndType.new(params).parsed_params
          requests_query = BsRequest::DataTable::FindForProjectQuery.new(@project, parsed_params)
          @requests_data_table = BsRequest::DataTable::Table.new(requests_query, params[:draw])

          respond_to do |format|
            format.json { render 'webui/shared/bs_requests/index' }
          end
        end
      end

      private

      def set_bs_requests
        return unless Flipper.enabled?(:request_index, User.session)

        @bs_requests = @project.bs_requests
      end

      def filter_involvement
        return if params[:involvement]&.compact_blank.blank?

        @selected_filter['involvement'] = params[:involvement]
        @bs_requests =  case
                        when @selected_filter['involvement'].include?('incoming')
                          @bs_requests.where(bs_request_actions: { target_project_id: @project.id })
                        when @selected_filter['involvement'].include?('outgoing')
                          @bs_requests.where(bs_request_actions: { source_project_id: @project.id })
                        when @selected_filter['involvement'].include?('review')
                          @bs_requests.where(reviews: { project: @project })
                        end
      end

      def redirect_legacy
        redirect_to(project_requests_path(@project)) unless Flipper.enabled?(:request_index, User.session) || request.format.json?
      end
    end
  end
end

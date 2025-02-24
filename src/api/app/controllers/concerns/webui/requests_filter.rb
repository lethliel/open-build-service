module Webui::RequestsFilter
  extend ActiveSupport::Concern

  ALLOWED_INVOLVEMENTS = %w[all incoming outgoing].freeze
  TEXT_SEARCH_MAX_RESULTS = 10_000

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def filter_requests
    set_filters

    if params[:requests_search_text].present?
      initial_bs_requests = filter_by_text(params[:requests_search_text])
      params[:ids] = filter_by_involvement(@filter_involvement).ids
    else
      initial_bs_requests = filter_by_involvement(@filter_involvement)
    end

    params[:creator] = @filter_creators if @filter_creators.present?
    params[:project_name] = @filter_project_names if @filter_project_names.present?
    params[:states] = @filter_state if @filter_state.present?
    params[:priorities] = @filter_priority if @filter_priority.present?
    params[:types] = @filter_action_type if @filter_action_type.present?
    params[:staging_projects] = @filter_staging_projects if @filter_staging_projects.present?
    params[:reviewers] = @filter_reviewers if @filter_reviewers.present?

    params[:created_at_from] = @filter_created_at_from if @filter_created_at_from.present?
    params[:created_at_to] = @filter_created_at_to if @filter_created_at_to.present?

    @bs_requests = BsRequest::FindFor::Query.new(params, initial_bs_requests).all
    set_selected_filter
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def set_filters
    @filter_involvement = params[:involvement].presence || 'all'
    @filter_involvement = 'all' if ALLOWED_INVOLVEMENTS.exclude?(@filter_involvement)

    @filter_state = params[:state].presence || []
    @filter_state = @filter_state.intersection(BsRequest::VALID_REQUEST_STATES.map(&:to_s))

    @filter_action_type = params[:action_type].presence || []
    @filter_action_type = @filter_action_type.intersection(BsRequestAction::TYPES)

    @filter_priority = params[:priority].presence || []
    @filter_priority = @filter_priority.intersection(BsRequest::VALID_REQUEST_PRIORITIES)

    @filter_creators = params[:creators].present? ? params[:creators].compact_blank! : []

    @filter_project_names = params[:project_names].present? ? params[:project_names].compact_blank! : []
    @filter_staging_projects = params[:staging_projects].presence || []

    @filter_created_at_from = params[:created_at_from].presence || ''
    @filter_created_at_to = params[:created_at_to].presence || ''

    @filter_reviewers = params[:reviewers].present? ? params[:reviewers].compact_blank! : []
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def set_selected_filter
    @selected_filter = { involvement: @filter_involvement, action_type: @filter_action_type, search_text: params[:requests_search_text],
                         state: @filter_state, creators: @filter_creators, project_names: @filter_project_names,
                         staging_projects: @filter_staging_projects, priority: @filter_priority,
                         created_at_from: @filter_created_at_from, created_at_to: @filter_created_at_to, reviewers: @filter_reviewers }
  end

  def filter_by_text(text)
    if BsRequest.search_count(text) > TEXT_SEARCH_MAX_RESULTS
      flash[:error] = 'Your text search pattern matches too many results. Please, try again with a more restrictive search pattern.'
      return BsRequest.none
    end

    BsRequest.with_actions.where(id: BsRequest.search_for_ids(text, per_page: TEXT_SEARCH_MAX_RESULTS))
  end

  def staging_projects
    Project.where(name: @filter_staging_projects)
  end
end

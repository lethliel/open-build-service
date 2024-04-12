# Methods to know which webhook we are dealing with based on the request_payload attribute
class WorkflowRunPayload
  extend ActiveSupport::Concern

  SOURCE_NAME_PAYLOAD_MAPPING = {
    'pull_request' => %w[pull_request number],
    'Merge Request Hook' => %w[object_attributes iid],
    'push' => %w[head_commit id],
    'Push Hook' => ['commits', 0, 'id']
  }.freeze

  def new_pull_request?
    (github_pull_request? && payload_hook_action == 'opened') ||
      (gitlab_merge_request? && payload_hook_action == 'open') ||
      (gitea_pull_request? && payload_hook_action == 'opened')
  end

  def updated_pull_request?
    (github_pull_request? && payload_hook_action == 'synchronize') ||
      (gitlab_merge_request? && payload_hook_action == 'update') ||
      (gitea_pull_request? && payload_hook_action == 'synchronized')
  end

  def closed_merged_pull_request?
    (github_pull_request? && payload_hook_action == 'closed') ||
      (gitlab_merge_request? && %w[close merge].include?(payload_hook_action) ||
      (gitea_pull_request? && payload_hook_action == 'closed')
  end

  def reopened_pull_request?
    (github_pull_request? && payload_hook_action == 'reopened') ||
      (gitlab_merge_request? && payload_hook_action == 'reopen') ||
      (gitea_pull_request? && payload_hook_action == 'reopened')
  end

  def new_commit_event?
    new_pull_request? || updated_pull_request? || push_event? || tag_push_event?
  end

  def push_event?
    github_push_event? || gitlab_push_event? || gitea_push_event?
  end

  def tag_push_event?
    github_tag_push_event? || gitlab_tag_push_event? || gitea_tag_push_event?
  end

  def pull_request_event?
    github_pull_request? || gitlab_merge_request? || gitea_pull_request?
  end

  def ignored_pull_request_action?
    ignored_github_pull_request_action? || ignored_gitlab_merge_request_action? || ignored_gitea_pull_request_action?
  end

  def ping_event?
    github_ping? || gitea_ping?
  end

  def ignored_push_event?
    ignored_github_push_event? || ignored_gitlab_push_event?
  end

  def commit_sha
    github_commit_sha || gitlab_commit_sha || gitea_commit_sha
  end

  def source_repository_full_name
    github_source_repository_full_name || gitlab_source_repository_full_name || gitea_source_repository_full_name
  end

  def target_repository_full_name
    github_target_repository_full_name || gitlab_target_repository_full_name || gitea_target_repository_full_name
  end

  def pr_number
    github_pr_number || gitlab_pr_number
  end

  def checkout_http_url
    github_checkout_http_url || gitea_checkout_http_url
  end

  def tag_name
    github_tag_name || gitlab_tag_name
  end

  def target_branch
    github_target_branch || gitlab_target_branch || gitea_target_branch
  end

  private

  def payload_generic_event_type
    # We only have filters for push, tag_push, and pull_request
    if hook_event == 'Push Hook' || payload.fetch('ref', '').match('refs/heads')
      'push'
    elsif hook_event == 'Tag Push Hook' || payload.fetch('ref', '').match('refs/tag')
      'tag_push'
    elsif hook_event.in?(['pull_request', 'Merge Request Hook'])
      'pull_request'
    end
  end

  def payload_event_source_name
    path = SOURCE_NAME_PAYLOAD_MAPPING[hook_event]
    payload.dig(*path) if path
  end

  def payload_repository_name
    payload.dig('repository', 'name') || payload.dig('project', 'path_with_namespace')&.split('/')&.last
  end

  def payload_repository_owner
    payload.dig('repository', 'owner', 'login') || payload.dig('project', 'path_with_namespace')&.split('/')&.first
  end

  def payload_hook_action
    github_hook_action || gitlab_hook_action
  end

  def api_endpoint
    github_api_endpoint || gitlab_api_endpoint || gitea_api_endpoint
  end
end

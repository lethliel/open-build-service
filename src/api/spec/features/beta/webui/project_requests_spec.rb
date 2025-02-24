require 'browser_helper'

RSpec.describe 'Project Requests' do
  let(:user) { create(:confirmed_user, login: 'titan') }
  let(:target_project) { create(:project_with_package, package_name: 'goal') }
  let(:source_project) { create(:project_with_package, package_name: 'ball') }
  let(:other_target_project) { create(:project_with_package, package_name: 'package_2') }

  let!(:incoming_request) do
    create(:bs_request_with_submit_action, description: 'Please take this',
                                           source_package: source_project.packages.first,
                                           target_project: target_project)
  end

  let!(:outgoing_request) do
    create(:bs_request_with_submit_action, description: 'How about this?',
                                           source_package: target_project.packages.first,
                                           target_project: other_target_project)
  end

  context 'project with requests' do
    before do
      Flipper.enable(:request_index)
      login user
      visit projects_requests_path(target_project)
    end

    it 'lists requests' do
      expect(page).to have_link(href: "/request/show/#{incoming_request.number}")
      expect(page).to have_link(href: "/request/show/#{outgoing_request.number}")
    end

    it 'filter requests' do
      find_by_id('requests-dropdown-trigger').click if mobile?
      choose('Incoming', allow_label_click: true)
      execute_script('$("#content-selector-filters-form").submit()')

      expect(page).to have_link(href: "/request/show/#{incoming_request.number}")
      expect(page).to have_no_link(href: "/request/show/#{outgoing_request.number}")
    end
  end
end

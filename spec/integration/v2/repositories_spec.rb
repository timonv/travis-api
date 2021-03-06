require 'spec_helper'

describe 'Repos' do
  before(:each) { Scenario.default }

  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  it 'GET /repos' do
    response = get '/repos', {}, headers
    response.should deliver_json_for(Repository.timeline, version: 'v2')
  end

  it 'GET /repos?owner_name=svenfuchs' do
    response = get '/repos', { owner_name: 'svenfuchs' }, headers
    response.should deliver_json_for(Repository.by_owner_name('svenfuchs'), version: 'v2')
  end

  it 'GET /repos?member=svenfuchs' do
    response = get '/repos', { member: 'svenfuchs' }, headers
    response.should deliver_json_for(Repository.by_member('svenfuchs'), version: 'v2')
  end

  it 'GET /repos?slug=svenfuchs/name=minimal' do
    response = get '/repos', { slug: 'svenfuchs/minimal' }, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal'), version: 'v2')
  end

  it 'GET /repos/1' do
    response = get "repos/#{repo.id}", {}, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v2')
  end

  it 'GET /repos/1/cc.xml' do
    response = get "repos/#{repo.id}/cc.xml"
    response.should deliver_cc_xml_for(Repository.by_slug('svenfuchs/minimal').first)
  end

  it 'GET /repos/svenfuchs/minimal' do
    response = get '/repos/svenfuchs/minimal', {}, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v2')
  end

  it 'GET /repos/svenfuchs/minimal/cc.xml' do
    response = get '/repos/svenfuchs/minimal/cc.xml'
    response.should deliver_cc_xml_for(Repository.by_slug('svenfuchs/minimal').first)
  end

  describe 'GET /repos/svenfuchs/minimal.png?branch=foo,bar' do
    let(:on_foo) { Factory(:commit, branch: 'foo') }
    let(:on_bar) { Factory(:commit, branch: 'bar') }

    it '"unknown" when the repository does not exist' do
      result = get('/repos/svenfuchs/does-not-exist.png?branch=foo,bar', {}, headers)
      result.should deliver_result_image_for('unknown')
    end

    it '"unknown" when it only has unfinished builds on the relevant branches' do
      Build.delete_all
      Factory(:build, repository: repo, state: :started, result: nil, commit: on_foo)
      Factory(:build, repository: repo, state: :started, result: nil, commit: on_bar)
      result = get('/repos/svenfuchs/minimal.png?branch=foo,bar', {}, headers)
      result.should deliver_result_image_for('unknown')
    end

    it '"failing" when the last build has failed' do
      Factory(:build, repository: repo, state: :finished, result: 1, commit: on_foo)
      Factory(:build, repository: repo, state: :finished, result: 1, commit: on_bar)
      result = get('/repos/svenfuchs/minimal.png?branch=foo,bar', {}, headers)
      result.should deliver_result_image_for('failing')
    end

    it '"passing" when the last build has passed' do
      Factory(:build, repository: repo, state: :finished, result: 1, commit: on_foo)
      Factory(:build, repository: repo, state: :finished, result: 0, commit: on_bar)
      result = get('/repos/svenfuchs/minimal.png?branch=foo,bar', {}, headers)
      result.should deliver_result_image_for('passing')
    end

    it '"passing" when there is a running build but the previous one has passed' do
      Factory(:build, repository: repo, state: :finished, result: 0, commit: on_foo)
      Factory(:build, repository: repo, state: :finished, result: 0, commit: on_bar)
      Factory(:build, repository: repo, state: :started, result: nil, commit: on_bar)
      repo.update_attributes!(last_build_result: nil)
      result = get('/repos/svenfuchs/minimal.png?branch=foo,bar', {}, headers)
      result.should deliver_result_image_for('passing')
    end
  end
end

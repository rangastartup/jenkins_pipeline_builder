require File.expand_path('../spec_helper', __FILE__)
require 'equivalent-xml'

describe 'Test YAML jobs conversion to XML' do
  context 'Loading YAML files' do
    before do
      @client = JenkinsApi::Client.new(
          :server_ip => '127.0.0.1',
          :server_port => 8080,
          :username => 'username',
          :password => 'password',
          :log_location => '/dev/null'
      )
      @generator = JenkinsPipelineBuilder::Generator.new(nil, @client)
      @generator.debug = true
      @generator.no_files = true
    end

    def compare_jobs(job, path)
      xml = @generator.compile_job_to_xml(job)
      doc1 = Nokogiri::XML(xml)

      sample_job_xml = File.read(path + '.xml')

      doc2 = Nokogiri::XML(sample_job_xml)

      doc1.should be_equivalent_to(doc2)
    end

    [
      'Job-Multi-Project',
      'Job-Build-Maven',
      'Job-Build-Flow',
      'Job-Gem-Build'
    ].each do |file|
      it "should create expected XML from YAML '#{file}'" do
        path = File.expand_path('../fixtures/files/' + file, __FILE__)

        @generator.load_collection_from_path path + '.yaml'
        job_name = @generator.job_collection.keys.first
        job = @generator.resolve_job_by_name(job_name)

        compare_jobs job, path
      end
    end

    it "should create expected XML from YAML collection" do
      path = File.expand_path('../fixtures/files/', __FILE__)

      @generator.load_collection_from_path(path)

      project_name = @generator.projects.first[:name]

      project = @generator.resolve_project(@generator.get_item(project_name))

      project[:value][:jobs].should_not be_nil

      project[:value][:jobs].each do |i|
        job = i[:result]
        job.should_not be_nil

        file_name = File.join(path, job[:name])
        compare_jobs job, file_name
      end
    end
  end
end
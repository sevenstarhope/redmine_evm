class Baseline < ActiveRecord::Base
  include Redmine::SafeAttributes
  unloadable

  belongs_to :project
  has_many :baseline_issues, dependent: :destroy
  has_many :baseline_versions, dependent: :destroy

  validates :name, :due_date, :presence => true

  before_create {update_baseline_status("Old", self.project_id)}
  after_destroy {update_baseline_status("Current", self.project_id)}

  acts_as_customizable

  safe_attributes 'name',
  'description',
  'due_date'

  def create_version versions
    unless versions.nil?
      versions.each do |version|
        baseline_version = BaselineVersion.create( original_version_id: version.id, effective_date: version.effective_date, start_date: version.created_on)
        self.baseline_versions << baseline_version
      end
    end
  end

  def create_issues issues
    unless issues.nil?
      issues.each do |issue|
        baseline_issue = BaselineIssue.create(original_issue_id: issue.id, estimated_time: issue.estimated_hours, due_date: issue.due_date, time_week: issue.start_date)  
        baseline_version = self.baseline_versions.where("original_version_id = :id", id: issue.fixed_version_id).first
        unless baseline_version.nil?
          baseline_issue.baseline_version_id = baseline_version.id
        end
        baseline_issues << baseline_issue
      end
    end
  end

  def update_baseline_status status, project_id
    if project_id
      project = Project.find(project_id) 
      baseline = project.baselines.last 
    else
      baseline = Baseline.last 
    end
    if baseline 
      baseline.state = status 
      baseline.save
    end
  end
end

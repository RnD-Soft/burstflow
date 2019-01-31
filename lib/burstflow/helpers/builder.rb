module Burstflow
  
class Helpers::Builder
  def initialize workflow_id, *args, &block
    @workflow_id = workflow_id
    @deps = []
    @jobs_by_class = {}
    @jobs_by_id = {}

    instance_exec *args, &block
    resolve_dependencies
  end

  def run(klass, opts = {})
    opts = opts.with_indifferent_access

    before_deps = opts.delete(:before) || []
    after_deps = opts.delete(:after) || []

    job = klass.new(self, opts)
    job.workflow_id = @workflow_id

    [*before_deps].each do |dep|
      @deps << { from: job.id, to: dep.to_s }
    end

    [*after_deps].each do |dep|
      @deps << { from: dep.to_s, to: job.id }
    end

    @jobs_by_class[klass.to_s] ||= []
    @jobs_by_class[klass.to_s] << job

    raise "Job id duplication" if @jobs_by_id.key?(job.id)
    @jobs_by_id[job.id] = job

    job.id
  end

  def find_job id_or_klass
    id = if @jobs_by_id.key?(id_or_klass)
      id_or_klass
    else
      jobs = @jobs_by_class[id_or_klass.to_s]

      raise "No job with #{id_or_klass.to_s} klass or id found" if jobs.count == 0
      raise "Duplicated jobs with #{id_or_klass.to_s} klass or id detected" if jobs.count > 1

      jobs.first.id
    end

    @jobs_by_id[id]
  end

  def resolve_dependencies
    @deps.each do |dependency|
      from = find_job(dependency[:from].to_s)
      to   = find_job(dependency[:to].to_s)

      to.incoming << from.id
      from.outgoing << to.id

      to.incoming.uniq!
      from.outgoing.uniq!
    end
  end

  def as_json
    @jobs_by_id.each_with_object({}) do |(id, job), json|
      json[job.id] = job.as_json
    end
  end

end
end